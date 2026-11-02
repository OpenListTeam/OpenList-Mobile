import 'package:dio/dio.dart';

import 'models.dart';
import 'openlist_client.dart';

/// File system endpoints under `/api/fs`.
class FsApi {
  FsApi(this.client);

  final OpenListClient client;

  Future<FsListResult> list(
    String path, {
    String password = '',
    int page = 1,
    int perPage = 0,
    bool refresh = false,
  }) async {
    final data = await client.post('/api/fs/list', body: {
      'path': path,
      'password': password,
      'page': page,
      'per_page': perPage,
      'refresh': refresh,
    });
    return FsListResult.fromJson(Map<String, dynamic>.from(data ?? {}));
  }

  Future<FsObject> get(String path, {String password = ''}) async {
    final data = await client
        .post('/api/fs/get', body: {'path': path, 'password': password});
    return FsObject.fromJson(Map<String, dynamic>.from(data ?? {}));
  }

  Future<void> mkdir(String path) =>
      client.post('/api/fs/mkdir', body: {'path': path});

  /// Creates an empty file at [path] using PUT with empty body
  Future<void> touchFile(String path, {bool overwrite = false}) async {
    await client.put(
      '/api/fs/put',
      data: '',
      headers: {
        'File-Path': OpenListClient.encodePath(path),
        'Overwrite': '$overwrite',
        'Content-Type': 'application/octet-stream',
      },
    );
  }

  Future<void> rename(String path, String name, {bool overwrite = false}) =>
      client.post('/api/fs/rename',
          body: {'path': path, 'name': name, 'overwrite': overwrite});

  Future<void> move(String srcDir, String dstDir, List<String> names,
          {bool overwrite = false}) =>
      client.post('/api/fs/move', body: {
        'src_dir': srcDir,
        'dst_dir': dstDir,
        'names': names,
        'overwrite': overwrite,
      });

  Future<void> copy(String srcDir, String dstDir, List<String> names,
          {bool overwrite = false}) =>
      client.post('/api/fs/copy', body: {
        'src_dir': srcDir,
        'dst_dir': dstDir,
        'names': names,
        'overwrite': overwrite,
      });

  Future<void> remove(String dir, List<String> names) =>
      client.post('/api/fs/remove', body: {'dir': dir, 'names': names});

  static const uploadPath = '/api/fs/put';

  /// `fs/put` headers except Content-Length, shared with the native uploader.
  static Map<String, String> uploadHeaders(
    String dstPath, {
    bool asTask = false,
    bool overwrite = false,
    String password = '',
    DateTime? lastModified,
  }) =>
      {
        'File-Path': OpenListClient.encodePath(dstPath),
        'As-Task': '$asTask',
        'Overwrite': '$overwrite',
        Headers.contentTypeHeader: 'application/octet-stream',
        if (password.isNotEmpty) 'Password': password,
        if (lastModified != null)
          'Last-Modified': '${lastModified.millisecondsSinceEpoch}',
      };

  /// Streams [data] to `dstPath` via `PUT /api/fs/put`.
  Future<void> upload(
    String dstPath,
    Stream<List<int>> data,
    int length, {
    bool asTask = false,
    bool overwrite = false,
    String password = '',
    DateTime? lastModified,
    ProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) =>
      client.put(
        uploadPath,
        data: data,
        headers: {
          ...uploadHeaders(dstPath,
              asTask: asTask,
              overwrite: overwrite,
              password: password,
              lastModified: lastModified),
          Headers.contentLengthHeader: '$length',
        },
        onSendProgress: onProgress,
        cancelToken: cancelToken,
      );

  /// Searches the index under [parent]; scope 0 = all, 1 = dirs, 2 = files.
  /// Returns the hits of one page and the total hit count.
  Future<(List<SearchHit>, int)> search(
    String parent,
    String keywords, {
    int scope = 0,
    int page = 1,
    int perPage = 100,
    String password = '',
  }) async {
    final data = await client.post('/api/fs/search', body: {
      'parent': parent,
      'keywords': keywords,
      'scope': scope,
      'page': page,
      'per_page': perPage,
      'password': password,
    });
    final m = data is Map ? data : const {};
    final hits = ((m['content'] as List?) ?? const [])
        .map((e) => SearchHit.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    final total = m['total'];
    return (hits, total is num ? total.toInt() : hits.length);
  }

  /// Offline download tools usable for [path].
  Future<List<String>> offlineTools({String path = ''}) async {
    final data = await client.get('/api/public/offline_download_tools',
        query: {if (path.isNotEmpty) 'path': path});
    return ((data as List?) ?? const []).map((e) => '$e').toList();
  }

  /// Queues offline download tasks for [urls] into [path].
  Future<void> addOfflineDownload(
    List<String> urls,
    String path,
    String tool, {
    String deletePolicy = 'delete_on_upload_succeed',
  }) =>
      client.post('/api/fs/add_offline_download', body: {
        'urls': urls,
        'path': path,
        'tool': tool,
        'delete_policy': deletePolicy,
      });

  /// Direct download URL served by the core (`/d/*path?sign=`).
  String downloadUrl(String path, {String sign = ''}) {
    final url = '${client.baseUrl}/d${OpenListClient.encodePath(path)}';
    return sign.isEmpty ? url : '$url?sign=${Uri.encodeQueryComponent(sign)}';
  }
}
