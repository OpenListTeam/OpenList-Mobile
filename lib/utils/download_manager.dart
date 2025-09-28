import 'dart:io';
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:get/get.dart' as getx;
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'notification_manager.dart';
import '../generated/l10n.dart';

/// 下载任务状态
enum DownloadStatus {
  pending,    // 等待中
  downloading, // 下载中
  completed,   // 已完成
  failed,      // 失败
  cancelled,   // 已取消
}

/// 下载任务
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
  
  /// 获取所有活跃的下载任务
  static List<DownloadTask> get activeTasks => _activeTasks.values.toList();
  
  /// 获取所有已完成的下载任务
  static List<DownloadTask> get completedTasks => _completedTasks;
  
  /// 获取所有下载任务
  static List<DownloadTask> get allTasks => [..._activeTasks.values, ..._completedTasks];

  /// 带进度条的下载（后台下载，不阻塞UI）
  static Future<bool> downloadFileWithProgress({
    required String url,
    String? filename,
  }) async {
    // 初始化通知管理器
    await NotificationManager.initialize();
    
    // 生成任务ID
    String taskId = DateTime.now().millisecondsSinceEpoch.toString();
    
    // 获取下载目录
    Directory? downloadDir = await _getOpenListDownloadDirectory();
    if (downloadDir == null) {
      getx.Get.showSnackbar(getx.GetSnackBar(
        message: S.current.cannotGetDownloadDirectory,
        duration: const Duration(seconds: 3),
      ));
      return false;
    }

    // 确定文件名和路径
    String finalFilename = filename ?? _getFilenameFromUrl(url);
    String filePath = '${downloadDir.path}/$finalFilename';
    filePath = _getUniqueFilePath(filePath);
    finalFilename = filePath.split('/').last;

    // 创建下载任务
    CancelToken cancelToken = CancelToken();
    DownloadTask task = DownloadTask(
      id: taskId,
      url: url,
      filename: finalFilename,
      filePath: filePath,
      status: DownloadStatus.pending,
      cancelToken: cancelToken,
    );

    // 添加到活跃任务列表
    _activeTasks[taskId] = task;

    // 显示开始下载提示（只显示一次）
    getx.Get.showSnackbar(getx.GetSnackBar(
      message: S.current.startDownloadFile(finalFilename),
      duration: const Duration(seconds: 2),
      backgroundColor: Colors.green,
    ));

    try {
      // 更新任务状态
      task.status = DownloadStatus.downloading;
      
      // 显示初始通知
      await NotificationManager.showDownloadProgressNotification();
      
      // 执行下载
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
          
          // 更新通知进度
          NotificationManager.showDownloadProgressNotification();
          
          log('下载进度: ${(task.progress * 100).toStringAsFixed(1)}%');
        },
      );

      // 下载完成
      task.status = DownloadStatus.completed;
      task.endTime = DateTime.now();
      task.progress = 1.0;

      // 移动到已完成列表
      _activeTasks.remove(taskId);
      _completedTasks.insert(0, task); // 插入到开头，最新的在前面

      // 显示单个文件完成通知
      await NotificationManager.showSingleFileCompleteNotification(task);

      // 显示完成提示
      getx.Get.showSnackbar(getx.GetSnackBar(
        message: S.current.downloadCompleteFile(finalFilename),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.blue,
        mainButton: TextButton(
          onPressed: () {
            _openFile(filePath);
          },
          child: Text(S.current.open),
        ),
      ));

      log('文件下载完成: $filePath');
      return true;

    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) {
        // 用户取消下载
        task.status = DownloadStatus.cancelled;
        task.endTime = DateTime.now();
        log('下载已取消: $url');
      } else {
        // 下载失败
        task.status = DownloadStatus.failed;
        task.errorMessage = e.toString();
        task.endTime = DateTime.now();
        log('下载失败: $e');
        
        getx.Get.showSnackbar(getx.GetSnackBar(
          message: S.current.downloadFailedFile(finalFilename),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ));
      }

      // 移动到已完成列表
      _activeTasks.remove(taskId);
      _completedTasks.insert(0, task);
      
      // 更新通知状态
      if (_activeTasks.isEmpty) {
        await NotificationManager.cancelDownloadNotification();
      } else {
        await NotificationManager.showDownloadProgressNotification();
      }
      
      return false;
    }
  }

  /// 简单的后台下载（推荐使用）
  static Future<bool> downloadFileInBackground({
    required String url,
    String? filename,
  }) async {
    return await downloadFileWithProgress(
      url: url,
      filename: filename,
    );
  }

  /// 取消下载任务
  static void cancelDownload(String taskId) {
    DownloadTask? task = _activeTasks[taskId];
    if (task != null && task.cancelToken != null) {
      task.cancelToken!.cancel(S.current.userCancelledDownloadError);
    }
  }

  /// 清除已完成的下载记录
  static void clearCompletedTasks() {
    _completedTasks.clear();
  }

  /// 删除下载任务记录
  static void removeTask(String taskId) {
    _activeTasks.remove(taskId);
    _completedTasks.removeWhere((task) => task.id == taskId);
  }

  /// 获取OpenList专用下载目录
  static Future<Directory?> _getOpenListDownloadDirectory() async {
    try {
      Directory? baseDir;
      
      if (Platform.isAndroid) {
        // Android: 优先使用公共下载目录
        baseDir = Directory('/storage/emulated/0/Download');
        if (!await baseDir.exists()) {
          // 如果公共下载目录不存在，使用外部存储目录
          baseDir = await getExternalStorageDirectory();
          if (baseDir != null) {
            baseDir = Directory('${baseDir.path}/Download');
          }
        }
      } else if (Platform.isIOS) {
        // iOS: 使用应用文档目录下的Downloads文件夹
        baseDir = await getApplicationDocumentsDirectory();
        baseDir = Directory('${baseDir.path}/Downloads');
      } else {
        // 其他平台（如Windows、macOS、Linux）
        baseDir = await getDownloadsDirectory();
      }

      if (baseDir == null) {
        log('无法获取基础下载目录');
        return null;
      }

      // 创建OpenList专用文件夹
      Directory openListDir = Directory('${baseDir.path}/OpenList');
      
      if (!await openListDir.exists()) {
        try {
          await openListDir.create(recursive: true);
          log('创建OpenList下载目录: ${openListDir.path}');
        } catch (e) {
          log('创建OpenList目录失败: $e');
          // 如果创建失败，返回基础目录
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

  /// 从URL中提取文件名
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
    
    // 如果无法从URL提取文件名，使用时间戳
    return 'download_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// 获取唯一的文件路径（避免重名）
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

  /// 检查是否为 APK 文件
  static bool _isApkFile(String filePath) {
    return filePath.toLowerCase().endsWith('.apk');
  }

  /// 检查和请求安装权限
  static Future<bool> _checkInstallPermission() async {
    if (!Platform.isAndroid) return true;
    
    try {
      // 检查是否有安装权限
      bool hasPermission = await Permission.requestInstallPackages.isGranted;
      
      if (!hasPermission) {
        // 请求安装权限
        PermissionStatus status = await Permission.requestInstallPackages.request();
        
        if (status.isGranted) {
          return true;
        } else if (status.isPermanentlyDenied) {
          // 权限被永久拒绝，引导用户到设置页面
          getx.Get.dialog(
            AlertDialog(
              title: Text(S.current.needInstallPermission),
              content: Text(S.current.needInstallPermissionDesc),
              actions: [
                TextButton(
                  onPressed: () => getx.Get.back(),
                  child: Text(S.current.cancel),
                ),
                TextButton(
                  onPressed: () {
                    getx.Get.back();
                    openAppSettings();
                  },
                  child: Text(S.current.goToSettings),
                ),
              ],
            ),
          );
          return false;
        } else {
          getx.Get.showSnackbar(getx.GetSnackBar(
            message: S.current.needInstallPermissionToInstallApk,
            duration: const Duration(seconds: 3),
          ));
          return false;
        }
      }
      
      return true;
    } catch (e) {
      log('检查安装权限失败: $e');
      return true; // 如果检查失败，继续尝试打开
    }
  }

  /// 尝试打开文件
  static Future<void> _openFile(String filePath) async {
    try {
      log('尝试打开文件: $filePath');
      
      // 如果是 APK 文件，先检查安装权限
      if (_isApkFile(filePath)) {
        bool hasPermission = await _checkInstallPermission();
        if (!hasPermission) {
          return; // 没有权限，不继续打开
        }
      }
      
      // 使用 open_filex 插件打开文件
      final result = await OpenFilex.open(filePath);
      
      log('打开文件结果: ${result.type} - ${result.message}');
      
      // 根据结果显示相应的提示
      switch (result.type) {
        case ResultType.done:
          // 文件成功打开，不需要额外提示
          break;
        case ResultType.noAppToOpen:
          if (_isApkFile(filePath)) {
            getx.Get.showSnackbar(getx.GetSnackBar(
              message: S.current.cannotInstallApkNeedPermission,
              duration: const Duration(seconds: 5),
              mainButton: TextButton(
                onPressed: () {
                  openAppSettings();
                },
                child: Text(S.current.goToSettings),
              ),
            ));
          } else {
            getx.Get.showSnackbar(getx.GetSnackBar(
              message: S.current.noAppToOpenFile,
              duration: const Duration(seconds: 3),
              mainButton: TextButton(
                onPressed: () {
                  _showFileLocation(filePath);
                },
                child: Text(S.current.viewLocation),
              ),
            ));
          }
          break;
        case ResultType.fileNotFound:
          getx.Get.showSnackbar(getx.GetSnackBar(
            message: S.current.fileNotFound,
            duration: const Duration(seconds: 3),
          ));
          break;
        case ResultType.permissionDenied:
          if (_isApkFile(filePath)) {
            getx.Get.showSnackbar(getx.GetSnackBar(
              message: S.current.noPermissionToInstallApkFile,
              duration: const Duration(seconds: 5),
              mainButton: TextButton(
                onPressed: () {
                  openAppSettings();
                },
                child: Text(S.current.goToSettings),
              ),
            ));
          } else {
            getx.Get.showSnackbar(getx.GetSnackBar(
              message: S.current.noPermissionToOpenFile,
              duration: const Duration(seconds: 3),
            ));
          }
          break;
        case ResultType.error:
          getx.Get.showSnackbar(getx.GetSnackBar(
            message: S.current.openFileFailed(result.message),
            duration: const Duration(seconds: 3),
            mainButton: TextButton(
              onPressed: () {
                _showFileLocation(filePath);
              },
              child: Text(S.current.viewLocation),
            ),
          ));
          break;
      }
    } catch (e) {
      log('打开文件异常: $e');
      getx.Get.showSnackbar(getx.GetSnackBar(
        message: S.current.openFileException(e.toString()),
        duration: const Duration(seconds: 3),
        mainButton: TextButton(
          onPressed: () {
            _showFileLocation(filePath);
          },
          child: Text(S.current.viewLocation),
        ),
      ));
    }
  }

  /// 显示文件位置信息
  static void _showFileLocation(String filePath) {
    getx.Get.dialog(
      AlertDialog(
        title: Text(S.current.fileLocation),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(S.current.fileSavedTo),
            const SizedBox(height: 8),
            SelectableText(
              filePath,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 16),
            Text(
              S.current.fileLocationTip,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => getx.Get.back(),
            child: Text(S.current.ok),
          ),
        ],
      ),
    );
  }

  /// 获取OpenList下载目录路径（公共方法）
  static Future<String?> getDownloadDirectoryPath() async {
    Directory? dir = await _getOpenListDownloadDirectory();
    return dir?.path;
  }

  /// 列出已下载的文件
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

  /// 清理下载目录
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

  /// 删除指定文件
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

/// 下载控制器（保持向后兼容）
class DownloadController extends getx.GetxController {
  double _progress = 0.0;
  String _statusText = S.current.preparingDownloadStatus;
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
    _statusText = S.current.downloadCancelledText;
    update();
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }
}