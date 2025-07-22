import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
import '../utils/download_manager.dart';
import '../generated/l10n.dart';

/// 下载文件管理页面
class DownloadManagerPage extends StatefulWidget {
  const DownloadManagerPage({Key? key}) : super(key: key);

  @override
  State<DownloadManagerPage> createState() => _DownloadManagerPageState();
}

class _DownloadManagerPageState extends State<DownloadManagerPage>
    with TickerProviderStateMixin {
  List<FileSystemEntity> _downloadedFiles = [];
  bool _isLoading = true;
  String? _downloadPath;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDownloadedFiles();
    
    // 定期刷新活跃任务状态
    _startPeriodicRefresh();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _startPeriodicRefresh() {
    // 每秒刷新一次活跃任务状态
    Stream.periodic(const Duration(seconds: 1)).listen((_) {
      if (mounted && _tabController.index == 0) {
        setState(() {});
      }
    });
  }

  Future<void> _loadDownloadedFiles() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _downloadedFiles = await DownloadManager.getDownloadedFiles();
      _downloadPath = await DownloadManager.getDownloadDirectoryPath();
    } catch (e) {
      print('${S.current.loadDownloadFilesFailed}: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
           '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  IconData _getFileIcon(String filename) {
    String extension = filename.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'mp4':
      case 'avi':
      case 'mkv':
        return Icons.video_file;
      case 'mp3':
      case 'wav':
        return Icons.audio_file;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.archive;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'apk':
        return Icons.android;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getStatusColor(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.pending:
        return Colors.orange;
      case DownloadStatus.downloading:
        return Colors.blue;
      case DownloadStatus.completed:
        return Colors.green;
      case DownloadStatus.failed:
        return Colors.red;
      case DownloadStatus.cancelled:
        return Colors.grey;
    }
  }

  Widget _buildActiveTasksTab() {
    List<DownloadTask> activeTasks = DownloadManager.activeTasks;
    
    if (activeTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.download_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              S.of(context).noActiveDownloads,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: activeTasks.length,
      itemBuilder: (context, index) {
        DownloadTask task = activeTasks[index];
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getFileIcon(task.filename),
                      size: 32,
                      color: _getStatusColor(task.status),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.filename,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            task.statusText,
                            style: TextStyle(
                              fontSize: 14,
                              color: _getStatusColor(task.status),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (task.status == DownloadStatus.downloading)
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () {
                          _confirmCancelDownload(task);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (task.status == DownloadStatus.downloading) ...[
                  LinearProgressIndicator(
                    value: task.progress,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getStatusColor(task.status),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        task.progressText,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        '${(task.progress * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ] else if (task.status == DownloadStatus.failed) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            task.errorMessage ?? S.of(context).downloadFailed,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  '${S.of(context).startTime}: ${_formatDateTime(task.startTime)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompletedTasksTab() {
    List<DownloadTask> completedTasks = DownloadManager.completedTasks;
    
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (completedTasks.isEmpty && _downloadedFiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.download_done,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              S.of(context).noCompletedDownloads,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDownloadedFiles,
      child: ListView(
        children: [
          // 显示任务记录中的已完成下载
          ...completedTasks.map((task) => Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: Icon(
                _getFileIcon(task.filename),
                size: 32,
                color: _getStatusColor(task.status),
              ),
              title: Text(
                task.filename,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.statusText,
                    style: TextStyle(color: _getStatusColor(task.status)),
                  ),
                  if (task.endTime != null)
                    Text('${S.of(context).completedTime}: ${_formatDateTime(task.endTime!)}'),
                  if (task.totalBytes > 0)
                    Text('${S.of(context).size}: ${_formatFileSize(task.totalBytes)}'),
                ],
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'open':
                      if (task.status == DownloadStatus.completed) {
                        _openFile(task.filePath);
                      }
                      break;
                    case 'delete_record':
                      _confirmDeleteTaskRecord(task);
                      break;
                    case 'delete_file':
                      if (task.status == DownloadStatus.completed) {
                        _confirmDeleteFile(task.filename);
                      }
                      break;
                  }
                },
                itemBuilder: (context) => [
                  if (task.status == DownloadStatus.completed)
                    PopupMenuItem(
                      value: 'open',
                      child: Row(
                        children: [
                          const Icon(Icons.open_in_new),
                          const SizedBox(width: 8),
                          Text(S.of(context).openFile),
                        ],
                      ),
                    ),
                  PopupMenuItem(
                    value: 'delete_record',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline),
                        const SizedBox(width: 8),
                        Text(S.of(context).deleteRecord),
                      ],
                    ),
                  ),
                  if (task.status == DownloadStatus.completed)
                    PopupMenuItem(
                      value: 'delete_file',
                      child: Row(
                        children: [
                          const Icon(Icons.delete, color: Colors.red),
                          const SizedBox(width: 8),
                          Text(S.of(context).deleteFile, style: const TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          )),
          
          // 显示文件系统中的其他下载文件
          ..._downloadedFiles.where((file) {
            String filename = file.path.split('/').last;
            // 过滤掉已经在任务记录的文件
            return !completedTasks.any((task) => task.filename == filename);
          }).map((file) {
            String filename = file.path.split('/').last;
            FileStat stat = file.statSync();
            
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                leading: Icon(
                  _getFileIcon(filename),
                  size: 32,
                  color: Theme.of(context).primaryColor,
                ),
                title: Text(
                  filename,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('大小: ${_formatFileSize(stat.size)}'),
                    Text('时间: ${_formatDateTime(stat.modified)}'),
                  ],
                ),
                trailing: const Icon(Icons.more_vert),
                onTap: () => _showFileOptions(file),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _confirmCancelDownload(DownloadTask task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('取消下载'),
        content: Text('确定要取消下载 "${task.filename}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('继续下载'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              DownloadManager.cancelDownload(task.id);
              setState(() {});
            },
            child: const Text('取消下载', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteTaskRecord(DownloadTask task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除记录'),
        content: Text('确定要删除 "${task.filename}" 的下载记录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              DownloadManager.removeTask(task.id);
              setState(() {});
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showFileOptions(FileSystemEntity file) {
    String filename = file.path.split('/').last;
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              filename,
              style: Theme.of(context).textTheme.titleMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: const Text('打开文件'),
              onTap: () async {
                Navigator.pop(context);
                await _openFile(file.path);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('分享文件'),
              onTap: () {
                Navigator.pop(context);
                // 这里可以添加分享功能
                Get.showSnackbar(const GetSnackBar(
                  message: '分享功能待实现',
                  duration: Duration(seconds: 2),
                ));
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('文件信息'),
              onTap: () {
                Navigator.pop(context);
                _showFileInfo(file);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('删除文件', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteFile(filename);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFileInfo(FileSystemEntity file) {
    String filename = file.path.split('/').last;
    FileStat stat = file.statSync();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('文件信息'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('文件名: $filename'),
            const SizedBox(height: 8),
            Text('大小: ${_formatFileSize(stat.size)}'),
            const SizedBox(height: 8),
            Text('修改时间: ${_formatDateTime(stat.modified)}'),
            const SizedBox(height: 8),
            Text('路径: ${file.path}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteFile(String filename) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除文件 "$filename" 吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              bool success = await DownloadManager.deleteFile(filename);
              if (success) {
                Get.showSnackbar(const GetSnackBar(
                  message: '文件已删除',
                  duration: Duration(seconds: 2),
                ));
                _loadDownloadedFiles(); // 刷新列表
              } else {
                Get.showSnackbar(const GetSnackBar(
                  message: '删除失败',
                  duration: Duration(seconds: 2),
                ));
              }
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmClearAll() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清空'),
        content: const Text('确定要清空所有下载文件吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              bool success = await DownloadManager.clearDownloadDirectory();
              if (success) {
                DownloadManager.clearCompletedTasks();
                Get.showSnackbar(const GetSnackBar(
                  message: '已清空下载目录',
                  duration: Duration(seconds: 2),
                ));
                _loadDownloadedFiles(); // 刷新列表
                setState(() {});
              } else {
                Get.showSnackbar(const GetSnackBar(
                  message: '清空失败',
                  duration: Duration(seconds: 2),
                ));
              }
            },
            child: const Text('清空', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// 打开文件
  Future<void> _openFile(String filePath) async {
    try {
      final result = await OpenFilex.open(filePath);
      
      switch (result.type) {
        case ResultType.done:
          // 文件成功打开，不需要额外提示
          break;
        case ResultType.noAppToOpen:
          Get.showSnackbar(GetSnackBar(
            message: '没有找到可以打开此文件的应用',
            duration: const Duration(seconds: 3),
            mainButton: TextButton(
              onPressed: () {
                _showFileLocation(filePath);
              },
              child: const Text('查看位置'),
            ),
          ));
          break;
        case ResultType.fileNotFound:
          Get.showSnackbar(const GetSnackBar(
            message: '文件不存在或已被删除',
            duration: Duration(seconds: 3),
          ));
          break;
        case ResultType.permissionDenied:
          Get.showSnackbar(const GetSnackBar(
            message: '没有权限打开此文件',
            duration: Duration(seconds: 3),
          ));
          break;
        case ResultType.error:
          Get.showSnackbar(GetSnackBar(
            message: '打开文件失败: ${result.message}',
            duration: const Duration(seconds: 3),
            mainButton: TextButton(
              onPressed: () {
                _showFileLocation(filePath);
              },
              child: const Text('查看位置'),
            ),
          ));
          break;
      }
    } catch (e) {
      Get.showSnackbar(GetSnackBar(
        message: '打开文件失败: ${e.toString()}',
        duration: const Duration(seconds: 3),
        mainButton: TextButton(
          onPressed: () {
            _showFileLocation(filePath);
          },
          child: const Text('查看位置'),
        ),
      ));
    }
  }

  /// 显示文件位置信息
  void _showFileLocation(String filePath) {
    Get.dialog(
      AlertDialog(
        title: const Text('文件位置'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('文件已保存到:'),
            const SizedBox(height: 8),
            SelectableText(
              filePath,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 16),
            const Text(
              '您可以使用文件管理器找到此文件，或者尝试安装相应的应用来打开它。',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('下载管理'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.downloading),
              text: '进行中 (${DownloadManager.activeTasks.length})',
            ),
            Tab(
              icon: const Icon(Icons.download_done),
              text: '已完成 (${DownloadManager.completedTasks.length + _downloadedFiles.length})',
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadDownloadedFiles();
              setState(() {});
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'clear_records':
                  DownloadManager.clearCompletedTasks();
                  setState(() {});
                  Get.showSnackbar(const GetSnackBar(
                    message: '已清空下载记录',
                    duration: Duration(seconds: 2),
                  ));
                  break;
                case 'clear_all':
                  _confirmClearAll();
                  break;
                case 'open_folder':
                  if (_downloadPath != null) {
                    Get.dialog(
                      AlertDialog(
                        title: const Text('下载目录'),
                        content: SelectableText(_downloadPath!),
                        actions: [
                          TextButton(
                            onPressed: () => Get.back(),
                            child: const Text('确定'),
                          ),
                        ],
                      ),
                    );
                  }
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'open_folder',
                child: Row(
                  children: [
                    Icon(Icons.folder_open),
                    SizedBox(width: 8),
                    Text('打开目录'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_records',
                child: Row(
                  children: [
                    Icon(Icons.clear_all),
                    SizedBox(width: 8),
                    Text('清空记录'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_forever, color: Colors.red),
                    SizedBox(width: 8),
                    Text('清空所有', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActiveTasksTab(),
          _buildCompletedTasksTab(),
        ],
      ),
    );
  }
}