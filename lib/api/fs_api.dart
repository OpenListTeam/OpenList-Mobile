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
        '/api/fs/put',
        data: data,
        headers: {
          'File-Path': OpenListClient.encodePath(dstPath),
          'As-Task': '$asTask',
          'Overwrite': '$overwrite',
          Headers.contentLengthHeader: '$length',
          Headers.contentTypeHeader: 'application/octet-stream',
          if (password.isNotEmpty) 'Password': password,
          if (lastModified != null)
            'Last-Modified': '${lastModified.millisecondsSinceEpoch}',
        },
        onSendProgress: onProgress,
        cancelToken: cancelToken,
      );

  /// Direct download URL served by the core (`/d/*path?sign=`).
  String downloadUrl(String path, {String sign = ''}) {
    final url = '${client.baseUrl}/d${OpenListClient.encodePath(path)}';
    return sign.isEmpty ? url : '$url?sign=${Uri.encodeQueryComponent(sign)}';
  }
}
