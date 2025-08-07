import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/storage.dart';
import '../../services/storage_api_service.dart';

class StorageDetailPage extends StatefulWidget {
  final Storage? storage;

  const StorageDetailPage({Key? key, this.storage}) : super(key: key);

  @override
  State<StorageDetailPage> createState() => _StorageDetailPageState();
}

class _StorageDetailPageState extends State<StorageDetailPage> {
  final _formKey = GlobalKey<FormState>();
  final _mountPathController = TextEditingController();
  final _remarkController = TextEditingController();
  final _orderController = TextEditingController();
  final _cacheExpirationController = TextEditingController();
  final _additionController = TextEditingController();
  
  String _selectedDriver = 'local';
  bool _disabled = false;
  bool _disableIndex = false;
  bool _enableSign = false;
  bool _webProxy = false;
  bool _proxyRange = false;

  final List<String> _drivers = [
    'local',
    'aliyundrive',
    'aliyundrive_open',
    'onedrive',
    'googledrive',
    'dropbox',
    'webdav',
    'ftp',
    'sftp',
    '123',
    'baidu_netdisk',
  ];

  bool get _isEditing => widget.storage != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadStorageData();
    } else {
      _setDefaultValues();
    }
  }

  void _loadStorageData() {
    final storage = widget.storage!;
    _mountPathController.text = storage.mountPath;
    _remarkController.text = storage.remark;
    _orderController.text = storage.order.toString();
    _cacheExpirationController.text = storage.cacheExpiration.toString();
    _additionController.text = storage.addition;
    _selectedDriver = storage.driver;
    _disabled = storage.disabled;
    _disableIndex = storage.disableIndex;
    _enableSign = storage.enableSign;
    _webProxy = storage.webProxy;
    _proxyRange = storage.proxyRange;
  }

  void _setDefaultValues() {
    _orderController.text = '0';
    _cacheExpirationController.text = '30';
  }

  @override
  void dispose() {
    _mountPathController.dispose();
    _remarkController.dispose();
    _orderController.dispose();
    _cacheExpirationController.dispose();
    _additionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '编辑存储' : '添加存储'),
        actions: [
          TextButton(
            onPressed: _saveStorage,
            child: Text(
              '保存',
              style: TextStyle(color: Theme.of(context).primaryColor),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildBasicSection(),
            const SizedBox(height: 24),
            _buildAdvancedSection(),
            const SizedBox(height: 24),
            _buildDriverSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '基本设置',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _mountPathController,
              decoration: const InputDecoration(
                labelText: '挂载路径',
                hintText: '例如: /',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入挂载路径';
                }
                if (!value.startsWith('/')) {
                  return '挂载路径必须以 / 开头';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedDriver,
              decoration: const InputDecoration(
                labelText: '驱动类型',
                border: OutlineInputBorder(),
              ),
              items: _drivers.map((driver) {
                return DropdownMenuItem(
                  value: driver,
                  child: Text(_getDriverDisplayName(driver)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDriver = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _remarkController,
              decoration: const InputDecoration(
                labelText: '备注',
                hintText: '可选的存储描述',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _orderController,
                    decoration: const InputDecoration(
                      labelText: '排序',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '请输入排序值';
                      }
                      if (int.tryParse(value) == null) {
                        return '请输入有效的数字';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _cacheExpirationController,
                    decoration: const InputDecoration(
                      labelText: '缓存过期时间(分钟)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '请输入缓存过期时间';
                      }
                      if (int.tryParse(value) == null) {
                        return '请输入有效的数字';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '高级设置',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('禁用存储'),
              subtitle: const Text('禁用后将无法访问此存储'),
              value: _disabled,
              onChanged: (value) {
                setState(() {
                  _disabled = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('禁用索引'),
              subtitle: const Text('禁用后将不会建立索引'),
              value: _disableIndex,
              onChanged: (value) {
                setState(() {
                  _disableIndex = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('启用签名'),
              subtitle: const Text('启用后访问文件需要签名验证'),
              value: _enableSign,
              onChanged: (value) {
                setState(() {
                  _enableSign = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('网页代理'),
              subtitle: const Text('通过网页代理访问文件'),
              value: _webProxy,
              onChanged: (value) {
                setState(() {
                  _webProxy = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('代理范围请求'),
              subtitle: const Text('支持断点续传'),
              value: _proxyRange,
              onChanged: (value) {
                setState(() {
                  _proxyRange = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '驱动配置',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _additionController,
              decoration: const InputDecoration(
                labelText: '附加配置',
                hintText: '请输入JSON格式的驱动配置',
                border: OutlineInputBorder(),
              ),
              maxLines: 8,
              validator: (value) {
                // 可以在这里添加JSON格式验证
                return null;
              },
            ),
            const SizedBox(height: 8),
            Text(
              '请根据所选驱动类型输入相应的配置参数，格式为JSON',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDriverDisplayName(String driver) {
    switch (driver) {
      case 'local':
        return '本地存储';
      case 'aliyundrive':
        return '阿里云盘';
      case 'aliyundrive_open':
        return '阿里云盘开放平台';
      case 'onedrive':
        return 'OneDrive';
      case 'googledrive':
        return 'Google Drive';
      case 'dropbox':
        return 'Dropbox';
      case 'webdav':
        return 'WebDAV';
      case 'ftp':
        return 'FTP';
      case 'sftp':
        return 'SFTP';
      case '123':
        return '123云盘';
      case 'baidu_netdisk':
        return '百度网盘';
      default:
        return driver;
    }
  }

  void _saveStorage() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final storage = Storage(
      id: widget.storage?.id,
      mountPath: _mountPathController.text.trim(),
      driver: _selectedDriver,
      remark: _remarkController.text.trim(),
      order: int.parse(_orderController.text),
      cacheExpiration: int.parse(_cacheExpirationController.text),
      addition: _additionController.text.trim(),
      disabled: _disabled,
      disableIndex: _disableIndex,
      enableSign: _enableSign,
      webProxy: _webProxy,
      proxyRange: _proxyRange,
    );

    try {
      // 显示加载对话框
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('保存中...'),
            ],
          ),
        ),
      );

      final response = _isEditing
          ? await StorageApiService.updateStorage(storage)
          : await StorageApiService.createStorage(storage);

      Navigator.of(context).pop(); // 关闭加载对话框

      if (response.isSuccess) {
        Get.snackbar(
          '成功',
          _isEditing ? '存储更新成功' : '存储创建成功',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        Navigator.of(context).pop(); // 返回上一页
      } else {
        Get.snackbar(
          '错误',
          response.message,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // 关闭加载对话框
      Get.snackbar(
        '错误',
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
