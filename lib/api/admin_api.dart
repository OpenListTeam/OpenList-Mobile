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
