import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/storage.dart';
import '../../services/storage_api_service.dart';
import '../../services/auth_manager.dart';
import '../../pages/auth/login_page.dart';
import 'storage_detail_page.dart';

class StorageManagementPage extends StatefulWidget {
  const StorageManagementPage({Key? key}) : super(key: key);

  @override
  State<StorageManagementPage> createState() => _StorageManagementPageState();
}

class _StorageManagementPageState extends State<StorageManagementPage> {
  final StorageController _controller = Get.put(StorageController());

  @override
  void initState() {
    super.initState();
    _controller.loadStorages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('存储管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.loadStorages(),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddStorageDialog(),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('退出登录'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Obx(() {
        if (_controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_controller.storages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.storage_outlined,
                  size: 80,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  '未配置存储',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _showAddStorageDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('添加存储'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => _controller.loadStorages(),
          child: ListView.builder(
            itemCount: _controller.storages.length,
            itemBuilder: (context, index) {
              final storage = _controller.storages[index];
              return _buildStorageCard(storage);
            },
          ),
        );
      }),
    );
  }

  Widget _buildStorageCard(Storage storage) {
    final isEnabled = !storage.disabled;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isEnabled ? Colors.green : Colors.grey,
          child: Icon(
            _getDriverIcon(storage.driver),
            color: Colors.white,
          ),
        ),
        title: Text(
          storage.mountPath,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isEnabled ? null : Colors.grey,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('驱动: ${storage.driver}'),
            if (storage.remark.isNotEmpty)
              Text('备注: ${storage.remark}'),
            Text(
              '状态: ${isEnabled ? '已启用' : '已禁用'}',
              style: TextStyle(
                color: isEnabled ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value, storage),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  const Icon(Icons.edit),
                  const SizedBox(width: 8),
                  const Text('编辑'),
                ],
              ),
            ),
            PopupMenuItem(
              value: isEnabled ? 'disable' : 'enable',
              child: Row(
                children: [
                  Icon(isEnabled ? Icons.pause : Icons.play_arrow),
                  const SizedBox(width: 8),
                  Text(isEnabled ? '禁用' : '启用'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  const Icon(Icons.delete, color: Colors.red),
                  const SizedBox(width: 8),
                  const Text(
                    '删除',
                    style: TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _showStorageDetail(storage),
      ),
    );
  }

  IconData _getDriverIcon(String driver) {
    switch (driver.toLowerCase()) {
      case 'local':
        return Icons.folder;
      case 'aliyundrive':
      case 'aliyundrive_open':
        return Icons.cloud;
      case 'onedrive':
        return Icons.cloud_outlined;
      case 'googledrive':
        return Icons.cloud_queue;
      case 'dropbox':
        return Icons.cloud_download;
      case 'ftp':
      case 'sftp':
        return Icons.folder_shared;
      case 'webdav':
        return Icons.web;
      default:
        return Icons.storage;
    }
  }

  void _handleMenuAction(String action, Storage storage) {
    switch (action) {
      case 'edit':
        _showEditStorageDialog(storage);
        break;
      case 'enable':
        _controller.enableStorage(storage.id!);
        break;
      case 'disable':
        _controller.disableStorage(storage.id!);
        break;
      case 'delete':
        _showDeleteConfirmDialog(storage);
        break;
    }
  }

  void _showStorageDetail(Storage storage) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StorageDetailPage(storage: storage),
      ),
    );
  }

  void _showAddStorageDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const StorageDetailPage(),
      ),
    ).then((_) => _controller.loadStorages());
  }

  void _showEditStorageDialog(Storage storage) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StorageDetailPage(storage: storage),
      ),
    ).then((_) => _controller.loadStorages());
  }

  void _showDeleteConfirmDialog(Storage storage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text(
          '确定要删除存储 "${storage.mountPath}" 吗？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _controller.deleteStorage(storage.id!);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认退出'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await AuthManager.instance.logout();
              Get.snackbar(
                '已退出',
                '已安全退出登录',
                backgroundColor: Colors.green,
                colorText: Colors.white,
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('退出'),
          ),
        ],
      ),
    );
  }
}

class StorageController extends GetxController {
  final RxList<Storage> storages = <Storage>[].obs;
  final RxBool isLoading = false.obs;

  Future<void> loadStorages() async {
    isLoading.value = true;
    try {
      final response = await StorageApiService.getStorages();
      if (response.isSuccess && response.data != null) {
        storages.value = response.data!.content;
      } else {
        _showError(response.message);
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> enableStorage(int id) async {
    try {
      final response = await StorageApiService.enableStorage(id);
      if (response.isSuccess) {
        _showSuccess('存储已启用');
        loadStorages();
      } else {
        _showError(response.message);
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> disableStorage(int id) async {
    try {
      final response = await StorageApiService.disableStorage(id);
      if (response.isSuccess) {
        _showSuccess('存储已禁用');
        loadStorages();
      } else {
        _showError(response.message);
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> deleteStorage(int id) async {
    try {
      final response = await StorageApiService.deleteStorage(id);
      if (response.isSuccess) {
        _showSuccess('存储已删除');
        loadStorages();
      } else {
        _showError(response.message);
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showSuccess(String message) {
    Get.snackbar(
      '成功',
      message,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _showError(String message) {
    Get.snackbar(
      '错误',
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
