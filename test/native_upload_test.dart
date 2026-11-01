import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openlist_mobile/api/native_upload.dart';
import 'package:openlist_mobile/api/openlist_client.dart';
import 'package:openlist_mobile/api/upload_queue.dart';
import 'package:openlist_mobile/generated_api.dart';

const _host = 'dev.flutter.pigeon.openlist_mobile.UploadApi.';
const _events = 'dev.flutter.pigeon.openlist_mobile.UploadEventApi.onUploadEvent';

/// Fake native host: records enqueue/cancel calls and returns job ids.
class _Host {
  final requests = <UploadRequest>[];
  final canceled = <String>[];

  String get lastId => 'job${requests.length}';

  void install() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const codec = UploadApi.pigeonChannelCodec;
    messenger.setMockMessageHandler('${_host}enqueue', (data) async {
      final args = codec.decodeMessage(data) as List<Object?>;
      requests.add(args[0]! as UploadRequest);
      return codec.encodeMessage(<Object?>[lastId]);
    });
    messenger.setMockMessageHandler('${_host}cancel', (data) async {
      final args = codec.decodeMessage(data) as List<Object?>;
      canceled.add(args[0]! as String);
      return codec.encodeMessage(<Object?>[null]);
    });
  }
}

/// Delivers an event as the platform would through UploadEventApi.
Future<void> _emit(String id, UploadEventState state,
    {int sent = 0, int total = 0, int status = 0, String? body, String? error}) async {
  const codec = UploadEventApi.pigeonChannelCodec;
  final event = UploadEvent(
    id: id,
    state: state,
    sent: sent,
    total: total,
    httpStatus: status,
    body: body,
    error: error,
  );
  await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .handlePlatformMessage(
          _events, codec.encodeMessage(<Object?>[event]), (_) {});
}

final _client =
    OpenListClient(baseUrl: 'https://files.example.com/base', token: 'tok');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Host host;
  late NativeUploader uploader;
  late int fallbacks;

  Future<void> upload({
    OpenListClient? client,
    CancelToken? token,
    ProgressCallback? onProgress,
  }) =>
      uploader.upload(
        client ?? _client,
        filePath: '/tmp/a.bin',
        dstPath: '/dir/a b.bin',
        title: 'a b.bin',
        password: 'pw',
        cancelToken: token,
        onProgress: onProgress,
        fallback: () async => fallbacks++,
      );

  setUp(() {
    host = _Host()..install();
    uploader = NativeUploader(platform: TargetPlatform.android);
    fallbacks = 0;
  });

  tearDown(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMessageHandler('${_host}enqueue', null);
    messenger.setMockMessageHandler('${_host}cancel', null);
  });

  test('enqueues fs/put with client auth and completes on envelope 200',
      () async {
    final progress = <int>[];
    final done = upload(onProgress: (sent, _) => progress.add(sent));
    await pumpEventQueue();

    final req = host.requests.single;
    expect(req.url, 'https://files.example.com/base/api/fs/put');
    expect(req.method, 'PUT');
    expect(req.filePath, '/tmp/a.bin');
    expect(req.headers['Authorization'], 'tok');
    expect(req.headers['File-Path'], '/dir/a%20b.bin');
    expect(req.headers['Password'], 'pw');
    expect(req.headers.keys.map((k) => k.toLowerCase()),
        isNot(contains('content-length')));

    await _emit('job1', UploadEventState.running, sent: 4, total: 10);
    await _emit('job1', UploadEventState.completed,
        sent: 10,
        total: 10,
        status: 200,
        body: '{"code":200,"message":"success","data":null}');
    await expectLater(done, completes);
    expect(progress, [4]);
    expect(fallbacks, 0);
  });

  test('maps an error envelope and a transport failure to ApiException',
      () async {
    final denied = expectLater(
        upload(),
        throwsA(isA<ApiException>()
            .having((e) => e.code, 'code', 403)
            .having((e) => e.message, 'message', 'permission denied')));
    await pumpEventQueue();
    await _emit('job1', UploadEventState.completed,
        status: 200, body: '{"code":403,"message":"permission denied"}');
    await denied;

    final broken = expectLater(
        upload(),
        throwsA(isA<ApiException>()
            .having((e) => e.code, 'code', -1)
            .having((e) => e.message, 'message', 'connection reset')));
    await pumpEventQueue();
    await _emit('job2', UploadEventState.failed, error: 'connection reset');
    await broken;
  });

  test('cancel token cancels the native job; native cancel marks the token',
      () async {
    final token = CancelToken();
    final done = expectLater(
        upload(token: token),
        throwsA(isA<DioException>()
            .having((e) => e.type, 'type', DioExceptionType.cancel)));
    await pumpEventQueue();
    token.cancel();
    await done;
    await pumpEventQueue();
    expect(host.canceled, ['job1']);

    // Canceled from the notification: the queue must see a canceled token.
    final other = CancelToken();
    final second = expectLater(upload(token: other), throwsA(isA<DioException>()));
    await pumpEventQueue();
    await _emit('job2', UploadEventState.canceled);
    await second;
    expect(other.isCancelled, isTrue);
  });

  test('handles a result that arrives before enqueue returns', () async {
    // The host replies with the id only after emitting the result.
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const codec = UploadApi.pigeonChannelCodec;
    messenger.setMockMessageHandler('${_host}enqueue', (data) async {
      await _emit('early', UploadEventState.completed,
          status: 200, body: '{"code":200}');
      return codec.encodeMessage(<Object?>['early']);
    });
    await expectLater(upload(), completes);
  });

  test('queue cancel and retry run a new native job', () async {
    final queue = UploadQueue(concurrency: 1);
    final job = UploadJob(
      name: 'a',
      dir: '/dir',
      size: 10,
      run: (token, onProgress) => upload(token: token, onProgress: onProgress),
    );
    queue.add(job);
    await pumpEventQueue();
    expect(job.state, UploadState.running);

    queue.cancel(job);
    await pumpEventQueue();
    expect(job.state, UploadState.canceled);
    expect(host.canceled, ['job1']);

    queue.retry(job);
    await pumpEventQueue();
    expect(host.requests, hasLength(2));
    await _emit('job2', UploadEventState.completed,
        status: 200, body: '{"code":200}');
    await pumpEventQueue();
    expect(job.state, UploadState.succeeded);
  });

  test('falls back to the Dart upload where native cannot run', () async {
    // Android loopback HTTPS: self-signed core certificate.
    await upload(
        client: OpenListClient(baseUrl: 'https://127.0.0.1:5245', token: 't'));
    // iOS loopback: the in-process core is suspended in background.
    uploader = NativeUploader(platform: TargetPlatform.iOS);
    await upload(
        client: OpenListClient(baseUrl: 'http://127.0.0.1:5244', token: 't'));
    // iOS plain HTTP remote: blocked by ATS.
    await upload(
        client: OpenListClient(baseUrl: 'http://files.example.com', token: 't'));
    expect(fallbacks, 3);
    expect(host.requests, isEmpty);

    // Android plain HTTP loopback runs natively.
    uploader = NativeUploader(platform: TargetPlatform.android);
    unawaited(upload(
        client: OpenListClient(baseUrl: 'http://127.0.0.1:5244', token: 't')));
    await pumpEventQueue();
    expect(host.requests.single.url, 'http://127.0.0.1:5244/api/fs/put');
  });

  test('falls back when the host API is not registered', () async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMessageHandler('${_host}enqueue', null);
    await upload();
    expect(fallbacks, 1);
    // Later uploads skip the channel entirely.
    expect(uploader.supports(_client.baseUrl), isFalse);
  });
}
