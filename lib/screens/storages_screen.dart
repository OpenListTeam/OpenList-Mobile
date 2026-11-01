import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:openlist_mobile/api/models.dart';
import 'package:openlist_mobile/api/session.dart';
import 'package:openlist_mobile/design/theme.dart';
import 'package:openlist_mobile/generated/l10n.dart';
import 'package:openlist_mobile/pages/native/storage_edit_page.dart';
import 'package:openlist_mobile/widgets/cards.dart';

/// Storages management screen
class StoragesScreen extends StatefulWidget {
  const StoragesScreen({super.key});

  @override
  State<StoragesScreen> createState() => _StoragesScreenState();
}

class _StoragesScreenState extends State<StoragesScreen> {
  final _session = OpenListSession.instance;
  final _storages = <Storage>[].obs;
  final _isLoading = false.obs;
  final _error = ''.obs;

  @override
  void initState() {
    super.initState();
    _loadStorages();
  }

  Future<void> _loadStorages() async {
    if (!_session.isConnected) {
      _error.value = 'Not connected to server';
      return;
    }

    _isLoading.value = true;
    _error.value = '';

    try {
      final storages = await _session.admin.listStorages();
      _storages.value = storages;
    } catch (e) {
      _error.value = e.toString();
    } finally {
      _isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.current.storages),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStorages,
          ),
        ],
      ),
      body: Obx(() {
        if (_isLoading.value && _storages.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_error.value.isNotEmpty) {
          return _ErrorView(
            message: _error.value,
            onRetry: _loadStorages,
          );
        }

        if (_storages.isEmpty) {
          return _EmptyView(onAddStorage: _showAddStorageDialog);
        }

        return RefreshIndicator(
          onRefresh: _loadStorages,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: AppDesign.space16),
            itemCount: _storages.length,
            itemBuilder: (context, index) {
              final storage = _storages[index];
              return StorageCard(
                name: storage.mountPath,
                type: storage.driver,
                status: storage.status,
                usedBytes: 0, // TODO: Get actual usage
                totalBytes: 0, // TODO: Get actual total
                onTap: () => _showStorageDetails(storage),
              );
            },
          ),
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddStorageDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddStorageDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const StorageEditPage(),
      ),
    ).then((_) => _loadStorages());
  }

  void _showStorageDetails(Storage storage) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _StorageDetailsSheet(
        storage: storage,
        onDelete: () async {
          Navigator.pop(context);
          await _deleteStorage(storage);
        },
        onEdit: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StorageEditPage(storage: storage),
            ),
          ).then((_) => _loadStorages());
        },
        onToggle: () async {
          Navigator.pop(context);
          await _toggleStorage(storage);
        },
      ),
    );
  }

  Future<void> _deleteStorage(Storage storage) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete Storage'),
        content: Text('Delete storage "${storage.mountPath}"?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _session.admin.deleteStorage(storage.id);
      await _loadStorages();
      Get.snackbar('Success', 'Storage deleted');
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete storage: $e');
    }
  }

  Future<void> _toggleStorage(Storage storage) async {
    try {
      if (storage.disabled) {
        await _session.admin.enableStorage(storage.id);
      } else {
        await _session.admin.disableStorage(storage.id);
      }
      await _loadStorages();
      Get.snackbar('Success', storage.disabled ? 'Storage enabled' : 'Storage disabled');
    } catch (e) {
      Get.snackbar('Error', 'Failed to toggle storage: $e');
    }
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDesign.space32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: AppDesign.space24),
            Text(
              'Failed to load storages',
              style: AppDesign.headline3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDesign.space12),
            Text(
              message,
              style: AppDesign.body2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDesign.space24),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onAddStorage});

  final VoidCallback onAddStorage;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDesign.space32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.storage,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: AppDesign.space24),
            Text(
              'No storages configured',
              style: AppDesign.headline3,
            ),
            const SizedBox(height: AppDesign.space12),
            Text(
              'Add a storage to get started',
              style: AppDesign.body2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDesign.space24),
            ElevatedButton.icon(
              onPressed: onAddStorage,
              icon: const Icon(Icons.add),
              label: const Text('Add Storage'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StorageDetailsSheet extends StatelessWidget {
  const _StorageDetailsSheet({
    required this.storage,
    required this.onDelete,
    required this.onEdit,
    required this.onToggle,
  });

  final Storage storage;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isConnected = storage.status == 'work';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppDesign.space24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDesign.space24),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: (isConnected ? AppDesign.primaryBlue : Colors.grey)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDesign.radiusSmall),
                  ),
                  child: Icon(
                    Icons.storage,
                    color: isConnected ? AppDesign.primaryBlue : Colors.grey,
                  ),
                ),
                const SizedBox(width: AppDesign.space16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        storage.mountPath,
                        style: AppDesign.headline3.copyWith(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: AppDesign.space4),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isConnected
                                  ? AppDesign.successGreen
                                  : AppDesign.errorRed,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: AppDesign.space8),
                          Text(
                            isConnected ? 'Connected' : 'Disconnected',
                            style: AppDesign.body2.copyWith(
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDesign.space24),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Driver'),
            trailing: Text(
              storage.driver,
              style: AppDesign.body1.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          if (storage.remark.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.note),
              title: const Text('Remark'),
              subtitle: Text(storage.remark),
            ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.folder_open),
            title: const Text('Browse Files'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to files screen filtered by this storage
              Get.snackbar('Info', 'Browse functionality coming soon');
            },
          ),
          ListTile(
            leading: Icon(
              storage.disabled ? Icons.toggle_off : Icons.toggle_on,
              color: storage.disabled ? Colors.grey : AppDesign.successGreen,
            ),
            title: Text(storage.disabled ? 'Enable Storage' : 'Disable Storage'),
            onTap: onToggle,
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Storage'),
            onTap: onEdit,
          ),
          ListTile(
            leading: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
            title: Text(
              'Delete Storage',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}
