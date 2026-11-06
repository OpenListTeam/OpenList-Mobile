import 'dart:convert';

import 'package:dio/dio.dart';

import 'models.dart';
import 'openlist_client.dart';

class OfflineDownloadToolConfig {
  const OfflineDownloadToolConfig({
    required this.name,
    required this.endpoint,
    required this.fields,
  });

  final String name;
  final String endpoint;
  final Map<String, String> fields;

  Map<String, String> requestBody(Map<String, String> values) => {
        for (final entry in fields.entries)
          entry.value: values[entry.key] ?? '',
      };
}

const offlineDownloadToolConfigs = <OfflineDownloadToolConfig>[
  OfflineDownloadToolConfig(
    name: 'Aria2',
    endpoint: 'set_aria2',
    fields: {'aria2_uri': 'uri', 'aria2_secret': 'secret'},
  ),
  OfflineDownloadToolConfig(
    name: 'qBittorrent',
    endpoint: 'set_qbit',
    fields: {
      'qbittorrent_url': 'url',
      'qbittorrent_seedtime': 'seedtime',
    },
  ),
  OfflineDownloadToolConfig(
    name: 'Transmission',
    endpoint: 'set_transmission',
    fields: {
      'transmission_uri': 'uri',
      'transmission_seedtime': 'seedtime',
    },
  ),
  OfflineDownloadToolConfig(
    name: '115',
    endpoint: 'set_115',
    fields: {'115_temp_dir': 'temp_dir'},
  ),
  OfflineDownloadToolConfig(
    name: '115 Open',
    endpoint: 'set_115_open',
    fields: {'115_open_temp_dir': 'temp_dir'},
  ),
  OfflineDownloadToolConfig(
    name: '123 Pan',
    endpoint: 'set_123_pan',
    fields: {'123_temp_dir': 'temp_dir'},
  ),
  OfflineDownloadToolConfig(
    name: '123 Open',
    endpoint: 'set_123_open',
    fields: {
      '123_open_temp_dir': 'temp_dir',
      '123_open_callback_url': 'callback_url',
    },
  ),
  OfflineDownloadToolConfig(
    name: 'PikPak',
    endpoint: 'set_pikpak',
    fields: {'pikpak_temp_dir': 'temp_dir'},
  ),
  OfflineDownloadToolConfig(
    name: 'Thunder',
    endpoint: 'set_thunder',
    fields: {'thunder_temp_dir': 'temp_dir'},
  ),
  OfflineDownloadToolConfig(
    name: 'ThunderX',
    endpoint: 'set_thunderx',
    fields: {'thunderx_temp_dir': 'temp_dir'},
  ),
  OfflineDownloadToolConfig(
    name: 'Thunder Browser',
    endpoint: 'set_thunder_browser',
    fields: {'thunder_browser_temp_dir': 'temp_dir'},
  ),
  OfflineDownloadToolConfig(
    name: 'GuangYaPan',
    endpoint: 'set_guangyapan',
    fields: {'guangyapan_temp_dir': 'temp_dir'},
  ),
];

/// Admin endpoints (`/api/admin`, admin only).
class AdminApi {
  AdminApi(this.client);

  final OpenListClient client;

  Future<List<Storage>> listStorages() async {
    final data = await client
        .get('/api/admin/storage/list', query: {'page': 1, 'per_page': 0});
    final content = (data is Map ? data['content'] as List? : null) ?? const [];
    return content
        .map((e) => Storage.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Storage> getStorage(int id) async {
    final data = await client.get('/api/admin/storage/get', query: {'id': id});
    return Storage.fromJson(Map<String, dynamic>.from(data ?? {}));
  }

  /// Returns the id of the new storage.
  Future<int> createStorage(Map<String, dynamic> storage) async {
    final data = await client.post('/api/admin/storage/create', body: storage);
    final id = data is Map ? data['id'] : null;
    return id is num ? id.toInt() : 0;
  }

  Future<void> updateStorage(Map<String, dynamic> storage) =>
      client.post('/api/admin/storage/update', body: storage);

  Future<void> deleteStorage(int id) =>
      client.post('/api/admin/storage/delete', query: {'id': id});

  Future<void> enableStorage(int id) =>
      client.post('/api/admin/storage/enable', query: {'id': id});

  Future<void> disableStorage(int id) =>
      client.post('/api/admin/storage/disable', query: {'id': id});

  Future<void> reloadAllStorages() =>
      client.post('/api/admin/storage/load_all');

  Future<List<String>> driverNames() async {
    final data = await client.get('/api/admin/driver/names');
    return ((data as List?) ?? const []).map((e) => '$e').toList();
  }

  Future<DriverInfo> driverInfo(String driver) async {
    final data =
        await client.get('/api/admin/driver/info', query: {'driver': driver});
    return DriverInfo.fromJson(Map<String, dynamic>.from(data ?? {}));
  }

  Future<List<AdminUser>> listUsers() async {
    final data = await client
        .get('/api/admin/user/list', query: {'page': 1, 'per_page': 0});
    final content = (data is Map ? data['content'] as List? : null) ?? const [];
    return content
        .map((e) => AdminUser.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// An empty `password` keeps the current one on update.
  Future<void> createUser(Map<String, dynamic> user) =>
      client.post('/api/admin/user/create', body: user);

  Future<void> updateUser(Map<String, dynamic> user) =>
      client.post('/api/admin/user/update', body: user);

  Future<void> deleteUser(int id) =>
      client.post('/api/admin/user/delete', query: {'id': id});

  Future<void> cancelUser2fa(int id) =>
      client.post('/api/admin/user/cancel_2fa', query: {'id': id});

  /// Settings of the given groups (`internal/model/setting.go` constants).
  Future<List<SettingItem>> listSettings(List<int> groups) async {
    final data = await client
        .get('/api/admin/setting/list', query: {'groups': groups.join(',')});
    return ((data as List?) ?? const [])
        .map((e) => SettingItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> saveSettings(List<SettingItem> items) =>
      client.post('/api/admin/setting/save',
          body: items.map((e) => e.toJson()).toList());

  Future<List<SettingItem>> defaultSettings(int group) async {
    final data = await client
        .post('/api/admin/setting/default', query: {'group': group});
    return ((data as List?) ?? const [])
        .map((e) => SettingItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> deleteSetting(String key) =>
      client.post('/api/admin/setting/delete', query: {'key': key});

  Future<List<Map<String, dynamic>>> listMetas() async {
    final data = await client
        .get('/api/admin/meta/list', query: {'page': 1, 'per_page': 0});
    final content = (data is Map ? data['content'] as List? : null) ?? const [];
    return content
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<Map<String, dynamic>> getMeta(int id) async {
    final data = await client.get('/api/admin/meta/get', query: {'id': id});
    return Map<String, dynamic>.from(data as Map);
  }

  Future<void> saveMeta(Map<String, dynamic> meta, {required bool create}) =>
      client.post('/api/admin/meta/${create ? 'create' : 'update'}',
          body: meta);

  Future<void> deleteMeta(int id) =>
      client.post('/api/admin/meta/delete', query: {'id': id});

  Future<List<Map<String, dynamic>>> listShares() async {
    final data =
        await client.get('/api/share/list', query: {'page': 1, 'per_page': 0});
    final content = (data is Map ? data['content'] as List? : null) ?? const [];
    return content
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<Map<String, dynamic>> getShare(String id) async {
    final data = await client.get('/api/share/get', query: {'id': id});
    return Map<String, dynamic>.from(data as Map);
  }

  Future<void> saveShare(Map<String, dynamic> share, {required bool create}) =>
      client.post('/api/share/${create ? 'create' : 'update'}', body: share);

  Future<void> deleteShare(String id) =>
      client.post('/api/share/delete', query: {'id': id});

  Future<void> setShareEnabled(String id, {required bool enabled}) => client
      .post('/api/share/${enabled ? 'enable' : 'disable'}', query: {'id': id});

  Future<Map<String, dynamic>> indexProgress() async {
    final data = await client.get('/api/admin/index/progress');
    return Map<String, dynamic>.from(data as Map);
  }

  Future<void> buildIndex() => client.post('/api/admin/index/build');

  Future<void> updateIndex(
          {List<String> paths = const [], int maxDepth = -1}) =>
      client.post('/api/admin/index/update',
          body: {'paths': paths, 'max_depth': maxDepth});

  Future<void> stopIndex() => client.post('/api/admin/index/stop');

  Future<void> clearIndex() => client.post('/api/admin/index/clear');

  Future<Map<String, dynamic>> manualScanProgress() async {
    final data = await client.get('/api/admin/scan/progress');
    return Map<String, dynamic>.from(data as Map);
  }

  Future<void> startManualScan({required String path, required double limit}) =>
      client
          .post('/api/admin/scan/start', body: {'path': path, 'limit': limit});

  Future<void> stopManualScan() => client.post('/api/admin/scan/stop');

  Future<List<Map<String, dynamic>>> listMediaConfigs() async {
    final data = await client.get('/api/admin/media/config/list');
    return ((data as List?) ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<void> saveMediaConfig(Map<String, dynamic> config) =>
      client.post('/api/admin/media/config/save', body: config);

  Future<List<Map<String, dynamic>>> listMediaScanPaths(
      {String? mediaType}) async {
    final data = await client.get('/api/admin/media/scan_paths',
        query: mediaType == null ? null : {'media_type': mediaType});
    return ((data as List?) ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<Map<String, dynamic>> createMediaScanPath(
          Map<String, dynamic> scanPath) async =>
      Map<String, dynamic>.from(await client
          .post('/api/admin/media/scan_paths/create', body: scanPath) as Map);

  Future<void> updateMediaScanPath(Map<String, dynamic> scanPath) =>
      client.post('/api/admin/media/scan_paths/update', body: scanPath);

  Future<void> deleteMediaScanPath(int id) =>
      client.post('/api/admin/media/scan_paths/delete', query: {'id': id});

  Future<void> clearMediaScanPath(int id) =>
      client.post('/api/admin/media/scan_paths/clear', query: {'id': id});

  Future<void> startMediaScan(String mediaType, {int scanPathId = 0}) =>
      client.post('/api/admin/media/scan/start',
          body: {'media_type': mediaType, 'scan_path_id': scanPathId});

  Future<Map<String, dynamic>> mediaScanProgress(String mediaType) async =>
      Map<String, dynamic>.from(await client.get(
          '/api/admin/media/scan/progress',
          query: {'media_type': mediaType}) as Map);

  Future<Map<String, dynamic>> listAdminMediaItems({
    required String mediaType,
    int page = 1,
    int pageSize = 30,
    int? scanPathId,
  }) async {
    final data = await client.get('/api/admin/media/items', query: {
      'media_type': mediaType,
      'page': page,
      'page_size': pageSize,
      if (scanPathId != null) 'scan_path_id': scanPathId,
    });
    return Map<String, dynamic>.from(data as Map);
  }

  Future<void> updateAdminMediaItem(Map<String, dynamic> item) =>
      client.post('/api/admin/media/items/update', body: item);

  Future<void> deleteAdminMediaItem(int id) =>
      client.post('/api/admin/media/items/delete', query: {'id': id});

  Future<Map<String, dynamic>> exportMedia({
    String? mediaType,
    int? scanPathId,
  }) async {
    final response = await client.dio.get<List<int>>(
      '/api/admin/media/export',
      queryParameters: {
        if (mediaType != null) 'media_type': mediaType,
        if (scanPathId != null) 'scan_path_id': scanPathId,
      },
      options: Options(responseType: ResponseType.bytes),
    );
    final raw = response.data;
    final decoded = raw is List<int> ? jsonDecode(utf8.decode(raw)) : raw;
    final body = OpenListClient.unwrap(response.statusCode ?? 0, decoded);
    if (body is! Map) {
      throw const FormatException(
          'The core returned invalid media export data');
    }
    return Map<String, dynamic>.from(body);
  }

  Future<Map<String, dynamic>> importMedia(Map<String, dynamic> data,
          {int? scanPathId}) async =>
      Map<String, dynamic>.from(await client.post('/api/admin/media/import',
              body: data,
              query: scanPathId == null ? null : {'scan_path_id': scanPathId})
          as Map);

  Future<Map<String, dynamic>> generateMediaStrm(
          {String? mediaType, int scanPathId = 0}) async =>
      Map<String, dynamic>.from(await client.post(
              '/api/admin/media/strm/generate',
              body: {'media_type': mediaType ?? '', 'scan_path_id': scanPathId})
          as Map);

  Future<List<Map<String, dynamic>>> listMediaAppKeys() async {
    final data = await client.get('/api/admin/media/appkey/list');
    return ((data as List?) ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<Map<String, dynamic>> createMediaAppKey(String name) async =>
      Map<String, dynamic>.from(await client
          .post('/api/admin/media/appkey/create', body: {'name': name}) as Map);

  Future<void> deleteMediaAppKey(int id) =>
      client.post('/api/admin/media/appkey/delete', query: {'id': id});

  Future<void> startMediaScrape(String mediaType, {int itemId = 0}) =>
      client.post('/api/admin/media/scrape/start',
          body: {'media_type': mediaType, 'item_id': itemId});

  Future<void> clearMedia(String mediaType) =>
      client.post('/api/admin/media/clear', query: {'media_type': mediaType});

  Future<void> clearMediaScrape({String? mediaType}) =>
      client.post('/api/admin/media/clear_scrape',
          query: mediaType == null ? null : {'media_type': mediaType});

  Future<void> deleteInvalidMedia({String? mediaType}) =>
      client.post('/api/admin/media/delete_invalid',
          query: mediaType == null ? null : {'media_type': mediaType});

  Future<List<Map<String, dynamic>>> listTranscodeWorkers() async {
    final data = await client.get('/api/admin/transcode/workers');
    return ((data as List?) ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> listTranscodeJobs() async {
    final data = await client.get('/api/admin/transcode/jobs');
    return ((data as List?) ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<void> cancelTranscodeJob(String jobId) =>
      client.post('/api/admin/transcode/cancel', body: {'job_id': jobId});

  Future<String> configureOfflineDownload(
    OfflineDownloadToolConfig config,
    Map<String, String> values,
  ) async {
    final data = await client.post(
      '/api/admin/setting/${config.endpoint}',
      body: config.requestBody(values),
    );
    if (data is! String) {
      throw const FormatException('The core returned an invalid tool status');
    }
    return data;
  }

  Future<String> resetToken() async {
    final data = await client.post('/api/admin/setting/reset_token');
    if (data is! String || data.isEmpty) {
      throw const FormatException('The core returned an invalid API token');
    }
    return data;
  }
}
