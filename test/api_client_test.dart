import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openlist_mobile/api/admin_api.dart';
import 'package:openlist_mobile/api/fs_api.dart';
import 'package:openlist_mobile/api/loopback_http.dart';
import 'package:openlist_mobile/api/models.dart';
import 'package:openlist_mobile/api/openlist_client.dart';
import 'package:openlist_mobile/api/session.dart';
import 'package:openlist_mobile/api/task_api.dart';
import 'package:openlist_mobile/generated_api.dart';

/// Records requests and answers with a canned envelope.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.respond);

  final Map<String, dynamic> Function(RequestOptions o) respond;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    return ResponseBody.fromString(jsonEncode(respond(options)), 200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        });
  }

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> _ok(dynamic data) =>
    {'code': 200, 'message': 'success', 'data': data};

(OpenListClient, _FakeAdapter) _client(
    Map<String, dynamic> Function(RequestOptions o) respond) {
  final adapter = _FakeAdapter(respond);
  final dio = Dio()..httpClientAdapter = adapter;
  return (
    OpenListClient(baseUrl: 'http://127.0.0.1:5244/', token: 'tk', dio: dio),
    adapter,
  );
}

void main() {
  group('envelope', () {
    test('returns data on code 200', () {
      expect(OpenListClient.unwrap(200, _ok({'a': 1})), {'a': 1});
    });

    test('throws ApiException with envelope code', () {
      expect(
        () => OpenListClient.unwrap(200, {'code': 401, 'message': 'expired'}),
        throwsA(isA<ApiException>()
            .having((e) => e.code, 'code', 401)
            .having((e) => e.isUnauthorized, 'unauthorized', true)
            .having((e) => e.message, 'message', 'expired')),
      );
    });

    test('non-envelope error body uses HTTP status', () {
      expect(() => OpenListClient.unwrap(502, 'bad gateway'),
          throwsA(isA<ApiException>().having((e) => e.code, 'code', 502)));
    });
  });

  test('path helpers encode segments and join', () {
    expect(OpenListClient.encodePath('/a b/c#d'), '/a%20b/c%23d');
    expect(OpenListClient.join('/', 'x'), '/x');
    expect(OpenListClient.join('/dir/', 'x'), '/dir/x');
    expect(OpenListClient.join('/dir', 'x'), '/dir/x');
  });

  test('fs list sends auth header and parses objects', () async {
    final (c, adapter) = _client((_) => _ok({
          'content': [
            {
              'name': 'docs',
              'size': 0,
              'is_dir': true,
              'modified': '2024-01-02T03:04:05Z',
              'type': 1,
            },
            {
              'name': 'a.txt',
              'size': 12,
              'is_dir': false,
              'modified': '0001-01-01T00:00:00Z',
              'sign': 's1',
              'type': 4,
            },
          ],
          'total': 2,
          'write': true,
        }));
    final res = await FsApi(c).list('/');
    final req = adapter.requests.single;
    expect(req.path, '/api/fs/list');
    expect(req.headers['Authorization'], 'tk');
    expect(req.data['path'], '/');
    expect(res.total, 2);
    expect(res.write, isTrue);
    expect(res.content.first.isDir, isTrue);
    expect(res.content.first.modified, DateTime.utc(2024, 1, 2, 3, 4, 5));
    expect(res.content.last.modified, isNull);
    expect(res.content.last.type, ObjType.text);
  });

  test('download url encodes path and sign', () {
    final (c, _) = _client((_) => _ok(null));
    expect(FsApi(c).downloadUrl('/a b/c.txt', sign: 'x=y'),
        'http://127.0.0.1:5244/d/a%20b/c.txt?sign=x%3Dy');
    expect(FsApi(c).downloadUrl('/c.txt'), 'http://127.0.0.1:5244/d/c.txt');
  });

  test('upload sends OpenList headers', () async {
    final (c, adapter) = _client((_) => _ok(null));
    await FsApi(c).upload(
      '/dir/新 文件.txt',
      Stream.value([1, 2, 3]),
      3,
      lastModified: DateTime.fromMillisecondsSinceEpoch(1700000000000),
    );
    final req = adapter.requests.single;
    expect(req.method, 'PUT');
    expect(req.headers['File-Path'],
        '/dir/${Uri.encodeComponent('新 文件.txt')}');
    expect(req.headers['As-Task'], 'false');
    expect(req.headers['Overwrite'], 'false');
    expect(req.headers['Last-Modified'], '1700000000000');
  });

  test('task actions pass tid as query', () async {
    final (c, adapter) = _client((o) => o.path.endsWith('/undone')
        ? _ok([
            {'id': '1', 'name': 'copy a', 'state': 1, 'progress': 42.5}
          ])
        : _ok(null));
    final api = TaskApi(c);
    final tasks = await api.undone(TaskGroup.copy);
    expect(tasks.single.progress, 42.5);
    expect(tasks.single.isActive, isTrue);
    await api.cancel(TaskGroup.copy, '1');
    final req = adapter.requests.last;
    expect(req.path, '/api/task/copy/cancel');
    expect(req.queryParameters['tid'], '1');
  });

  test('storage list keeps unmodelled fields', () async {
    final (c, _) = _client((_) => _ok({
          'content': [
            {
              'id': 3,
              'mount_path': '/local',
              'driver': 'Local',
              'status': 'work',
              'addition': '{"root_folder_path":"/sdcard"}',
              'seed_policy': 'inherit',
            }
          ],
          'total': 1,
        }));
    final s = (await AdminApi(c).listStorages()).single;
    expect(s.id, 3);
    expect(s.isWorking, isTrue);
    expect(s.toJson()['seed_policy'], 'inherit');
  });

  test('driver info parses items', () {
    final info = DriverInfo.fromJson({
      'common': [
        {'name': 'mount_path', 'type': 'string', 'required': true}
      ],
      'additional': [
        {'name': 'order_by', 'type': 'select', 'options': 'name, size,'}
      ],
    });
    expect(info.common.single.required, isTrue);
    expect(info.additional.single.optionList, ['name', 'size']);
  });

  test('local base url prefers http unless https is forced', () {
    ServerStatus s(int http, int https, bool force) => ServerStatus(
          running: true,
          mode: 'local',
          httpPort: http,
          httpsPort: https,
          forceHttps: force,
          addresses: const [],
          manuallyStopped: false,
        );
    expect(OpenListSession.localBaseUrl(s(5244, -1, false)),
        'http://127.0.0.1:5244');
    expect(OpenListSession.localBaseUrl(s(5244, 5245, true)),
        'https://127.0.0.1:5245');
    expect(OpenListSession.localBaseUrl(s(-1, 5245, false)),
        'https://127.0.0.1:5245');
  });

  test('loopback hosts are recognised', () {
    for (final h in ['127.0.0.1', '127.8.0.1', 'localhost', '::1']) {
      expect(isLoopbackHost(h), isTrue, reason: h);
    }
    for (final h in ['192.168.1.2', 'example.com', '10.0.0.1']) {
      expect(isLoopbackHost(h), isFalse, reason: h);
    }
  });

  test('only password 403s ask for a folder password', () {
    expect(
        ApiException(403, 'password is incorrect or you have no permission')
            .isPasswordRequired,
        isTrue);
    expect(ApiException(403, 'Refresh without permission').isPasswordRequired,
        isFalse);
    expect(ApiException(500, 'password').isPasswordRequired, isFalse);
  });
}
