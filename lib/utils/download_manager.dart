import 'dart:async';
import 'dart:io';
import 'dart:developer';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:get/get.dart' as getx;
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_manager.dart';
import 'package:openlist_mobile/generated/l10n.dart';

/// 下载任务状态
enum DownloadStatus {
  pending,
  downloading,
  paused,
  cancelling,
  completed,
  failed,
  cancelled,
}

class DownloadTask {
  final String id;
  final String url;
  final String filename;
  final String filePath;
  final String? partialFilePath;
  DownloadStatus status;
  double progress;
  int receivedBytes;
  int totalBytes;
  String? errorMessage;
  DateTime startTime;
  DateTime? endTime;
  CancelToken? cancelToken;
  bool pauseRequested = false;
  Completer<void>? resumeSignal;
  DateTime? lastUiProgressUpdate;
  DateTime? lastSystemProgressUpdate;

  DownloadTask({
    required this.id,
    required this.url,
    required this.filename,
    required this.filePath,
    this.partialFilePath,
    this.status = DownloadStatus.pending,
    this.progress = 0.0,
    this.receivedBytes = 0,
    this.totalBytes = 0,
    this.errorMessage,
    DateTime? startTime,
    this.endTime,
    this.cancelToken,
  }) : startTime = startTime ?? DateTime.now();

  Map<String, Object?> toHistory() => {
        'id': id,
        'filename': filename,
        'status': status.name,
        'progress': progress,
        'receivedBytes': receivedBytes,
        'totalBytes': totalBytes,
        'startTime': startTime.millisecondsSinceEpoch,
        'endTime': endTime?.millisecondsSinceEpoch,
        'errorMessage': errorMessage == null ? null : 'Download failed',
      };

  static DownloadTask? fromHistory(Map<String, dynamic> data) {
    try {
      final status = DownloadStatus.values.byName(data['status'] as String);
      if (status == DownloadStatus.pending ||
          status == DownloadStatus.downloading ||
          status == DownloadStatus.paused ||
          status == DownloadStatus.cancelling) {
        return null;
      }
      return DownloadTask(
        id: data['id'] as String,
        url: '',
        filename: data['filename'] as String,
        filePath: '',
        status: status,
        progress: (data['progress'] as num?)?.toDouble() ?? 0,
        receivedBytes: data['receivedBytes'] as int? ?? 0,
        totalBytes: data['totalBytes'] as int? ?? 0,
        errorMessage: data['errorMessage'] as String?,
        startTime:
            DateTime.fromMillisecondsSinceEpoch(data['startTime'] as int),
        endTime: (data['endTime'] as int?) == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(data['endTime'] as int),
      );
    } catch (_) {
      return null;
    }
  }

  String get statusText {
    switch (status) {
      case DownloadStatus.pending:
        return S.current.pending;
      case DownloadStatus.downloading:
        return S.current.downloading;
      case DownloadStatus.paused:
        return S.current.paused;
      case DownloadStatus.cancelling:
        return S.current.cancelling;
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
    if (bytes < 1024) {
      return '${bytes}B';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)}KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }
}

class _DownloadChangeNotifier extends ChangeNotifier {
  void emit() => notifyListeners();
}

class DownloadManager {
  static final Dio _dio = Dio();
  static final _DownloadChangeNotifier _changes = _DownloadChangeNotifier();
  static const String _historyKey = 'download_task_history.v1';
  static const String _downloadDirectoryKey = 'download_directory.v1';
  static const String _askForDownloadDirectoryKey =
      'ask_for_download_directory.v1';
  static const int _historyLimit = 100;
  static Future<void>? _historyLoading;
  static Future<void> _historyWrites = Future.value();
  static const _uiProgressInterval = Duration(milliseconds: 100);
  static const _systemProgressInterval = Duration(milliseconds: 250);
  static final Map<String, DownloadTask> _activeTasks = {};
  static final List<DownloadTask> _completedTasks = [];
  static final Set<String> _cancelledTaskIds = {};
  static final Set<String> _reservedFilePaths = {};
  static int _nextTaskId = 0;

  static void addListener(VoidCallback listener) =>
      _changes.addListener(listener);
  static void removeListener(VoidCallback listener) =>
      _changes.removeListener(listener);

  static Future<void> initialize() => _historyLoading ??= _loadHistory();

  static Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_historyKey);
      if (raw == null) return;
      final records = jsonDecode(raw) as List<dynamic>;
      _completedTasks
        ..clear()
        ..addAll(records
            .whereType<Map<String, dynamic>>()
            .map(DownloadTask.fromHistory)
            .whereType<DownloadTask>());
      _changes.emit();
    } catch (e) {
      log('Failed to load download history: $e');
    }
  }

  static void _notifyChanged({bool persistHistory = false}) {
    _changes.emit();
    if (persistHistory) {
      _historyWrites = _historyWrites.then((_) async {
        try {
          final prefs = await SharedPreferences.getInstance();
          final records = _completedTasks
              .take(_historyLimit)
              .map((task) => task.toHistory())
              .toList();
          await prefs.setString(_historyKey, jsonEncode(records));
        } catch (e) {
          log('Failed to save download history: $e');
        }
      });
    }
  }

  static List<DownloadTask> get activeTasks =>
      List.unmodifiable(_activeTasks.values);
  static List<DownloadTask> get completedTasks =>
      List.unmodifiable(_completedTasks);
  static List<DownloadTask> get allTasks =>
      [..._activeTasks.values, ..._completedTasks];

  static Future<bool> getAskForDownloadDirectory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_askForDownloadDirectoryKey) ?? false;
  }

  static Future<void> setAskForDownloadDirectory(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_askForDownloadDirectoryKey, enabled);
  }

  static Future<String?> getConfiguredDownloadDirectory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_downloadDirectoryKey);
  }

  static Future<Directory?> _prepareDownloadDirectory(String path) async {
    try {
      var directoryPath = path.trim();
      if (directoryPath.isEmpty) return null;
      if (Platform.isAndroid || Platform.isIOS) {
        final uri = Uri.tryParse(directoryPath);
        if (uri?.hasScheme == true && uri!.scheme != 'file') return null;
        if (uri?.scheme == 'file') directoryPath = uri!.toFilePath();
      }
      final dir = Directory(directoryPath);
      await dir.create(recursive: true);
      if (Platform.isAndroid) {
        final appDirectory = await getExternalStorageDirectory();
        final privatePath = appDirectory?.absolute.path;
        final selectedPath = dir.absolute.path;
        final isAppPrivate = privatePath != null &&
            (selectedPath == privatePath ||
                selectedPath
                    .startsWith('$privatePath${Platform.pathSeparator}'));
        if (!isAppPrivate) {
          var storageGranted = await Permission.storage.isGranted;
          var allFilesGranted =
              await Permission.manageExternalStorage.isGranted;
          if (!storageGranted && !allFilesGranted) {
            storageGranted = (await Permission.storage.request()).isGranted;
            if (!storageGranted) {
              allFilesGranted =
                  (await Permission.manageExternalStorage.request()).isGranted;
            }
          }
          if (!storageGranted && !allFilesGranted) return null;
        }
      }
      final probe = File(
          '${dir.path}${Platform.pathSeparator}.openlist-${DateTime.now().microsecondsSinceEpoch}.tmp');
      await probe.writeAsBytes(const [], flush: true);
      await probe.delete();
      return dir;
    } catch (error) {
      log('Download directory is not writable: $error');
      return null;
    }
  }

  static Future<bool> setDownloadDirectory(String path) async {
    if (path.trim().isEmpty) return false;
    final dir = await _prepareDownloadDirectory(path);
    if (dir == null) return false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_downloadDirectoryKey, dir.path);
    _notifyChanged();
    return true;
  }

  static Future<void> resetDownloadDirectory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_downloadDirectoryKey);
    _notifyChanged();
  }

  static Future<Directory?> _getDownloadDirectoryForTask() async {
    if (!await getAskForDownloadDirectory()) {
      final configured = await getConfiguredDownloadDirectory();
      return configured == null || configured.isEmpty
          ? _getOpenListDownloadDirectory()
          : _prepareDownloadDirectory(configured);
    }
    final path = await FilePicker.platform.getDirectoryPath(
      dialogTitle: S.current.downloadDirectory,
    );
    if (path == null || path.trim().isEmpty) return null;
    final directory = await _prepareDownloadDirectory(path);
    if (directory == null) {
      getx.Get.showSnackbar(getx.GetSnackBar(
        message: S.current.downloadDirectoryNotWritable,
        duration: const Duration(seconds: 4),
      ));
    }
    return directory;
  }

  /// Downloads a file into the selected download directory.
  static Future<bool> downloadFileWithProgress({
    required String url,
    String? filename,
    Map<String, String>? headers,
  }) async {
    await initialize();

    final taskId = '${DateTime.now().millisecondsSinceEpoch}-${_nextTaskId++}';
    final downloadDir = await _getDownloadDirectoryForTask();
    if (downloadDir == null) return false;
    var finalFilename = filename ?? _getFilenameFromUrl(url);
    final filePath = _getUniqueFilePath('${downloadDir.path}/$finalFilename');
    final partialFilePath = '$filePath.$taskId.part';
    _reservedFilePaths.add(filePath);
    finalFilename = filePath.split('/').last;
    final task = DownloadTask(
      id: taskId,
      url: url,
      filename: finalFilename,
      filePath: filePath,
      partialFilePath: partialFilePath,
    );
    _activeTasks[taskId] = task;
    _notifyChanged();

    getx.Get.showSnackbar(getx.GetSnackBar(
      message: S.current.startDownloadFile(finalFilename),
      duration: const Duration(seconds: 2),
      backgroundColor: Colors.green,
    ));

    try {
      task.status = DownloadStatus.downloading;
      _notifyChanged();
      unawaited(NotificationManager.showDownloadProgressNotification());
      await _runHttpDownload(task, headers ?? const {});
      if (_cancelledTaskIds.contains(taskId)) {
        throw const FileSystemException('Download cancelled');
      }

      await File(partialFilePath).rename(filePath);
      task
        ..status = DownloadStatus.completed
        ..endTime = DateTime.now()
        ..progress = 1.0;
      if (task.totalBytes == 0) task.totalBytes = task.receivedBytes;
      _activeTasks.remove(taskId);
      _completedTasks.insert(0, task);
      _notifyChanged(persistHistory: true);
      unawaited(NotificationManager.showSingleFileCompleteNotification(task));
      getx.Get.showSnackbar(getx.GetSnackBar(
        message: S.current.downloadCompleteFile(finalFilename),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.blue,
        mainButton: TextButton(
          onPressed: () => _openFile(filePath),
          child: Text(S.current.open),
        ),
      ));
      return true;
    } catch (error) {
      final cancelled = task.status == DownloadStatus.cancelling ||
          _cancelledTaskIds.contains(taskId);
      task
        ..status = cancelled ? DownloadStatus.cancelled : DownloadStatus.failed
        ..endTime = DateTime.now();
      if (!cancelled) {
        task.errorMessage = error is DioException
            ? 'Download failed (${error.type.name})'
            : 'Download failed (${error.runtimeType})';
        getx.Get.showSnackbar(getx.GetSnackBar(
          message: S.current.downloadFailedFile(finalFilename),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ));
      }
      await _deletePartialFile(partialFilePath);
      _activeTasks.remove(taskId);
      _completedTasks.insert(0, task);
      _notifyChanged(persistHistory: true);
      if (_activeTasks.isEmpty) {
        unawaited(NotificationManager.cancelDownloadNotification());
      } else {
        unawaited(NotificationManager.showDownloadProgressNotification());
      }
      return false;
    } finally {
      task.cancelToken = null;
      _cancelledTaskIds.remove(taskId);
      _reservedFilePaths.remove(filePath);
    }
  }

  static Future<void> _runHttpDownload(
      DownloadTask task, Map<String, String> headers) async {
    while (true) {
      await _waitForResume(task);
      final partial = File(task.partialFilePath!);
      if (task.totalBytes > 0 &&
          await partial.exists() &&
          await partial.length() == task.totalBytes) {
        task.receivedBytes = task.totalBytes;
        task.progress = 1;
        return;
      }
      await _waitForResume(task);
      final token = CancelToken();
      task.cancelToken = token;
      try {
        await _downloadHttpAttempt(task, headers, token);
        task.cancelToken = null;
        if (task.pauseRequested) {
          await _waitForResume(task);
          continue;
        }
        return;
      } catch (_) {
        task.cancelToken = null;
        if (!task.pauseRequested) rethrow;
        await _waitForResume(task);
      }
    }
  }

  static Future<void> _downloadHttpAttempt(
      DownloadTask task, Map<String, String> headers, CancelToken token) async {
    final partialFile = File(task.partialFilePath!);
    final offset = await partialFile.exists() ? await partialFile.length() : 0;
    final response = await _dio.get<ResponseBody>(
      task.url,
      cancelToken: token,
      options: Options(
        responseType: ResponseType.stream,
        headers: {
          ...headers,
          if (offset > 0) 'Range': 'bytes=$offset-',
        },
      ),
    );

    var writeOffset = offset;
    final status = response.statusCode ?? 0;
    if (offset > 0 && status == 200) {
      writeOffset = 0;
      task
        ..receivedBytes = 0
        ..progress = 0;
    } else if (status == 206) {
      final range = response.headers.value('content-range');
      final match = range == null
          ? null
          : RegExp(r'bytes (\d+)-\d+/', caseSensitive: false).firstMatch(range);
      if (match == null || int.parse(match.group(1)!) != offset) {
        throw const FormatException('Invalid partial download response');
      }
    } else if (status != 200) {
      throw HttpException('Unexpected download status: $status');
    }

    final contentLength =
        int.tryParse(response.headers.value(Headers.contentLengthHeader) ?? '');
    final range = response.headers.value('content-range');
    final rangeMatch = range == null
        ? null
        : RegExp(r'bytes \d+-\d+/(\d+)', caseSensitive: false)
            .firstMatch(range);
    final int? totalFromRange =
        rangeMatch == null ? null : int.tryParse(rangeMatch.group(1)!);
    task.totalBytes = totalFromRange ??
        (contentLength == null ? 0 : writeOffset + contentLength);
    task.receivedBytes = writeOffset;

    final output = await partialFile.open(
        mode: writeOffset > 0 ? FileMode.append : FileMode.write);
    try {
      await for (final chunk in response.data!.stream) {
        await output.writeFrom(chunk);
        task.receivedBytes += chunk.length;
        if (task.totalBytes > 0) {
          task.progress = task.receivedBytes / task.totalBytes;
        }
        _notifyDownloadProgress(task);
      }
    } finally {
      await output.flush();
      await output.close();
    }
    if (task.totalBytes > 0 && task.receivedBytes != task.totalBytes) {
      throw const FormatException('Incomplete download response');
    }
  }

  static void _notifyDownloadProgress(DownloadTask task) {
    final now = DateTime.now();
    final lastUi = task.lastUiProgressUpdate;
    if (lastUi == null || now.difference(lastUi) >= _uiProgressInterval) {
      task.lastUiProgressUpdate = now;
      _notifyChanged();
    }
    final lastSystem = task.lastSystemProgressUpdate;
    if (lastSystem == null ||
        now.difference(lastSystem) >= _systemProgressInterval) {
      task.lastSystemProgressUpdate = now;
      unawaited(NotificationManager.showDownloadProgressNotification());
    }
  }

  static Future<void> _waitForResume(DownloadTask task) async {
    if (task.pauseRequested) {
      final signal = task.resumeSignal;
      if (signal == null) return;
      if (!signal.isCompleted) {
        task.status = DownloadStatus.paused;
        _notifyChanged();
        await signal.future;
      }
      if (_cancelledTaskIds.contains(task.id)) {
        throw const FileSystemException('Download cancelled');
      }
      task
        ..pauseRequested = false
        ..resumeSignal = null
        ..status = DownloadStatus.downloading;
      _notifyChanged();
    }
    if (_cancelledTaskIds.contains(task.id)) {
      throw const FileSystemException('Download cancelled');
    }
  }

  static Future<void> _deletePartialFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (error) {
      log('Failed to remove partial download: $error');
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

  static Future<bool> saveFileInBackground({
    required String source,
    required int totalBytes,
    required Future<List<int>> Function(int offset) readChunk,
    String? filename,
  }) async {
    await initialize();
    if (Platform.isAndroid) {
      var storageStatus = await Permission.storage.status;
      var manageStorageStatus = await Permission.manageExternalStorage.status;
      if (!storageStatus.isGranted) {
        storageStatus = await Permission.storage.request();
      }
      if (!manageStorageStatus.isGranted) {
        manageStorageStatus = await Permission.manageExternalStorage.request();
      }
      if (!storageStatus.isGranted && !manageStorageStatus.isGranted) {
        getx.Get.showSnackbar(getx.GetSnackBar(
          message: S.current.grantStoragePermissionDesc,
          duration: const Duration(seconds: 5),
        ));
        return false;
      }
    }

    final taskId = '${DateTime.now().millisecondsSinceEpoch}-${_nextTaskId++}';
    final downloadDir = await _getDownloadDirectoryForTask();
    if (downloadDir == null) return false;

    var finalFilename = filename ?? _getFilenameFromUrl(source);
    var filePath = _getUniqueFilePath('${downloadDir.path}/$finalFilename');
    _reservedFilePaths.add(filePath);
    finalFilename = filePath.split('/').last;
    final temporaryFile = File('$filePath.$taskId.part');
    final task = DownloadTask(
      id: taskId,
      url: source,
      filename: finalFilename,
      filePath: filePath,
      partialFilePath: temporaryFile.path,
      totalBytes: totalBytes,
    );
    _activeTasks[taskId] = task;
    _notifyChanged();

    getx.Get.showSnackbar(getx.GetSnackBar(
      message: S.current.startDownloadFile(finalFilename),
      duration: const Duration(seconds: 2),
      backgroundColor: Colors.green,
    ));

    RandomAccessFile? output;
    try {
      task.status = DownloadStatus.downloading;
      _notifyChanged();
      unawaited(NotificationManager.showDownloadProgressNotification());

      output = await temporaryFile.open(mode: FileMode.write);
      while (task.receivedBytes < totalBytes) {
        await _waitForResume(task);
        final chunk = await readChunk(task.receivedBytes);
        await _waitForResume(task);
        if (task.status == DownloadStatus.paused) continue;
        if (chunk.isEmpty || task.receivedBytes + chunk.length > totalBytes) {
          throw const FormatException('Invalid Blob download data');
        }

        await output.writeFrom(chunk);
        task.receivedBytes += chunk.length;
        task.progress = totalBytes == 0 ? 1 : task.receivedBytes / totalBytes;
        _notifyDownloadProgress(task);
      }

      if (_cancelledTaskIds.contains(taskId)) {
        throw const FileSystemException('Download cancelled');
      }
      await output.close();
      output = null;
      if (_cancelledTaskIds.contains(taskId)) {
        throw const FileSystemException('Download cancelled');
      }
      await temporaryFile.rename(filePath);
      if (_cancelledTaskIds.contains(taskId)) {
        await File(filePath).delete();
        throw const FileSystemException('Download cancelled');
      }

      task.status = DownloadStatus.completed;
      task.endTime = DateTime.now();
      task.progress = 1.0;
      _activeTasks.remove(taskId);
      _completedTasks.insert(0, task);
      _notifyChanged(persistHistory: true);

      await NotificationManager.showSingleFileCompleteNotification(task);
      getx.Get.showSnackbar(getx.GetSnackBar(
        message: S.current.downloadCompleteFile(finalFilename),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.blue,
        mainButton: TextButton(
          onPressed: () => _openFile(filePath),
          child: Text(S.current.open),
        ),
      ));
      log('文件下载完成: $filePath');
      return true;
    } catch (error) {
      final cancelled = _cancelledTaskIds.contains(taskId);
      task.status =
          cancelled ? DownloadStatus.cancelled : DownloadStatus.failed;
      if (!cancelled) {
        task.errorMessage = error is DioException
            ? 'Download failed (${error.type.name})'
            : 'Download failed (${error.runtimeType})';
      }
      task.endTime = DateTime.now();
      _activeTasks.remove(taskId);
      _completedTasks.insert(0, task);
      _notifyChanged(persistHistory: true);

      try {
        await output?.close();
      } catch (closeError) {
        log('关闭临时下载文件失败: $closeError');
      }
      try {
        if (await temporaryFile.exists()) {
          await temporaryFile.delete();
        }
      } catch (deleteError) {
        log('删除临时下载文件失败: $deleteError');
      }

      if (task.status == DownloadStatus.failed) {
        log('下载失败: $error');
        getx.Get.showSnackbar(getx.GetSnackBar(
          message: S.current.downloadFailedFile(finalFilename),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ));
      }

      if (_activeTasks.isEmpty) {
        await NotificationManager.cancelDownloadNotification();
      } else {
        await NotificationManager.showDownloadProgressNotification();
      }
      return false;
    } finally {
      _cancelledTaskIds.remove(taskId);
      _reservedFilePaths.remove(filePath);
    }
  }

  static void pauseDownload(String taskId) {
    final task = _activeTasks[taskId];
    if (task == null || task.status != DownloadStatus.downloading) return;
    task
      ..pauseRequested = true
      ..resumeSignal = Completer<void>()
      ..status = DownloadStatus.paused;
    task.cancelToken?.cancel(S.current.userCancelledDownloadError);
    _notifyChanged();
  }

  static void resumeDownload(String taskId) {
    final task = _activeTasks[taskId];
    if (task == null || task.status != DownloadStatus.paused) return;
    task.status = DownloadStatus.downloading;
    final signal = task.resumeSignal;
    if (signal != null && !signal.isCompleted) signal.complete();
    _notifyChanged();
  }

  static void cancelDownload(String taskId) {
    final task = _activeTasks[taskId];
    if (task == null || task.status == DownloadStatus.cancelling) return;
    _cancelledTaskIds.add(taskId);
    task.status = DownloadStatus.cancelling;
    task.cancelToken?.cancel(S.current.userCancelledDownloadError);
    final signal = task.resumeSignal;
    if (signal != null && !signal.isCompleted) signal.complete();
    _notifyChanged();
  }

  /// 清除已完成的下载记录
  static void clearCompletedTasks() {
    _completedTasks.clear();
    _notifyChanged(persistHistory: true);
  }

  /// 删除下载任务记录
  static void removeTask(String taskId) {
    if (_activeTasks.containsKey(taskId)) {
      cancelDownload(taskId);
      return;
    }
    _completedTasks.removeWhere((task) => task.id == taskId);
    _notifyChanged(persistHistory: true);
  }

  /// 获取OpenList专用下载目录
  static Future<Directory?> _getOpenListDownloadDirectory() async {
    try {
      final configured = await getConfiguredDownloadDirectory();
      if (configured != null && configured.isNotEmpty) {
        final dir = Directory(configured);
        await dir.create(recursive: true);
        return dir;
      }
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
    if (!file.existsSync() && !_reservedFilePaths.contains(originalPath)) {
      return originalPath;
    }

    String directory = file.parent.path;
    String nameWithoutExtension = file.path.split('/').last.split('.').first;
    String extension =
        file.path.contains('.') ? '.${file.path.split('.').last}' : '';

    int counter = 1;
    String newPath;
    do {
      newPath = '$directory/${nameWithoutExtension}_$counter$extension';
      counter++;
    } while (
        File(newPath).existsSync() || _reservedFilePaths.contains(newPath));

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
        PermissionStatus status =
            await Permission.requestInstallPackages.request();

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

  static Future<String?> getDownloadDirectoryPath() async {
    final configured = await getConfiguredDownloadDirectory();
    if (configured != null && configured.isNotEmpty) return configured;
    return (await _getOpenListDownloadDirectory())?.path;
  }

  /// 列出已下载的文件
  static Future<List<FileSystemEntity>> getDownloadedFiles() async {
    try {
      final downloadDir = await _getOpenListDownloadDirectory();
      if (downloadDir != null && await downloadDir.exists()) {
        return await downloadDir.list(followLinks: false).toList();
      }
    } catch (e) {
      log('获取下载文件列表失败: $e');
    }
    return [];
  }

  static Future<bool> clearDownloadDirectory() async {
    try {
      final downloadDir = await _getOpenListDownloadDirectory();
      if (downloadDir != null && await downloadDir.exists()) {
        await downloadDir.delete(recursive: true);
        return true;
      }
    } catch (e) {
      log('清理下载目录失败: $e');
    }
    return false;
  }

  static Future<bool> deleteFile(String filename) async {
    final configured = await getConfiguredDownloadDirectory();
    final directory =
        configured ?? (await _getOpenListDownloadDirectory())?.path;
    if (directory == null) return false;
    return deleteFileAtPath('${directory}${Platform.pathSeparator}$filename');
  }

  static Future<bool> deleteFileAtPath(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        return true;
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
    if (bytes < 1024) {
      return '${bytes}B';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)}KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }
}
