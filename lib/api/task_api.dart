import 'models.dart';
import 'openlist_client.dart';

/// Task groups registered by `handles.SetupTaskRoute`.
class TaskGroup {
  static const upload = 'upload';
  static const copy = 'copy';
  static const move = 'move';
  static const offlineDownload = 'offline_download';
  static const offlineDownloadTransfer = 'offline_download_transfer';
  static const decompress = 'decompress';
  static const decompressUpload = 'decompress_upload';

  static const all = [
    upload,
    copy,
    move,
    offlineDownload,
    offlineDownloadTransfer,
    decompress,
    decompressUpload,
  ];
}

/// Task endpoints under `/api/task/{group}`.
class TaskApi {
  TaskApi(this.client);

  final OpenListClient client;

  static List<TaskInfo> _tasks(dynamic data) => ((data as List?) ?? const [])
      .map((e) => TaskInfo.fromJson(Map<String, dynamic>.from(e)))
      .toList();

  Future<List<TaskInfo>> undone(String group) async =>
      _tasks(await client.get('/api/task/$group/undone'));

  Future<List<TaskInfo>> done(String group) async =>
      _tasks(await client.get('/api/task/$group/done'));

  Future<void> cancel(String group, String id) =>
      client.post('/api/task/$group/cancel', query: {'tid': id});

  Future<void> delete(String group, String id) =>
      client.post('/api/task/$group/delete', query: {'tid': id});

  Future<void> retry(String group, String id) =>
      client.post('/api/task/$group/retry', query: {'tid': id});

  Future<void> clearDone(String group) =>
      client.post('/api/task/$group/clear_done');

  Future<void> clearSucceeded(String group) =>
      client.post('/api/task/$group/clear_succeeded');

  Future<void> retryFailed(String group) =>
      client.post('/api/task/$group/retry_failed');
}
