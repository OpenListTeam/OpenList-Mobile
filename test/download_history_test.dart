import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:openlist_mobile/utils/download_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads terminal download history and notifies listeners', () async {
    SharedPreferences.setMockInitialValues({
      'download_task_history.v1': jsonEncode([
        {
          'id': 'task-1',
          'filename': 'report.pdf',
          'status': 'failed',
          'progress': 0.4,
          'receivedBytes': 40,
          'totalBytes': 100,
          'startTime': 1000,
          'endTime': 2000,
          'errorMessage': 'Download failed',
        },
        {
          'id': 'task-active',
          'filename': 'unfinished.bin',
          'status': 'downloading',
          'progress': 0.5,
          'receivedBytes': 50,
          'totalBytes': 100,
          'startTime': 1000,
        },
      ]),
    });

    var notifications = 0;
    void listener() => notifications++;
    DownloadManager.addListener(listener);
    await DownloadManager.initialize();
    DownloadManager.removeListener(listener);

    expect(notifications, 1);
    expect(DownloadManager.allTasks.map((task) => task.filename), [
      'report.pdf',
    ]);
    expect(DownloadManager.completedTasks.single.status, DownloadStatus.failed);
    expect(DownloadManager.completedTasks.single.url, isEmpty);
    expect(DownloadManager.completedTasks.single.filePath, isEmpty);
  });

  test('history serialization excludes URLs, paths, and detailed errors', () {
    final task = DownloadTask(
      id: 'task-2',
      url: 'https://example.test/file?token=secret',
      filename: 'file.bin',
      filePath: '/private/file.bin',
      directoryReference: 'directory-3',
      status: DownloadStatus.failed,
      errorMessage: 'https://example.test/file?token=secret failed',
    );

    final history = task.toHistory();
    final serialized = jsonEncode(history);
    expect(history, isNot(contains('url')));
    expect(history, isNot(contains('filePath')));
    expect(history['directoryReference'], 'directory-3');
    expect(serialized, isNot(contains('secret')));
    expect(DownloadTask.fromHistory(history)?.status, DownloadStatus.failed);
  });
}
