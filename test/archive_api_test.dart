import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openlist_mobile/api/archive_api.dart';
import 'package:openlist_mobile/api/openlist_client.dart';

class _ArchiveAdapter implements HttpClientAdapter {
  _ArchiveAdapter(this.respond);

  final Map<String, dynamic> Function(RequestOptions options) respond;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    return ResponseBody.fromString(jsonEncode(respond(options)), 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('archive entry URL uses Core raw URL and appends sign and inner path',
      () {
    final api = ArchiveApi(OpenListClient(
      baseUrl: 'https://core.example.com/openlist',
      token: 'secret-token',
    ));
    final meta = ArchiveMeta(
      content: const [],
      sign: 'archive-sign',
      rawUrl: 'https://core.example.com/openlist/ad/archive%20file.zip',
    );

    final uri = Uri.parse(
        api.entryUrl(meta, '/nested/file.txt', archivePassword: 'pw'));
    expect(uri.path, '/openlist/ad/archive%20file.zip');
    expect(uri.queryParameters['sign'], 'archive-sign');
    expect(uri.queryParameters['inner'], '/nested/file.txt');
    expect(uri.queryParameters['pass'], 'pw');
    expect(api.headersFor(uri.toString()), {'Authorization': 'secret-token'});
  });

  test('archive adapter sends Core request fields and decodes responses',
      () async {
    final adapter = _ArchiveAdapter((options) {
      if (options.path.endsWith('/meta')) {
        return {
          'code': 200,
          'data': {
            'encrypted': true,
            'sign': 'sig',
            'raw_url': 'http://127.0.0.1:5244/ad/archive.zip',
            'content': [],
          },
        };
      }
      return {
        'code': 200,
        'data': {'content': [], 'total': 0},
      };
    });
    final dio = Dio()..httpClientAdapter = adapter;
    final api = ArchiveApi(OpenListClient(
      baseUrl: 'http://127.0.0.1:5244',
      token: 'token',
      dio: dio,
    ));

    final meta = await api.meta('/archive.zip', archivePassword: 'secret');
    final list = await api.list('/archive.zip',
        archivePassword: 'secret', innerPath: '/nested', page: 2, perPage: 10);

    expect(meta.encrypted, isTrue);
    expect(meta.rawUrl, contains('/ad/archive.zip'));
    expect(list.total, 0);
    expect(adapter.requests.map((request) => request.path), [
      '/api/fs/archive/meta',
      '/api/fs/archive/list',
    ]);
    expect(adapter.requests[0].data['archive_pass'], 'secret');
    expect(adapter.requests[1].data['inner_path'], '/nested');
    expect(adapter.requests[1].data['page'], 2);
    expect(adapter.requests[1].data['per_page'], 10);
  });

  test('archive entry URL does not forward credentials to third-party URL', () {
    final api = ArchiveApi(OpenListClient(
      baseUrl: 'https://core.example.com',
      token: 'secret-token',
    ));
    final meta = ArchiveMeta(
        content: const [], rawUrl: 'https://storage.example.net/archive');
    final url = api.entryUrl(meta, 'file.txt');
    expect(api.headersFor(url), isEmpty);
  });
}
