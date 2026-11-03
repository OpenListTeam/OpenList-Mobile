import 'package:flutter_test/flutter_test.dart';
import 'package:openlist_mobile/api/archive_api.dart';
import 'package:openlist_mobile/api/openlist_client.dart';

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
