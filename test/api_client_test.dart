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

Map<String, dynamic> _ok(dynamic data) => {
  'code': 200,
  'message': 'success',
  'data': data,
};

(OpenListClient, _FakeAdapter) _client(
  Map<String, dynamic> Function(RequestOptions o) respond,
) {
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
        throwsA(
          isA<ApiException>()
              .having((e) => e.code, 'code', 401)
              .having((e) => e.isUnauthorized, 'unauthorized', true)
              .having((e) => e.message, 'message', 'expired'),
        ),
      );
    });

    test('non-envelope error body uses HTTP status', () {
      expect(
        () => OpenListClient.unwrap(502, 'bad gateway'),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 502)),
      );
    });
  });

  test('path helpers encode segments and join', () {
    expect(OpenListClient.encodePath('/a b/c#d'), '/a%20b/c%23d');
    expect(OpenListClient.join('/', 'x'), '/x');
    expect(OpenListClient.join('/dir/', 'x'), '/dir/x');
    expect(OpenListClient.join('/dir', 'x'), '/dir/x');
  });

  test('fs list sends auth header and parses objects', () async {
    final (c, adapter) = _client(
      (_) => _ok({
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
      }),
    );
    final res = await FsApi(c).list('/', password: 'folder-secret');
    final req = adapter.requests.single;
    expect(req.path, '/api/fs/list');
    expect(req.headers['Authorization'], 'tk');
    expect(req.data['path'], '/');
    expect(req.data['password'], 'folder-secret');
    expect(res.total, 2);
    expect(res.write, isTrue);
    expect(res.content.first.isDir, isTrue);
    expect(res.content.first.modified, DateTime.utc(2024, 1, 2, 3, 4, 5));
    expect(res.content.last.modified, isNull);
    expect(res.content.last.type, ObjType.text);
  });

  test('fs batch rename posts the rename pairs', () async {
    final (c, adapter) = _client((_) => _ok(null));
    await FsApi(c).batchRename('/dir', const [
      RenameObj(srcName: 'a.txt', newName: 'b.txt'),
      RenameObj(srcName: 'c.txt', newName: 'd.txt'),
    ]);
    final req = adapter.requests.single;
    expect(req.method, 'POST');
    expect(req.path, '/api/fs/batch_rename');
    expect(req.data['src_dir'], '/dir');
    expect(req.data['rename_objects'], [
      {'src_name': 'a.txt', 'new_name': 'b.txt'},
      {'src_name': 'c.txt', 'new_name': 'd.txt'},
    ]);
  });

  test('download url encodes path and sign', () {
    final (c, _) = _client((_) => _ok(null));
    expect(
      FsApi(c).downloadUrl('/a b/c.txt', sign: 'x=y'),
      'http://127.0.0.1:5244/d/a%20b/c.txt?sign=x%3Dy',
    );
    expect(FsApi(c).downloadUrl('/c.txt'), 'http://127.0.0.1:5244/d/c.txt');
  });

  test('upload sends OpenList headers', () async {
    final (c, adapter) = _client((_) => _ok(null));
    await FsApi(c).upload(
      '/dir/新 文件.txt',
      Stream.value([1, 2, 3]),
      3,
      password: 'folder-secret',
      lastModified: DateTime.fromMillisecondsSinceEpoch(1700000000000),
    );
    final req = adapter.requests.single;
    expect(req.method, 'PUT');
    expect(req.headers['File-Path'], '/dir/${Uri.encodeComponent('新 文件.txt')}');
    expect(req.headers['As-Task'], 'false');
    expect(req.headers['Overwrite'], 'false');
    expect(req.headers['Last-Modified'], '1700000000000');
    expect(req.headers['Password'], 'folder-secret');
  });

  test('task actions pass tid as query', () async {
    final (c, adapter) = _client(
      (o) => o.path.endsWith('/undone')
          ? _ok([
              {'id': '1', 'name': 'copy a', 'state': 1, 'progress': 42.5},
            ])
          : _ok(null),
    );
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
    final (c, _) = _client(
      (_) => _ok({
        'content': [
          {
            'id': 3,
            'mount_path': '/local',
            'driver': 'Local',
            'status': 'work',
            'addition': '{"root_folder_path":"/sdcard"}',
            'seed_policy': 'inherit',
          },
        ],
        'total': 1,
      }),
    );
    final s = (await AdminApi(c).listStorages()).single;
    expect(s.id, 3);
    expect(s.isWorking, isTrue);
    expect(s.toJson()['seed_policy'], 'inherit');
  });

  test('driver info parses items', () {
    final info = DriverInfo.fromJson({
      'common': [
        {'name': 'mount_path', 'type': 'string', 'required': true},
      ],
      'additional': [
        {'name': 'order_by', 'type': 'select', 'options': 'name, size,'},
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
    expect(
      OpenListSession.localBaseUrl(s(5244, -1, false)),
      'http://127.0.0.1:5244',
    );
    expect(
      OpenListSession.localBaseUrl(s(5244, 5245, true)),
      'https://127.0.0.1:5245',
    );
    expect(
      OpenListSession.localBaseUrl(s(-1, 5245, false)),
      'https://127.0.0.1:5245',
    );
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
      ApiException(
        403,
        'password is incorrect or you have no permission',
      ).isPasswordRequired,
      isTrue,
    );
    expect(
      ApiException(403, 'Refresh without permission').isPasswordRequired,
      isFalse,
    );
    expect(ApiException(500, 'password').isPasswordRequired, isFalse);
  });

  test('search posts paging and parses hits', () async {
    final (c, adapter) = _client(
      (_) => _ok({
        'content': [
          {
            'parent': '/a',
            'name': 'b.mp4',
            'is_dir': false,
            'size': 9,
            'type': 2,
          },
        ],
        'total': 7,
      }),
    );
    final (hits, total) = await FsApi(c)
        .search('/a', 'b', scope: 2, password: 'folder-secret');
    expect(total, 7);
    expect(hits.single.path, '/a/b.mp4');
    expect(hits.single.type, ObjType.video);
    final body = adapter.requests.single.data as Map;
    expect(body['keywords'], 'b');
    expect(body['scope'], 2);
    expect(body['per_page'], 100);
    expect(body['password'], 'folder-secret');
  });

  test('offline download sends urls, tool and policy', () async {
    final (c, adapter) = _client(
      (o) => o.path.contains('tools') ? _ok(['aria2']) : _ok(null),
    );
    final api = FsApi(c);
    expect(await api.offlineTools(path: '/d'), ['aria2']);
    expect(adapter.requests.first.queryParameters['path'], '/d');
    await api.addOfflineDownload(['http://x/y'], '/d', 'aria2');
    final req = adapter.requests.last;
    expect(req.path, '/api/fs/add_offline_download');
    expect((req.data as Map)['delete_policy'], 'delete_on_upload_succeed');
  });

  test('user list keeps raw fields and decodes permission bits', () async {
    final (c, adapter) = _client(
      (_) => _ok({
        'content': [
          {'id': 2, 'username': 'u', 'role': 0, 'permission': 9, 'sso_id': 's'},
        ],
        'total': 1,
      }),
    );
    final u = (await AdminApi(c).listUsers()).single;
    expect(u.can(UserPerm.seeHides), isTrue);
    expect(u.can(UserPerm.write), isTrue);
    expect(u.can(UserPerm.rename), isFalse);
    expect(u.toJson()['sso_id'], 's');
    expect(u.basePath, '/');
    await AdminApi(c).deleteUser(2);
    expect(adapter.requests.last.queryParameters['id'], 2);
  });

  test('settings list joins groups and save posts an array', () async {
    final (c, adapter) = _client(
      (o) => o.path.endsWith('/list')
          ? _ok([
              {'key': 'site_title', 'value': 'A', 'type': 'string', 'flag': 0},
              {'key': 'version', 'value': '1', 'type': 'string', 'flag': 2},
            ])
          : _ok(null),
    );
    final api = AdminApi(c);
    final items = await api.listSettings([1, 4]);
    expect(adapter.requests.first.queryParameters['groups'], '1,4');
    expect(items.last.readOnly, isTrue);
    items.first.value = 'B';
    await api.saveSettings([items.first]);
    final body = adapter.requests.last.data as List;
    expect((body.single as Map)['value'], 'B');
  });

  test('settings defaults and deletion use their admin endpoints', () async {
    final (c, adapter) = _client(
      (o) => o.path.endsWith('/default')
          ? _ok([
              {'key': 'site_title', 'value': 'Default', 'group': 1},
            ])
          : _ok(null),
    );
    final api = AdminApi(c);
    final defaults = await api.defaultSettings(1);
    expect(defaults.single.key, 'site_title');
    expect(defaults.single.value, 'Default');
    expect(adapter.requests.single.path, '/api/admin/setting/default');
    expect(adapter.requests.single.method, 'POST');
    expect(adapter.requests.single.queryParameters['group'], 1);

    await api.deleteSetting('site_title');
    expect(adapter.requests.last.path, '/api/admin/setting/delete');
    expect(adapter.requests.last.queryParameters['key'], 'site_title');
  });

  test(
    'offline tool settings use the runtime initialization endpoint',
    () async {
      final (c, adapter) = _client((_) => _ok('aria2 version: 1.37'));
      final config = offlineDownloadToolConfigs.singleWhere(
        (item) => item.endpoint == 'set_aria2',
      );
      final status = await AdminApi(c).configureOfflineDownload(config, {
        'aria2_uri': 'http://aria2:6800/jsonrpc',
        'aria2_secret': 'secret',
      });
      expect(status, 'aria2 version: 1.37');
      final req = adapter.requests.single;
      expect(req.path, '/api/admin/setting/set_aria2');
      expect(req.data, {
        'uri': 'http://aria2:6800/jsonrpc',
        'secret': 'secret',
      });
    },
  );

  test('offline tool settings preserve core errors', () async {
    final (c, _) = _client(
      (_) => {'code': 400, 'message': 'unsupported storage driver'},
    );
    final config = offlineDownloadToolConfigs.singleWhere(
      (item) => item.endpoint == 'set_115',
    );
    expect(
      () =>
          AdminApi(c).configureOfflineDownload(config, {'115_temp_dir': '/x'}),
      throwsA(
        isA<ApiException>()
            .having((e) => e.code, 'code', 400)
            .having((e) => e.message, 'message', 'unsupported storage driver'),
      ),
    );
  });

  test('offline tool settings cover every core runtime endpoint', () {
    expect(
      offlineDownloadToolConfigs.map((config) => config.endpoint).toList(),
      [
        'set_aria2',
        'set_qbit',
        'set_transmission',
        'set_115',
        'set_115_open',
        'set_123_pan',
        'set_123_open',
        'set_pikpak',
        'set_thunder',
        'set_thunderx',
        'set_thunder_browser',
        'set_guangyapan',
      ],
    );
  });

  test('reset token returns the new token', () async {
    final (c, adapter) = _client((_) => _ok('new-token'));
    final token = await AdminApi(c).resetToken();
    expect(token, 'new-token');
    expect(adapter.requests.single.path, '/api/admin/setting/reset_token');
  });

  test('meta and share administration use the core routes', () async {
    final (c, adapter) = _client((o) {
      if (o.path.endsWith('/list')) {
        return _ok({
          'content': [
            if (o.path.contains('/meta/')) {'id': 2, 'path': '/docs'},
            if (o.path == '/api/share/list')
              {
                'id': 'docs',
                'files': ['/docs'],
              },
          ],
          'total': 1,
        });
      }
      if (o.path == '/api/share/get') {
        return _ok({
          'id': 'docs',
          'files': ['/docs'],
        });
      }
      return _ok(null);
    });
    final api = AdminApi(c);
    expect((await api.listMetas()).single['path'], '/docs');
    await api.saveMeta({'path': '/docs'}, create: true);
    await api.deleteMeta(2);
    expect((await api.listShares()).single['id'], 'docs');
    expect((await api.getShare('docs'))['files'], ['/docs']);
    await api.saveShare({'id': 'docs'}, create: false);
    await api.setShareEnabled('docs', enabled: false);
    await api.deleteShare('docs');

    expect(adapter.requests.map((request) => request.path), [
      '/api/admin/meta/list',
      '/api/admin/meta/create',
      '/api/admin/meta/delete',
      '/api/share/list',
      '/api/share/get',
      '/api/share/update',
      '/api/share/disable',
      '/api/share/delete',
    ]);
    expect(adapter.requests[2].queryParameters['id'], 2);
    expect(adapter.requests[6].queryParameters['id'], 'docs');
  });

  test(
    'index and manual scan administration send core request shapes',
    () async {
      final (c, adapter) = _client((_) => _ok({'is_done': true}));
      final api = AdminApi(c);
      await api.indexProgress();
      await api.buildIndex();
      await api.updateIndex(paths: ['/docs'], maxDepth: 4);
      await api.stopIndex();
      await api.clearIndex();
      await api.manualScanProgress();
      await api.startManualScan(path: '/docs', limit: 2.5);
      await api.stopManualScan();

      expect(adapter.requests.map((request) => request.path), [
        '/api/admin/index/progress',
        '/api/admin/index/build',
        '/api/admin/index/update',
        '/api/admin/index/stop',
        '/api/admin/index/clear',
        '/api/admin/scan/progress',
        '/api/admin/scan/start',
        '/api/admin/scan/stop',
      ]);
      expect(adapter.requests[2].data, {
        'paths': ['/docs'],
        'max_depth': 4,
      });
      expect(adapter.requests[6].data, {'path': '/docs', 'limit': 2.5});
    },
  );

  test(
    'media administration sends configured type and scan path fields',
    () async {
      final (c, adapter) = _client((o) {
        if (o.path.endsWith('/items')) {
          return _ok({'content': [], 'total': 0});
        }
        if (o.path.endsWith('/scan_paths/create')) return _ok({'id': 5});
        if (o.path.endsWith('/scan_paths') || o.path.endsWith('/config/list')) {
          return _ok([]);
        }
        return _ok({'running': false});
      });
      final api = AdminApi(c);
      await api.listMediaConfigs();
      await api.saveMediaConfig({'media_type': 'video', 'enabled': true});
      await api.listMediaScanPaths(mediaType: 'video');
      await api.createMediaScanPath({'media_type': 'video', 'path': '/movies'});
      await api.updateMediaScanPath({'id': 5, 'path': '/films'});
      await api.deleteMediaScanPath(5);
      await api.clearMediaScanPath(5);
      await api.listAdminMediaItems(mediaType: 'video', scanPathId: 5);
      await api.updateAdminMediaItem({'id': 7, 'hidden': true});
      await api.deleteAdminMediaItem(7);
      await api.startMediaScan('video', scanPathId: 5);
      await api.mediaScanProgress('video');
      await api.startMediaScrape('video', itemId: 7);
      await api.clearMedia('video');
      await api.clearMediaScrape(mediaType: 'video');
      await api.deleteInvalidMedia(mediaType: 'video');

      expect(adapter.requests[1].data, {
        'media_type': 'video',
        'enabled': true,
      });
      expect(adapter.requests[3].data['path'], '/movies');
      expect(adapter.requests[7].queryParameters['scan_path_id'], 5);
      expect(adapter.requests[10].data, {
        'media_type': 'video',
        'scan_path_id': 5,
      });
      expect(adapter.requests[12].data, {'media_type': 'video', 'item_id': 7});
      expect(adapter.requests.last.path, '/api/admin/media/delete_invalid');
    },
  );

  test(
    'media administration supports export, import, STRM, and app keys',
    () async {
      final (c, adapter) = _client((o) {
        if (o.path.endsWith('/export')) {
          return {'version': 1, 'scope': 'media_type', 'items': []};
        }
        if (o.path.endsWith('/appkey/list')) {
          return _ok([
            {'id': 4, 'name': 'player', 'prefix': 'ol_'},
          ]);
        }
        if (o.path.endsWith('/appkey/create')) {
          return _ok({'id': 5, 'name': 'mobile', 'key': 'secret'});
        }
        return _ok({'written': 2, 'path': '/strm'});
      });
      final api = AdminApi(c);
      final exported = await api.exportMedia(mediaType: 'video');
      await api.importMedia({'version': 1, 'items': []}, scanPathId: 3);
      await api.generateMediaStrm(mediaType: 'video', scanPathId: 3);
      final keys = await api.listMediaAppKeys();
      await api.createMediaAppKey('mobile');
      await api.deleteMediaAppKey(4);

      expect(exported['scope'], 'media_type');
      expect(keys.single['prefix'], 'ol_');
      expect(adapter.requests.map((request) => request.path), [
        '/api/admin/media/export',
        '/api/admin/media/import',
        '/api/admin/media/strm/generate',
        '/api/admin/media/appkey/list',
        '/api/admin/media/appkey/create',
        '/api/admin/media/appkey/delete',
      ]);
      expect(adapter.requests[0].queryParameters, {'media_type': 'video'});
      expect(adapter.requests[1].queryParameters, {'scan_path_id': 3});
      expect(adapter.requests[2].data, {
        'media_type': 'video',
        'scan_path_id': 3,
      });
      expect(adapter.requests[4].data, {'name': 'mobile'});
      expect(adapter.requests[5].queryParameters, {'id': 4});
    },
  );

  test('media export raises envelope errors returned as bytes', () async {
    final (c, _) = _client((_) => {'code': 404, 'message': 'missing'});
    expect(
      () => AdminApi(c).exportMedia(),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 404)),
    );
  });

  test('transcode administration lists workers and cancels a job', () async {
    final (c, adapter) = _client(
      (o) => o.path.endsWith('/workers')
          ? _ok([
              {'id': 'w1', 'callback_token': 'private-token'},
            ])
          : o.path.endsWith('/jobs')
          ? _ok([
              {'id': 'j1', 'source_url': 'signed-secret'},
            ])
          : _ok(null),
    );
    final api = AdminApi(c);
    final workers = await api.listTranscodeWorkers();
    final jobs = await api.listTranscodeJobs();
    await api.cancelTranscodeJob('j1');

    expect(workers.single['id'], 'w1');
    expect(jobs.single['id'], 'j1');
    expect(adapter.requests.map((request) => request.path), [
      '/api/admin/transcode/workers',
      '/api/admin/transcode/jobs',
      '/api/admin/transcode/cancel',
    ]);
    expect(adapter.requests.last.data, {'job_id': 'j1'});
  });

  test('driver alert splits level and text', () {
    final info = DriverInfo.fromJson({
      'common': [],
      'additional': [],
      'config': {'alert': 'warning|Be careful|really', 'no_upload': true},
    });
    expect(info.alertLevel, 'warning');
    expect(info.alertText, 'Be careful|really');
    expect(info.noUpload, isTrue);
    expect(DriverInfo.fromJson({}).alertText, '');
  });
}
