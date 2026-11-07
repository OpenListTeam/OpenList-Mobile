import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openlist_mobile/api/media_api.dart';
import 'package:openlist_mobile/api/openlist_client.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.respond);

  final Map<String, dynamic> Function(RequestOptions options) respond;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode(respond(options)),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('lists media and preserves the server query', () async {
    final adapter = _FakeAdapter(
      (_) => {
        'code': 200,
        'message': 'success',
        'data': {
          'content': [
            {
              'id': 7,
              'media_type': 'video',
              'file_name': 'film.mp4',
              'folder_path': '/media',
              'is_folder': true,
              'file_size': 1024,
              'episodes': '[{"file_name":"part1.mp4","title":"Part 1"}]',
            },
          ],
          'total': 1,
        },
      },
    );
    final client = OpenListClient(
      baseUrl: 'https://example.test',
      dio: Dio()..httpClientAdapter = adapter,
    );

    final page = await MediaApi(client).list('video');
    final item = page.items.single;
    final request = adapter.requests.single;

    expect(request.path, '/api/fs/media/list');
    expect(request.queryParameters['media_type'], 'video');
    expect(request.queryParameters['page_size'], 40);
    expect(page.total, 1);
    expect(item.path, '/media/film.mp4');
    expect(item.episodes.single.fileName, 'part1.mp4');
    expect(item.episodePath(item.episodes.single), '/media/film.mp4/part1.mp4');
  });

  test('sets an item-level favorite', () async {
    final adapter = _FakeAdapter(
      (_) => {
        'code': 200,
        'message': 'success',
        'data': {'favorite': true},
      },
    );
    final client = OpenListClient(
      baseUrl: 'https://example.test',
      dio: Dio()..httpClientAdapter = adapter,
    );

    await MediaApi(client).setFavorite(23, true);
    final request = adapter.requests.single;
    expect(request.path, '/api/fs/media/favorite');
    expect(request.data, {'item_id': 23, 'episode_index': 0, 'favorite': true});
  });
}
