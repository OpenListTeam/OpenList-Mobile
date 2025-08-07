import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
import '../utils/download_manager.dart';
import '../utils/intent_utils.dart';
import '../generated/l10n.dart';

/// Download file management page
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
    
    // Periodically refresh active task status
    _startPeriodicRefresh();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _startPeriodicRefresh() {
    // Refresh active task status every second
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
          // Show completed downloads from task records
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
                    case 'open_folder':
                      if (task.status == DownloadStatus.completed) {
                        _openFileManager(task.filePath);
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
                  if (task.status == DownloadStatus.completed)
                    PopupMenuItem(
                      value: 'open_folder',
                      child: Row(
                        children: [
                          const Icon(Icons.folder_open),
                          const SizedBox(width: 8),
                          Text(S.of(context).showInFileManager),
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
          
          // Show other download files from file system
          ..._downloadedFiles.where((file) {
            String filename = file.path.split('/').last;
            // Filter out files already in task records
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
                    Text('${S.of(context).size}: ${_formatFileSize(stat.size)}'),
                    Text('${S.of(context).modifiedTime}: ${_formatDateTime(stat.modified)}'),
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
        title: Text(S.of(context).cancelDownload),
        content: Text(S.of(context).confirmCancelDownload(task.filename)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(S.of(context).continueDownload),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              DownloadManager.cancelDownload(task.id);
              setState(() {});
            },
            child: Text(S.of(context).cancelDownload, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteTaskRecord(DownloadTask task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.of(context).deleteRecord),
        content: Text(S.of(context).confirmDeleteRecord(task.filename)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(S.of(context).cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              DownloadManager.removeTask(task.id);
              setState(() {});
            },
            child: Text(S.of(context).delete, style: const TextStyle(color: Colors.red)),
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
              title: Text(S.of(context).openFile),
              onTap: () async {
                Navigator.pop(context);
                await _openFile(file.path);
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder_open),
              title: Text(S.of(context).showInFileManager),
              onTap: () {
                Navigator.pop(context);
                _openFileManager(file.path);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: Text(S.of(context).shareFile),
              onTap: () {
                Navigator.pop(context);
                // Share functionality can be added here
                Get.showSnackbar(GetSnackBar(
                  message: S.of(context).shareFeatureNotImplemented,
                  duration: const Duration(seconds: 2),
                ));
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: Text(S.of(context).fileInfo),
              onTap: () {
                Navigator.pop(context);
                _showFileInfo(file);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: Text(S.of(context).deleteFile, style: const TextStyle(color: Colors.red)),
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
        title: Text(S.of(context).fileInfo),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${S.of(context).fileName}: $filename'),
            const SizedBox(height: 8),
            Text('${S.of(context).size}: ${_formatFileSize(stat.size)}'),
            const SizedBox(height: 8),
            Text('${S.of(context).modifiedTime}: ${_formatDateTime(stat.modified)}'),
            const SizedBox(height: 8),
            Text('${S.of(context).filePath}: ${file.path}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(S.of(context).ok),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteFile(String filename) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.of(context).confirmDelete),
        content: Text(S.of(context).confirmDeleteFile(filename)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(S.of(context).cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              bool success = await DownloadManager.deleteFile(filename);
              if (success) {
                Get.showSnackbar(GetSnackBar(
                  message: S.of(context).fileDeleted,
                  duration: const Duration(seconds: 2),
                ));
                _loadDownloadedFiles(); // Refresh list
              } else {
                Get.showSnackbar(GetSnackBar(
                  message: S.of(context).deleteFailed,
                  duration: const Duration(seconds: 2),
                ));
              }
            },
            child: Text(S.of(context).delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmClearAll() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.of(context).confirmClear),
        content: Text(S.of(context).confirmClearAllFiles),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(S.of(context).cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              bool success = await DownloadManager.clearDownloadDirectory();
              if (success) {
                DownloadManager.clearCompletedTasks();
                Get.showSnackbar(GetSnackBar(
                  message: S.of(context).cleared,
                  duration: const Duration(seconds: 2),
                ));
                _loadDownloadedFiles(); // Refresh list
                setState(() {});
              } else {
                Get.showSnackbar(GetSnackBar(
                  message: S.of(context).clearFailed,
                  duration: const Duration(seconds: 2),
                ));
              }
            },
            child: Text(S.of(context).clear, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// Open file
  Future<void> _openFile(String filePath) async {
    try {
      final result = await OpenFilex.open(filePath);
      
      switch (result.type) {
        case ResultType.done:
          // File opened successfully, no additional notification needed
          break;
        case ResultType.noAppToOpen:
          Get.showSnackbar(GetSnackBar(
            message: S.of(context).noAppToOpenFile,
            duration: const Duration(seconds: 3),
            mainButton: TextButton(
              onPressed: () {
                _showFileLocation(filePath);
              },
              child: Text(S.of(context).viewLocation),
            ),
          ));
          break;
        case ResultType.fileNotFound:
          Get.showSnackbar(GetSnackBar(
            message: S.of(context).fileNotFound,
            duration: const Duration(seconds: 3),
          ));
          break;
        case ResultType.permissionDenied:
          Get.showSnackbar(GetSnackBar(
            message: S.of(context).noPermissionToOpenFile,
            duration: const Duration(seconds: 3),
          ));
          break;
        case ResultType.error:
          Get.showSnackbar(GetSnackBar(
            message: S.of(context).openFileFailed(result.message),
            duration: const Duration(seconds: 3),
            mainButton: TextButton(
              onPressed: () {
                _showFileLocation(filePath);
              },
              child: Text(S.of(context).viewLocation),
            ),
          ));
          break;
      }
    } catch (e) {
      Get.showSnackbar(GetSnackBar(
        message: S.of(context).openFileFailed(e.toString()),
        duration: const Duration(seconds: 3),
        mainButton: TextButton(
          onPressed: () {
            _showFileLocation(filePath);
          },
          child: Text(S.of(context).viewLocation),
        ),
      ));
    }
  }

  /// Open file manager and navigate to specified file location
  Future<void> _openFileManager(String filePath) async {
    try {
      // Get the directory containing the file
      String directoryPath = filePath.substring(0, filePath.lastIndexOf('/'));
      
      // Use system app chooser to open file manager
      final intent = IntentUtils.getFileManagerIntent(directoryPath);
      await intent.launchChooser('选择文件管理器');
      
      Get.showSnackbar(GetSnackBar(
        message: '已打开文件管理器选择器',
        duration: const Duration(seconds: 2),
      ));
    } catch (e) {
      Get.showSnackbar(GetSnackBar(
        message: '打开文件管理器失败: $e',
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.orange,
      ));
    }
  }

  /// Open download directory
  Future<void> _openDownloadDirectory() async {
    if (_downloadPath != null) {
      // Show file manager selection dialog
      _openFileManager(_downloadPath!);
    } else {
      Get.showSnackbar(GetSnackBar(
        message: S.of(context).downloadDirectoryPathUnknown,
        duration: const Duration(seconds: 2),
      ));
    }
  }

  /// Show file location information
  void _showFileLocation(String filePath) {
    Get.dialog(
      AlertDialog(
        title: Text(S.of(context).fileLocation),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(S.of(context).fileSavedTo),
            const SizedBox(height: 8),
            SelectableText(
              filePath,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 16),
            Text(
              S.of(context).fileLocationTip,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(S.of(context).cancel),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              _openFileManager(filePath);
            },
            child: Text(S.of(context).openFileManager),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).downloadManager),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.downloading),
              text: '${S.of(context).inProgress} (${DownloadManager.activeTasks.length})',
            ),
            Tab(
              icon: const Icon(Icons.download_done),
              text: '${S.of(context).completed} (${DownloadManager.completedTasks.length + _downloadedFiles.length})',
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
                  Get.showSnackbar(GetSnackBar(
                    message: S.of(context).downloadRecordsCleared,
                    duration: const Duration(seconds: 2),
                  ));
                  break;
                case 'clear_all':
                  _confirmClearAll();
                  break;
                case 'open_folder':
                  _openDownloadDirectory();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'open_folder',
                child: Row(
                  children: [
                    const Icon(Icons.folder_open),
                    const SizedBox(width: 8),
                    Text(S.of(context).openDirectory),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'clear_records',
                child: Row(
                  children: [
                    const Icon(Icons.clear_all),
                    const SizedBox(width: 8),
                    Text(S.of(context).clearRecords),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    const Icon(Icons.delete_forever, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(S.of(context).clearAll, style: const TextStyle(color: Colors.red)),
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