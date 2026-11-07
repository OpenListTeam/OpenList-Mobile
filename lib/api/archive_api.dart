import 'package:openlist_mobile/api/models.dart';
import 'package:openlist_mobile/api/openlist_client.dart';

class ArchiveMeta {
  ArchiveMeta({
    required this.content,
    this.encrypted = false,
    this.sign = '',
    this.rawUrl = '',
  });

  final List<FsObject> content;
  final bool encrypted;
  final String sign;
  final String rawUrl;

  factory ArchiveMeta.fromJson(Map<String, dynamic> json) => ArchiveMeta(
        content: ((json['content'] as List?) ?? const [])
            .map((e) => FsObject.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        encrypted: json['encrypted'] == true,
        sign: '${json['sign'] ?? ''}',
        rawUrl: '${json['raw_url'] ?? ''}',
      );
}

/// Authenticated archive inspection endpoints provided by OpenList Core.
class ArchiveApi {
  ArchiveApi(this.client);
  final OpenListClient client;

  Future<ArchiveMeta> meta(String path,
      {String password = '',
      String archivePassword = '',
      bool refresh = false}) async {
    final data = await client.post('/api/fs/archive/meta', body: {
      'path': path,
      'password': password,
      'archive_pass': archivePassword,
      'refresh': refresh,
    });
    return ArchiveMeta.fromJson(Map<String, dynamic>.from(data ?? {}));
  }

  Future<FsListResult> list(String path,
      {String password = '',
      String archivePassword = '',
      String innerPath = '/',
      int page = 1,
      int perPage = 0,
      bool refresh = false}) async {
    final data = await client.post('/api/fs/archive/list', body: {
      'path': path,
      'password': password,
      'archive_pass': archivePassword,
      'inner_path': innerPath,
      'page': page,
      'per_page': perPage,
      'refresh': refresh,
    });
    return FsListResult.fromJson(Map<String, dynamic>.from(data ?? {}));
  }

  /// Core exposes its supported archive extensions without authentication.
  Future<Set<String>> extensions() async {
    final data = await client.get('/api/public/archive_extensions');
    return ((data as List?) ?? const [])
        .map((value) => '$value'.toLowerCase().replaceFirst('.', ''))
        .where((value) => value.isNotEmpty)
        .toSet();
  }

  /// Builds the Core-provided extraction URL, preserving driver-specific `/ad`
  /// routes and archive signatures returned by the meta endpoint.
  String entryUrl(ArchiveMeta meta, String innerPath,
      {String archivePassword = ''}) {
    final base = Uri.parse(meta.rawUrl);
    return base.replace(queryParameters: {
      ...base.queryParameters,
      if (meta.sign.isNotEmpty) 'sign': meta.sign,
      'inner': innerPath,
      if (archivePassword.isNotEmpty) 'pass': archivePassword,
    }).toString();
  }

  /// Adds credentials only when the extraction URL belongs to this Core.
  Map<String, String> headersFor(String url) {
    final uri = Uri.tryParse(url);
    final base = Uri.tryParse(client.baseUrl);
    if (uri == null ||
        base == null ||
        uri.origin != base.origin ||
        client.token.isEmpty) {
      return const {};
    }
    return {'Authorization': client.token};
  }
}
