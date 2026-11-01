import 'models.dart';
import 'openlist_client.dart';

/// Admin endpoints for storages and drivers (`/api/admin`, admin only).
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
}
