import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openlist_mobile/generated/l10n.dart';
import 'package:openlist_mobile/utils/download_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.respond);

  final Future<ResponseBody> Function(RequestOptions, int) respond;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) {
    requests.add(options);
    return respond(options, requests.length);
  }

  @override
  void close({bool force = false}) {}
}

Future<({DownloadTask task, Future<bool> done})> _startPaused(
    _Adapter adapter) async {
  final paused = Completer<DownloadTask>();
  void listener() {
    final tasks = DownloadManager.activeTasks;
    if (tasks.isEmpty || paused.isCompleted) return;
    final task = tasks.single;
    if (task.status == DownloadStatus.downloading && task.receivedBytes > 0) {
      DownloadManager.pauseDownload(task.id);
      paused.complete(task);
    }
  }

  DownloadManager.addListener(listener);
  final done = DownloadManager.downloadFileWithProgress(
    url: 'https://files.example.test/file.bin',
    filename: 'file.bin',
    client: Dio()..httpClientAdapter = adapter,
    headers: {'range': 'bytes=99-', 'accept-encoding': 'gzip'},
  );
  try {
    final task = await paused.future.timeout(const Duration(seconds: 5));
    return (task: task, done: done);
  } finally {
    DownloadManager.removeListener(listener);
  }
}

ResponseBody _partialResponse(Map<String, List<String>> headers) {
  final controller = StreamController<Uint8List>();
  controller.onCancel = () {
    unawaited(controller.close());
  };
  controller.add(Uint8List.fromList([1, 2, 3, 4]));
  return ResponseBody(controller.stream, 200, headers: {
    Headers.contentLengthHeader: ['8'],
    ...headers,
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await S.load(const Locale('en'));
    DownloadManager.clearCompletedTasks();
    directory = await Directory.systemTemp.createTemp('openlist-transfer-');
    expect(await DownloadManager.setDownloadDirectory(directory.path), isTrue);
  });

  tearDown(() async {
    for (final task in DownloadManager.activeTasks) {
      DownloadManager.cancelDownload(task.id);
    }
    DownloadManager.clearCompletedTasks();
    await directory.delete(recursive: true);
  });

  for (final mode in [
    'range',
    'ignore',
    'changed',
    '416',
    'weak',
    'no-validator',
    'modified',
    'gzip',
  ]) {
    test('pause and resume handles $mode responses without mixing bytes',
        () async {
      final validator = mode == 'modified'
          ? {
              'last-modified': ['Thu, 05 Nov 2026 00:00:00 GMT']
            }
          : mode == 'no-validator'
              ? <String, List<String>>{}
              : {
                  'etag': [mode == 'weak' ? 'W/"v1"' : '"v1"']
                };
      final expected = mode == 'changed' || mode == '416' || mode == 'ignore'
          ? [8, 7, 6, 5, 4, 3, 2, 1]
          : [1, 2, 3, 4, 5, 6, 7, 8];
      final rangeSupported = !['weak', 'no-validator', 'gzip'].contains(mode);
      final adapter = _Adapter((options, attempt) async {
        expect(options.headers[HttpHeaders.acceptEncodingHeader], 'identity');
        if (attempt == 1) {
          expect(options.headers[HttpHeaders.rangeHeader], isNull);
          return _partialResponse({
            ...validator,
            if (mode == 'gzip') 'content-encoding': ['gzip'],
          });
        }
        if (attempt == 2 && rangeSupported) {
          expect(options.headers[HttpHeaders.rangeHeader], 'bytes=4-');
          expect(options.headers[HttpHeaders.ifRangeHeader],
              validator.values.single.single);
          if (mode == '416') return ResponseBody.fromBytes([], 416);
          if (mode == 'changed') {
            return ResponseBody.fromBytes(expected.sublist(4), 206, headers: {
              'etag': ['"v2"'],
              'content-range': ['bytes 4-7/8'],
            });
          }
          if (mode != 'ignore') {
            return ResponseBody.fromBytes(expected.sublist(4), 206, headers: {
              ...validator,
              'content-range': ['bytes 4-7/8'],
            });
          }
        } else {
          expect(options.headers[HttpHeaders.rangeHeader], isNull);
          expect(options.headers[HttpHeaders.ifRangeHeader], isNull);
        }
        return ResponseBody.fromBytes(expected, 200, headers: {
          'etag': ['"v2"'],
          Headers.contentLengthHeader: ['8'],
        });
      });
      final download = await _startPaused(adapter);
      expect(download.task.status, DownloadStatus.paused);
      expect(await DownloadManager.clearDownloadDirectory(), isFalse);
      DownloadManager.resumeDownload(download.task.id);
      expect(await download.done.timeout(const Duration(seconds: 5)), isTrue);
      expect(await File(download.task.filePath).readAsBytes(), expected);
      expect(await File(download.task.partialFilePath!).exists(), isFalse);
      expect(download.task.status, DownloadStatus.completed);
      expect(
          adapter.requests.length, ['changed', '416'].contains(mode) ? 3 : 2);
    });
  }

  test('canceling a paused download removes its partial file promptly',
      () async {
    final adapter = _Adapter((_, attempt) async {
      expect(attempt, 1);
      return _partialResponse({
        'etag': ['"v1"']
      });
    });
    final download = await _startPaused(adapter);
    DownloadManager.cancelDownload(download.task.id);
    expect(download.task.status, DownloadStatus.cancelling);
    expect(await download.done.timeout(const Duration(seconds: 5)), isFalse);
    expect(download.task.status, DownloadStatus.cancelled);
    expect(await File(download.task.partialFilePath!).exists(), isFalse);
    expect(DownloadManager.activeTasks, isEmpty);
  });

  test('invalid partial responses fail instead of silently retrying', () async {
    final adapter = _Adapter((_, attempt) async {
      if (attempt == 1) {
        return _partialResponse({
          'etag': ['"v1"']
        });
      }
      return ResponseBody.fromBytes([5, 6, 7, 8], 206,
          headers: {
            'etag': ['"v1"'],
            'content-range': ['bytes 3-6/8'],
          });
    });
    final download = await _startPaused(adapter);
    DownloadManager.resumeDownload(download.task.id);
    expect(await download.done.timeout(const Duration(seconds: 5)), isFalse);
    expect(download.task.status, DownloadStatus.failed);
    expect(await File(download.task.partialFilePath!).exists(), isFalse);
    expect(adapter.requests.length, 2);
  });

  test('decoded gzip length is not compared with compressed Content-Length',
      () async {
    final adapter = _Adapter((_, __) async => ResponseBody.fromBytes(
          [1, 2, 3, 4],
          200,
          headers: {
            'content-encoding': ['gzip'],
            Headers.contentLengthHeader: ['2'],
          },
        ));
    final result = await DownloadManager.downloadFileWithProgress(
      url: 'https://files.example.test/compressed.bin',
      filename: 'compressed.bin',
      client: Dio()..httpClientAdapter = adapter,
    );
    expect(result, isTrue);
    final task = DownloadManager.completedTasks.single;
    expect(await File(task.filePath).readAsBytes(), [1, 2, 3, 4]);
    expect(task.totalBytes, 4);
  });
}
