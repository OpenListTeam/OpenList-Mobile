import 'dart:io';
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:get/get.dart' as getx;
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'notification_manager.dart';
import 'intent_utils.dart';
import '../generated/l10n.dart';

/// Download task status
enum DownloadStatus {
  pending,    // Waiting
  downloading, // Downloading
  completed,   // Completed
  failed,      // Failed
  cancelled,   // Cancelled
}

/// Download task
class DownloadTask {
  final String id;
  final String url;
  final String filename;
  final String filePath;
  DownloadStatus status;
  double progress;
  int receivedBytes;
  int totalBytes;
  String? errorMessage;
  DateTime startTime;
  DateTime? endTime;
  CancelToken? cancelToken;

  DownloadTask({
    required this.id,
    required this.url,
    required this.filename,
    required this.filePath,
    this.status = DownloadStatus.pending,
    this.progress = 0.0,
    this.receivedBytes = 0,
    this.totalBytes = 0,
    this.errorMessage,
    DateTime? startTime,
    this.endTime,
    this.cancelToken,
  }) : startTime = startTime ?? DateTime.now();

  String get statusText {
    switch (status) {
      case DownloadStatus.pending:
        return S.current.pending;
      case DownloadStatus.downloading:
        return S.current.downloading;
      case DownloadStatus.completed:
        return S.current.completed;
      case DownloadStatus.failed:
        return S.current.failed;
      case DownloadStatus.cancelled:
        return S.current.cancelled;
    }
  }

  String get progressText {
    if (totalBytes > 0) {
      return '${_formatBytes(receivedBytes)} / ${_formatBytes(totalBytes)}';
    }
    return _formatBytes(receivedBytes);
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }
}

class DownloadManager {
  static final Dio _dio = Dio();
  static final Map<String, DownloadTask> _activeTasks = {};
  static final List<DownloadTask> _completedTasks = [];
  
  /// Get all active download tasks
  static List<DownloadTask> get activeTasks => _activeTasks.values.toList();
  
  /// Get all completed download tasks
  static List<DownloadTask> get completedTasks => _completedTasks;
  
  /// Get all download tasks
  static List<DownloadTask> get allTasks => [..._activeTasks.values, ..._completedTasks];

  /// Download with progress bar (background download, non-blocking UI)
  static Future<bool> downloadFileWithProgress({
    required String url,
    String? filename,
  }) async {
    // Initialize notification manager
    await NotificationManager.initialize();
    
    // Generate task ID
    String taskId = DateTime.now().millisecondsSinceEpoch.toString();
    
    // Get download directory
    Directory? downloadDir = await _getOpenListDownloadDirectory();
    if (downloadDir == null) {
      getx.Get.showSnackbar(const getx.GetSnackBar(
        message: '无法获取下载目录',
        duration: Duration(seconds: 3),
      ));
      return false;
    }

    // Determine filename and path
    String finalFilename = filename ?? _getFilenameFromUrl(url);
    String filePath = '${downloadDir.path}/$finalFilename';
    filePath = _getUniqueFilePath(filePath);
    finalFilename = filePath.split('/').last;

    // Create download task
    CancelToken cancelToken = CancelToken();
    DownloadTask task = DownloadTask(
      id: taskId,
      url: url,
      filename: finalFilename,
      filePath: filePath,
      status: DownloadStatus.pending,
      cancelToken: cancelToken,
    );

    // Add to active task list
    _activeTasks[taskId] = task;

    // Show download start notification (only once)
    getx.Get.showSnackbar(getx.GetSnackBar(
      message: '开始下载: $finalFilename',
      duration: const Duration(seconds: 2),
      backgroundColor: Colors.green,
    ));

    try {
      // Update task status
      task.status = DownloadStatus.downloading;
      
      // Show initial notification
      await NotificationManager.showDownloadProgressNotification();
      
      // Execute download
      await _dio.download(
        url,
        filePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (task.status == DownloadStatus.cancelled) return;
          
          task.receivedBytes = received;
          task.totalBytes = total;
          if (total > 0) {
            task.progress = received / total;
          }
          
          // Update notification progress
          NotificationManager.showDownloadProgressNotification();
          
          log('下载进度: ${(task.progress * 100).toStringAsFixed(1)}%');
        },
      );

      // Download completed
      task.status = DownloadStatus.completed;
      task.endTime = DateTime.now();
      task.progress = 1.0;

      // Move to completed list
      _activeTasks.remove(taskId);
      _completedTasks.insert(0, task); // Insert at beginning, latest first

      // Show single file completion notification
      await NotificationManager.showSingleFileCompleteNotification(task);

      // Show completion notification
      getx.Get.showSnackbar(getx.GetSnackBar(
        message: '下载完成: $finalFilename',
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.blue,
        mainButton: TextButton(
          onPressed: () {
            _openFile(filePath);
          },
          child: const Text('打开'),
        ),
      ));

      log('文件下载完成: $filePath');
      return true;

    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) {
        // User cancelled download
        task.status = DownloadStatus.cancelled;
        task.endTime = DateTime.now();
        log('下载已取消: $url');
      } else {
        // Download failed
        task.status = DownloadStatus.failed;
        task.errorMessage = e.toString();
        task.endTime = DateTime.now();
        log('下载失败: $e');
        
        getx.Get.showSnackbar(getx.GetSnackBar(
          message: '下载失败: $finalFilename',
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ));
      }

      // Move to completed list
      _activeTasks.remove(taskId);
      _completedTasks.insert(0, task);
      
      // Update notification status
      if (_activeTasks.isEmpty) {
        await NotificationManager.cancelDownloadNotification();
      } else {
        await NotificationManager.showDownloadProgressNotification();
      }
      
      return false;
    }
  }

  /// Simple background download (recommended)
  static Future<bool> downloadFileInBackground({
    required String url,
    String? filename,
  }) async {
    return await downloadFileWithProgress(
      url: url,
      filename: filename,
    );
  }

  /// Cancel download task
  static void cancelDownload(String taskId) {
    DownloadTask? task = _activeTasks[taskId];
    if (task != null && task.cancelToken != null) {
      task.cancelToken!.cancel('用户取消下载');
    }
  }

  /// Clear completed download records
  static void clearCompletedTasks() {
    _completedTasks.clear();
  }

  /// Delete download task record
  static void removeTask(String taskId) {
    _activeTasks.remove(taskId);
    _completedTasks.removeWhere((task) => task.id == taskId);
  }

  /// Get OpenList dedicated download directory
  static Future<Directory?> _getOpenListDownloadDirectory() async {
    try {
      Directory? baseDir;
      
      if (Platform.isAndroid) {
        // Android: Prefer public download directory
        baseDir = Directory('/storage/emulated/0/Download');
        if (!await baseDir.exists()) {
          // If public download directory doesn't exist, use external storage directory
          baseDir = await getExternalStorageDirectory();
          if (baseDir != null) {
            baseDir = Directory('${baseDir.path}/Download');
          }
        }
      } else if (Platform.isIOS) {
        // iOS: Use Downloads folder under app documents directory
        baseDir = await getApplicationDocumentsDirectory();
        baseDir = Directory('${baseDir.path}/Downloads');
      } else {
        // Other platforms (Windows, macOS, Linux)
        baseDir = await getDownloadsDirectory();
      }

      if (baseDir == null) {
        log('无法获取基础下载目录');
        return null;
      }

      // Create OpenList dedicated folder
      Directory openListDir = Directory('${baseDir.path}/OpenList');
      
      if (!await openListDir.exists()) {
        try {
          await openListDir.create(recursive: true);
          log('创建OpenList下载目录: ${openListDir.path}');
        } catch (e) {
          log('创建OpenList目录失败: $e');
          // If creation fails, return base directory
          return baseDir;
        }
      }

      log('OpenList下载目录: ${openListDir.path}');
      return openListDir;
      
    } catch (e) {
      log('获取下载目录失败: $e');
      return null;
    }
  }

  /// Extract filename from URL
  static String _getFilenameFromUrl(String url) {
    try {
      Uri uri = Uri.parse(url);
      String path = uri.path;
      if (path.isNotEmpty && path.contains('/')) {
        String filename = path.split('/').last;
        if (filename.isNotEmpty) {
          return filename;
        }
      }
    } catch (e) {
      log('解析文件名失败: $e');
    }
    
    // If unable to extract filename from URL, use timestamp
    return 'download_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Get unique file path (avoid duplicate names)
  static String _getUniqueFilePath(String originalPath) {
    File file = File(originalPath);
    if (!file.existsSync()) {
      return originalPath;
    }

    String directory = file.parent.path;
    String nameWithoutExtension = file.path.split('/').last.split('.').first;
    String extension = file.path.contains('.') 
        ? '.${file.path.split('.').last}' 
        : '';

    int counter = 1;
    String newPath;
    do {
      newPath = '$directory/${nameWithoutExtension}_$counter$extension';
      counter++;
    } while (File(newPath).existsSync());

    return newPath;
  }

  /// Check if file is APK
  static bool _isApkFile(String filePath) {
    return filePath.toLowerCase().endsWith('.apk');
  }

  /// Check and request install permissions
  static Future<bool> _checkInstallPermission() async {
    if (!Platform.isAndroid) return true;
    
    try {
      // Check for install permission
      bool hasPermission = await Permission.requestInstallPackages.isGranted;
      
      if (!hasPermission) {
        // Request install permission
        PermissionStatus status = await Permission.requestInstallPackages.request();
        
        if (status.isGranted) {
          return true;
        } else if (status.isPermanentlyDenied) {
          // Permission permanently denied, guide user to settings page
          getx.Get.dialog(
            AlertDialog(
              title: const Text('需要安装权限'),
              content: const Text('为了安装 APK 文件，需要授予安装权限。请在设置中手动开���。'),
              actions: [
                TextButton(
                  onPressed: () => getx.Get.back(),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () {
                    getx.Get.back();
                    openAppSettings();
                  },
                  child: const Text('去设置'),
                ),
              ],
            ),
          );
          return false;
        } else {
          getx.Get.showSnackbar(const getx.GetSnackBar(
            message: '需要安装权限才能安装 APK 文件',
            duration: Duration(seconds: 3),
          ));
          return false;
        }
      }
      
      return true;
    } catch (e) {
      log('检查安装权限失败: $e');
      return true; // If check fails, continue to try opening
    }
  }

  /// Try to open file
  static Future<void> _openFile(String filePath) async {
    try {
      log('尝试打开文件: $filePath');
      
      // If it's an APK file, check install permission first
      if (_isApkFile(filePath)) {
        bool hasPermission = await _checkInstallPermission();
        if (!hasPermission) {
          return; // No permission, don't continue opening
        }
      }
      
      // Use open_filex plugin to open file
      final result = await OpenFilex.open(filePath);
      
      log('打开文件结果: ${result.type} - ${result.message}');
      
      // Show appropriate message based on result
      switch (result.type) {
        case ResultType.done:
          // File opened successfully, no additional notification needed
          break;
        case ResultType.noAppToOpen:
          if (_isApkFile(filePath)) {
            getx.Get.showSnackbar(getx.GetSnackBar(
              message: '无法安装 APK 文件，可能需要在设置中开启"允许安装未知来源应用"',
              duration: const Duration(seconds: 5),
              mainButton: TextButton(
                onPressed: () {
                  openAppSettings();
                },
                child: const Text('去设置'),
              ),
            ));
          } else {
            getx.Get.showSnackbar(getx.GetSnackBar(
              message: '没有找到可以打开此文件的应用',
              duration: const Duration(seconds: 3),
              mainButton: TextButton(
                onPressed: () {
                  _showFileLocation(filePath);
                },
                child: const Text('查看位置'),
              ),
            ));
          }
          break;
        case ResultType.fileNotFound:
          getx.Get.showSnackbar(const getx.GetSnackBar(
            message: '文件不存在或已被删除',
            duration: Duration(seconds: 3),
          ));
          break;
        case ResultType.permissionDenied:
          if (_isApkFile(filePath)) {
            getx.Get.showSnackbar(getx.GetSnackBar(
              message: '没有权限安装 APK 文件，请在设置中开启安装权限',
              duration: const Duration(seconds: 5),
              mainButton: TextButton(
                onPressed: () {
                  openAppSettings();
                },
                child: const Text('去设置'),
              ),
            ));
          } else {
            getx.Get.showSnackbar(const getx.GetSnackBar(
              message: '没有权限打开此文件',
              duration: Duration(seconds: 3),
            ));
          }
          break;
        case ResultType.error:
          getx.Get.showSnackbar(getx.GetSnackBar(
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
      log('打开文件异常: $e');
      getx.Get.showSnackbar(getx.GetSnackBar(
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

  /// Show file location information dialog
  static void _showFileLocation(String filePath) {
    getx.Get.dialog(
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
            onPressed: () => getx.Get.back(),
            child: const Text('确定'),
          ),
          TextButton(
            onPressed: () {
              getx.Get.back();
              _openFileManagerSelector(filePath);
            },
            child: const Text('打开文件管理器'),
          ),
        ],
      ),
    );
  }

  /// Show file manager selector dialog
  static void _openFileManagerSelector(String filePath) {
    // Get directory containing the file
    String directoryPath = filePath.substring(0, filePath.lastIndexOf('/'));
    final fileManagerOptions = IntentUtils.getAllFileManagerIntents(directoryPath);
    
    getx.Get.dialog(
      AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.folder_open, size: 24),
            SizedBox(width: 8),
            Text('选择文件管理器'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // System app chooser
              ListTile(
                leading: const Icon(Icons.open_in_new, size: 24, color: Colors.blue),
                title: const Text('选择应用打开'),
                subtitle: const Text('让Android系统显示所有可用的应用'),
                onTap: () async {
                  getx.Get.back();
                  await _launchGenericFileManagerChooser(directoryPath);
                },
              ),
              const Divider(),
              // Vendor file manager options
              ...fileManagerOptions.take(6).map((option) {
                return ListTile(
                  leading: Text(
                    option['icon'],
                    style: const TextStyle(fontSize: 20),
                  ),
                  title: Text(option['name']),
                  subtitle: option['isDefault'] == true 
                      ? const Text('推荐选项')
                      : null,
                  onTap: () async {
                    getx.Get.back();
                    await _launchFileManagerIntent(option['intent'], option['name']);
                  },
                );
              }).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => getx.Get.back(),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  /// Launch generic file manager chooser to let user select app
  static Future<void> _launchGenericFileManagerChooser(String directoryPath) async {
    try {
      final intent = IntentUtils.getGenericFileManagerIntent(directoryPath);
      await intent.launchChooser('选择应用打开');
      getx.Get.showSnackbar(const getx.GetSnackBar(
        message: '已打开应用选择器',
        duration: Duration(seconds: 2),
      ));
    } catch (e) {
      log('打开文件管理器选择器失败: $e');
      getx.Get.showSnackbar(getx.GetSnackBar(
        message: '打开选择器失败: $e',
        duration: const Duration(seconds: 3),
      ));
    }
  }

  /// Launch specified file manager using Intent
  static Future<void> _launchFileManagerIntent(dynamic intent, String managerName) async {
    try {
      await intent.launch();
      getx.Get.showSnackbar(getx.GetSnackBar(
        message: '已打开 $managerName',
        duration: const Duration(seconds: 2),
      ));
    } catch (e) {
      log('打开 $managerName 失败: $e');
      getx.Get.showSnackbar(getx.GetSnackBar(
        message: '打开 $managerName 失败: $e',
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.orange,
      ));
    }
  }

  /// Get OpenList download directory path (public method)
  static Future<String?> getDownloadDirectoryPath() async {
    Directory? dir = await _getOpenListDownloadDirectory();
    return dir?.path;
  }

  /// List downloaded files
  static Future<List<FileSystemEntity>> getDownloadedFiles() async {
    try {
      Directory? downloadDir = await _getOpenListDownloadDirectory();
      if (downloadDir != null && await downloadDir.exists()) {
        return downloadDir.listSync();
      }
    } catch (e) {
      log('获取下载文件列表失败: $e');
    }
    return [];
  }

  /// Clean download directory
  static Future<bool> clearDownloadDirectory() async {
    try {
      Directory? downloadDir = await _getOpenListDownloadDirectory();
      if (downloadDir != null && await downloadDir.exists()) {
        await downloadDir.delete(recursive: true);
        log('已清理下载目录');
        return true;
      }
    } catch (e) {
      log('清理下载目录失败: $e');
    }
    return false;
  }

  /// Delete specified file
  static Future<bool> deleteFile(String filename) async {
    try {
      Directory? downloadDir = await _getOpenListDownloadDirectory();
      if (downloadDir != null) {
        File file = File('${downloadDir.path}/$filename');
        if (await file.exists()) {
          await file.delete();
          log('已删除文件: $filename');
          return true;
        }
      }
    } catch (e) {
      log('删除文件失败: $e');
    }
    return false;
  }
}

/// Download controller (maintaining backward compatibility)
class DownloadController extends getx.GetxController {
  double _progress = 0.0;
  String _statusText = '准备下载...';
  bool _isCancelled = false;

  double get progress => _progress;
  String get statusText => _statusText;
  bool get isCancelled => _isCancelled;

  void updateProgress(double progress, int received, int total) {
    if (_isCancelled) return;
    
    _progress = progress;
    _statusText = '${_formatBytes(received)} / ${_formatBytes(total)}';
    update();
  }

  void cancelDownload() {
    _isCancelled = true;
    _statusText = '下载已取消';
    update();
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }
}