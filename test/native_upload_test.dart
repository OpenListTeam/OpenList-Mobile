import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openlist_mobile/api/native_upload.dart';
import 'package:openlist_mobile/api/openlist_client.dart';
import 'package:openlist_mobile/api/upload_queue.dart';
import 'package:openlist_mobile/generated_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _host = 'dev.flutter.pigeon.openlist_mobile.UploadApi.';
const _events =
    'dev.flutter.pigeon.openlist_mobile.UploadEventApi.onUploadEvent';

/// Fake native host: records enqueue/cancel/restore calls and returns job ids.
class _Host {
  final requests = <UploadRequest>[];
  final canceled = <String>[];
  final restored = <List<String>>[];

  /// What `restore` reports, by id; ids not here are unknown to the host.
  final known = <String, UploadEvent>{};

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
    messenger.setMockMessageHandler('${_host}restore', (data) async {
      final args = codec.decodeMessage(data) as List<Object?>;
      final ids = (args[0]! as List<Object?>).cast<String>();
      restored.add(ids);
      return codec.encodeMessage(<Object?>[
        [
          for (final id in ids)
            if (known[id] != null) known[id],
        ],
      ]);
    });
  }
}

UploadEvent _event(
  String id,
  UploadEventState state, {
  int sent = 0,
  int total = 0,
  int status = 0,
  String? body,
}) => UploadEvent(
  id: id,
  state: state,
  sent: sent,
  total: total,
  httpStatus: status,
  body: body,
);

/// A stored job record as written by an earlier app process.
String _record(
  String id, {
  String baseUrl = 'https://files.example.com/base',
}) => jsonEncode({
  'id': id,
  'name': '$id.bin',
  'dir': '/dir',
  'dstPath': '/dir/$id.bin',
  'filePath': '/tmp/$id.bin',
  'size': 10,
  'baseUrl': baseUrl,
});

Future<Set<String>> _recordIds() async {
  final prefs = await SharedPreferences.getInstance();
  return {
    for (final k in prefs.getKeys())
      if (k.startsWith(NativeUploader.recordPrefix))
        k.substring(NativeUploader.recordPrefix.length),
  };
}

/// Delivers an event as the platform would through UploadEventApi.
Future<void> _emit(
  String id,
  UploadEventState state, {
  int sent = 0,
  int total = 0,
  int status = 0,
  String? body,
  String? error,
}) async {
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
        _events,
        codec.encodeMessage(<Object?>[event]),
        (_) {},
      );
}

final _client = OpenListClient(
  baseUrl: 'https://files.example.com/base',
  token: 'tok',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Host host;
  late NativeUploader uploader;
  late int fallbacks;

  Future<void> upload({
    OpenListClient? client,
    CancelToken? token,
    ProgressCallback? onProgress,
  }) => uploader.upload(
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
    SharedPreferences.setMockInitialValues({});
    host = _Host()..install();
    uploader = NativeUploader(
      platform: TargetPlatform.android,
      currentClient: () => _client,
    );
    fallbacks = 0;
  });

  tearDown(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMessageHandler('${_host}enqueue', null);
    messenger.setMockMessageHandler('${_host}cancel', null);
    messenger.setMockMessageHandler('${_host}restore', null);
  });

  test(
    'enqueues fs/put with client auth and completes on envelope 200',
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
      expect(
        req.headers.keys.map((k) => k.toLowerCase()),
        isNot(contains('content-length')),
      );

      await _emit('job1', UploadEventState.running, sent: 4, total: 10);
      await _emit(
        'job1',
        UploadEventState.completed,
        sent: 10,
        total: 10,
        status: 200,
        body: '{"code":200,"message":"success","data":null}',
      );
      await expectLater(done, completes);
      expect(progress, [4]);
      expect(fallbacks, 0);
    },
  );

  test(
    'maps an error envelope and a transport failure to ApiException',
    () async {
      final denied = expectLater(
        upload(),
        throwsA(
          isA<ApiException>()
              .having((e) => e.code, 'code', 403)
              .having((e) => e.message, 'message', 'permission denied'),
        ),
      );
      await pumpEventQueue();
      await _emit(
        'job1',
        UploadEventState.completed,
        status: 200,
        body: '{"code":403,"message":"permission denied"}',
      );
      await denied;

      final broken = expectLater(
        upload(),
        throwsA(
          isA<ApiException>()
              .having((e) => e.code, 'code', -1)
              .having((e) => e.message, 'message', 'connection reset'),
        ),
      );
      await pumpEventQueue();
      await _emit('job2', UploadEventState.failed, error: 'connection reset');
      await broken;
    },
  );

  test(
    'cancel token cancels the native job; native cancel marks the token',
    () async {
      final token = CancelToken();
      final done = expectLater(
        upload(token: token),
        throwsA(
          isA<DioException>().having(
            (e) => e.type,
            'type',
            DioExceptionType.cancel,
          ),
        ),
      );
      await pumpEventQueue();
      token.cancel();
      await done;
      await pumpEventQueue();
      expect(host.canceled, ['job1']);

      // Canceled from the notification: the queue must see a canceled token.
      final other = CancelToken();
      final second = expectLater(
        upload(token: other),
        throwsA(isA<DioException>()),
      );
      await pumpEventQueue();
      await _emit('job2', UploadEventState.canceled);
      await second;
      expect(other.isCancelled, isTrue);
    },
  );

  test('handles a result that arrives before enqueue returns', () async {
    // The host replies with the id only after emitting the result.
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const codec = UploadApi.pigeonChannelCodec;
    messenger.setMockMessageHandler('${_host}enqueue', (data) async {
      await _emit(
        'early',
        UploadEventState.completed,
        status: 200,
        body: '{"code":200}',
      );
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
    await _emit(
      'job2',
      UploadEventState.completed,
      status: 200,
      body: '{"code":200}',
    );
    await pumpEventQueue();
    expect(job.state, UploadState.succeeded);
  });

  test('falls back to the Dart upload where native cannot run', () async {
    // iOS loopback: the in-process core is suspended in background.
    uploader = NativeUploader(platform: TargetPlatform.iOS);
    await upload(
      client: OpenListClient(baseUrl: 'http://127.0.0.1:5244', token: 't'),
    );
    await upload(
      client: OpenListClient(baseUrl: 'https://127.0.0.1:5245', token: 't'),
    );
    // iOS plain HTTP remote: blocked by ATS.
    await upload(
      client: OpenListClient(baseUrl: 'http://files.example.com', token: 't'),
    );
    expect(fallbacks, 3);
    expect(host.requests, isEmpty);

    // Android loopback runs natively over HTTP and over HTTPS, where the
    // worker pins the core's certificate.
    uploader = NativeUploader(platform: TargetPlatform.android);
    unawaited(
      upload(
        client: OpenListClient(baseUrl: 'http://127.0.0.1:5244', token: 't'),
      ),
    );
    unawaited(
      upload(
        client: OpenListClient(baseUrl: 'https://127.0.0.1:5245', token: 't'),
      ),
    );
    unawaited(
      upload(
        client: OpenListClient(baseUrl: 'https://[::1]:5245', token: 't'),
      ),
    );
    await pumpEventQueue();
    expect(host.requests.map((r) => r.url), [
      'http://127.0.0.1:5244/api/fs/put',
      'https://127.0.0.1:5245/api/fs/put',
      'https://[::1]:5245/api/fs/put',
    ]);
    expect(fallbacks, 3);
  });

  test(
    'records each native job without credentials until its result',
    () async {
      final done = uploader.upload(
        _client,
        filePath: '/tmp/a.bin',
        dstPath: '/dir/a.bin',
        title: 'a.bin',
        dir: '/dir',
        size: 10,
        password: 'pw',
        fallback: () async => fallbacks++,
      );
      await pumpEventQueue();
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('${NativeUploader.recordPrefix}job1')!;
      expect(jsonDecode(stored), {
        'id': 'job1',
        'name': 'a.bin',
        'dir': '/dir',
        'dstPath': '/dir/a.bin',
        'filePath': '/tmp/a.bin',
        'size': 10,
        'baseUrl': 'https://files.example.com/base',
      });
      expect(stored, isNot(contains('tok')));
      expect(stored, isNot(contains('pw')));

      await _emit(
        'job1',
        UploadEventState.completed,
        status: 200,
        body: '{"code":200}',
      );
      await done;
      await pumpEventQueue();
      expect(await _recordIds(), isEmpty);
    },
  );

  group('restore', () {
    late UploadQueue queue;

    Future<UploadJob> restoreOne(String id, {UploadEvent? state}) async {
      SharedPreferences.setMockInitialValues({
        '${NativeUploader.recordPrefix}$id': _record(id),
      });
      if (state != null) host.known[id] = state;
      await uploader.restore(queue: queue);
      await pumpEventQueue();
      return queue.jobs.single;
    }

    setUp(() => queue = UploadQueue(concurrency: 1));

    test(
      'replays a saved terminal result without executing or losing it',
      () async {
        SharedPreferences.setMockInitialValues({
          'native_upload_result.done': jsonEncode({
            'id': 'done',
            'timestamp': 1,
            'name': 'done.bin',
            'dir': '/dir',
            'size': 10,
            'success': true,
          }),
        });
        uploader = NativeUploader(
          platform: TargetPlatform.android,
          currentClient: () => _client,
        );

        await uploader.restore(queue: queue);
        await pumpEventQueue();

        expect(queue.jobs, hasLength(1));
        expect(queue.jobs.single.state, UploadState.succeeded);
        expect(host.restored, [<String>[]]);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.containsKey('native_upload_result.done'), isTrue);

        queue.clearFinished();
        await pumpEventQueue();
        expect(prefs.containsKey('native_upload_result.done'), isFalse);
      },
    );

    test('shows a running job outside the concurrency limit', () async {
      final job = await restoreOne(
        'old',
        state: _event('old', UploadEventState.running, sent: 3, total: 10),
      );
      expect(host.restored.single, ['old']);
      expect(job.name, 'old.bin');
      expect(job.dir, '/dir');
      expect(job.size, 10);
      expect(job.state, UploadState.running);
      expect(job.sent, 3);

      // A new job still gets the single slot.
      queue.add(
        UploadJob(
          name: 'new',
          dir: '/dir',
          size: 1,
          run: (token, onProgress) => upload(token: token),
        ),
      );
      await pumpEventQueue();
      expect(queue.jobs.last.state, UploadState.running);

      await _emit('old', UploadEventState.running, sent: 7, total: 10);
      expect(job.sent, 7);
      await _emit(
        'old',
        UploadEventState.completed,
        status: 200,
        body: '{"code":200}',
      );
      await pumpEventQueue();
      expect(job.state, UploadState.succeeded);
      expect(await _recordIds(), {'job1'});
    });

    test('applies finished results through the envelope check', () async {
      final ok = await restoreOne(
        'ok',
        state: _event(
          'ok',
          UploadEventState.completed,
          status: 200,
          body: '{"code":200}',
        ),
      );
      expect(ok.state, UploadState.succeeded);

      queue = UploadQueue();
      uploader = NativeUploader(platform: TargetPlatform.android);
      final denied = await restoreOne(
        'denied',
        state: _event(
          'denied',
          UploadEventState.completed,
          status: 200,
          body: '{"code":403,"message":"permission denied"}',
        ),
      );
      expect(denied.state, UploadState.failed);
      expect(
        denied.error,
        isA<ApiException>().having((e) => e.code, 'code', 403),
      );
      expect(await _recordIds(), {'denied'});
    });

    test(
      'fails a job the platform no longer knows and drops its record',
      () async {
        final job = await restoreOne('gone');
        expect(job.state, UploadState.failed);
        expect(job.error, isA<ApiException>());
        expect(await _recordIds(), isEmpty);
      },
    );

    test('cancel cancels the native job', () async {
      final job = await restoreOne(
        'old',
        state: _event('old', UploadEventState.enqueued),
      );
      queue.cancel(job);
      await pumpEventQueue();
      expect(job.state, UploadState.canceled);
      expect(host.canceled, ['old']);
      expect(await _recordIds(), {'old'});
    });

    test(
      'retry re-enqueues the recorded file with the session client',
      () async {
        final job = await restoreOne('gone');
        queue.retry(job);
        await pumpEventQueue();
        final req = host.requests.single;
        expect(req.url, 'https://files.example.com/base/api/fs/put');
        expect(req.filePath, '/tmp/gone.bin');
        expect(req.headers['File-Path'], '/dir/gone.bin');
        expect(req.headers['Authorization'], 'tok');
        expect(req.headers.containsKey('Password'), isFalse);
        expect(await _recordIds(), {'job1'});

        await _emit(
          'job1',
          UploadEventState.completed,
          status: 200,
          body: '{"code":200}',
        );
        await pumpEventQueue();
        expect(job.state, UploadState.succeeded);
      },
    );

    test('retry fails when the session points at another server', () async {
      uploader = NativeUploader(
        platform: TargetPlatform.android,
        currentClient: () =>
            OpenListClient(baseUrl: 'https://other.example.com', token: 't'),
      );
      final job = await restoreOne('gone');
      queue.retry(job);
      await pumpEventQueue();
      expect(job.state, UploadState.failed);
      expect(
        job.error,
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('https://files.example.com/base'),
        ),
      );
      expect(host.requests, isEmpty);
    });

    test('runs once and keeps records when the host call fails', () async {
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMessageHandler('${_host}restore', null);
      SharedPreferences.setMockInitialValues({
        '${NativeUploader.recordPrefix}old': _record('old'),
      });
      await uploader.restore(queue: queue);
      await uploader.restore(queue: queue);
      expect(queue.jobs, isEmpty);
      expect(await _recordIds(), {'old'});
    });
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
