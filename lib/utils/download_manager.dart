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
import 'package:open_file_manager/open_file_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_manager.dart';
import 'download_destination.dart';
import 'package:openlist_mobile/contant/native_bridge.dart';
import 'package:openlist_mobile/generated_api.dart';
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
  String filename;
  String filePath;
  final String? partialFilePath;
  final String? directoryReference;
  String? fileReference;
  DownloadDestination? destination;
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
  String? etag;
  String? lastModified;

  DownloadTask({
    required this.id,
    required this.url,
    required this.filename,
    required this.filePath,
    this.partialFilePath,
    this.directoryReference,
    this.fileReference,
    this.destination,
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
        if (directoryReference != null)
          'directoryReference': directoryReference,
        if (fileReference != null) 'fileReference': fileReference,
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
      final filename = data['filename'] as String;
      if (filename.isEmpty ||
          filename == '.' ||
          filename == '..' ||
          filename.contains(RegExp(r'[/\\\x00]'))) {
        return null;
      }
      return DownloadTask(
        id: data['id'] as String,
        url: '',
        filename: filename,
        filePath: '',
        directoryReference: data['directoryReference'] as String?,
        fileReference: data['fileReference'] as String?,
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
  static const String _downloadDirectoryNameKey = 'download_directory_name.v1';
  static const String _downloadDirectoryReferenceKey =
      'download_directory_reference.v1';
  static const String _askForDownloadDirectoryKey =
      'ask_for_download_directory.v1';
  static const String _directoryReferencesKey =
      'download_directory_references.v1';
  static const int _historyLimit = 100;
  static Future<void>? _historyLoading;
  static Future<void> _historyWrites = Future.value();
  static Future<void>? _directoryReferencesLoading;
  static Future<void> _directoryReferenceWrites = Future.value();
  static const _uiProgressInterval = Duration(milliseconds: 100);
  static const _systemProgressInterval = Duration(milliseconds: 250);
  static final Map<String, DownloadTask> _activeTasks = {};
  static final List<DownloadTask> _completedTasks = [];
  static final Set<String> _cancelledTaskIds = {};
  static final Set<String> _reservedFilePaths = {};
  static final Set<String> _removeWhenFinished = {};
  static final Map<String, String> _directoryReferences = {};
  static int _nextTaskId = 0;
  static int _nextDirectoryReference = 0;
  static int _filesVersion = 0;

  static int get filesVersion => _filesVersion;

  static void _showSnackbar(getx.GetSnackBar snackbar) {
    if (getx.Get.context != null) getx.Get.showSnackbar(snackbar);
  }

  static void addListener(VoidCallback listener) =>
      _changes.addListener(listener);
  static void removeListener(VoidCallback listener) =>
      _changes.removeListener(listener);

  static Future<void> _loadDirectoryReferences() {
    return _directoryReferencesLoading ??= () async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString(_directoryReferencesKey);
        if (raw == null) return;
        final values = jsonDecode(raw);
        if (values is! Map<String, dynamic>) return;
        for (final entry in values.entries) {
          if (entry.value is! String) continue;
          _directoryReferences[entry.key] = entry.value as String;
          final match = RegExp(r'^directory-(\d+)$').firstMatch(entry.key);
          final id = match == null ? null : int.tryParse(match.group(1)!);
          if (id != null && id >= _nextDirectoryReference) {
            _nextDirectoryReference = id + 1;
          }
        }
      } catch (error) {
        log('Failed to load download directory references: $error');
      }
    }();
  }

  static Future<String> _registerDirectoryReference(Directory directory) async {
    await _loadDirectoryReferences();
    final path = directory.absolute.path;
    for (final entry in _directoryReferences.entries) {
      if (entry.value == path) return entry.key;
    }
    final reference = 'directory-${_nextDirectoryReference++}';
    _directoryReferences[reference] = path;
    _directoryReferenceWrites = _directoryReferenceWrites.then((_) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            _directoryReferencesKey, jsonEncode(_directoryReferences));
      } catch (error) {
        log('Failed to save download directory reference: $error');
      }
    });
    await _directoryReferenceWrites;
    return reference;
  }

  static void _resolveHistoricalFilePaths() {
    for (final task in _completedTasks) {
      final directoryReference = task.directoryReference;
      final fileReference = task.fileReference;
      if (directoryReference != null && fileReference != null) {
        task.destination = NativeDownloadDestination(
          directoryReference: directoryReference,
          filename: task.filename,
          fileReference: fileReference,
        );
        continue;
      }
      final directory = directoryReference == null
          ? null
          : _directoryReferences[directoryReference];
      if (directory == null || directoryReference == null) continue;
      task.filePath =
          File('$directory${Platform.pathSeparator}${task.filename}').path;
      task.destination = PathDownloadDestination(
        directoryReference: directoryReference,
        filename: task.filename,
        filePath: task.filePath,
        partialFilePath: '${task.filePath}.history.part',
        finalized: true,
      );
    }
  }

  static Future<void> initialize() => _historyLoading ??= _loadHistory();

  static Future<void> _loadHistory() async {
    try {
      await _loadDirectoryReferences();
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
      _resolveHistoricalFilePaths();
      _changes.emit();
    } catch (e) {
      log('Failed to load download history: $e');
    }
  }

  static void _notifyChanged({
    bool persistHistory = false,
    bool filesChanged = false,
  }) {
    if (filesChanged) _filesVersion++;
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

  static bool get _usesNativeDownloadStorage =>
      Platform.isAndroid || Platform.isIOS;

  static Future<DownloadDirectoryTarget?> getDownloadDirectoryTarget() async {
    if (_usesNativeDownloadStorage) {
      final directory =
          await NativeBridge.downloadStorage.getDefaultDirectory();
      return DownloadDirectoryTarget.native(directory);
    }
    try {
      final configured = await getConfiguredDownloadDirectory();
      final directory = configured == null || configured.isEmpty
          ? await _getOpenListDownloadDirectory()
          : await _prepareDownloadDirectory(configured);
      return directory == null
          ? null
          : DownloadDirectoryTarget.path(
              reference: await _registerDirectoryReference(directory),
              directory: directory,
            );
    } catch (error) {
      log('Failed to get download directory: $error');
      return null;
    }
  }

  static Future<DownloadDirectoryTarget?> chooseDownloadDirectory() async {
    try {
      if (_usesNativeDownloadStorage) {
        final directory = await NativeBridge.downloadStorage.chooseDirectory();
        if (directory == null) return null;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            _downloadDirectoryReferenceKey, directory.reference);
        await prefs.setString(_downloadDirectoryNameKey, directory.name);
        await prefs.remove(_downloadDirectoryKey);
        _notifyChanged(filesChanged: true);
        return DownloadDirectoryTarget.native(directory);
      }
      final path = await FilePicker.platform.getDirectoryPath(
        dialogTitle: S.current.downloadDirectory,
      );
      if (path == null || path.trim().isEmpty) return null;
      final directory = await _prepareDownloadDirectory(path);
      if (directory == null) {
        _showSnackbar(getx.GetSnackBar(
          message: S.current.downloadDirectoryNotWritable,
          duration: const Duration(seconds: 4),
        ));
        return null;
      }
      return DownloadDirectoryTarget.path(
        reference: await _registerDirectoryReference(directory),
        directory: directory,
      );
    } catch (error) {
      log('Failed to choose download directory: $error');
      return null;
    }
  }

  static Future<DownloadDirectoryTarget?> _getDownloadTargetForTask() async {
    if (await getAskForDownloadDirectory()) {
      return chooseDownloadDirectory();
    }
    return getDownloadDirectoryTarget();
  }

  static Future<DownloadDestination> _reserveDestination(
      DownloadDirectoryTarget target, String filename, String taskId) async {
    if (target.isNative) {
      return NativeDownloadDestination.reserve(target.reference, filename);
    }
    final directory = target.directory!;
    final filePath = _getUniqueFilePath(
        '${directory.path}${Platform.pathSeparator}$filename');
    _reservedFilePaths.add(filePath);
    return PathDownloadDestination(
      directoryReference: target.reference,
      filename: _basename(filePath),
      filePath: filePath,
      partialFilePath: '$filePath.$taskId.part',
    );
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
    await _registerDirectoryReference(dir);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_downloadDirectoryKey, dir.path);
    _notifyChanged(filesChanged: true);
    return true;
  }

  static Future<void> resetDownloadDirectory() async {
    if (_usesNativeDownloadStorage) {
      await NativeBridge.downloadStorage.resetSelectedDirectory();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_downloadDirectoryKey);
    await prefs.remove(_downloadDirectoryReferenceKey);
    await prefs.remove(_downloadDirectoryNameKey);
    _notifyChanged(filesChanged: true);
  }

  /// Downloads a file into the selected download directory.
  static Future<bool> downloadFileWithProgress({
    required String url,
    String? filename,
    Map<String, String>? headers,
    Dio? client,
  }) async {
    await initialize();

    final taskId = '${DateTime.now().millisecondsSinceEpoch}-${_nextTaskId++}';
    final DownloadDirectoryTarget? target;
    try {
      target = await _getDownloadTargetForTask();
    } catch (error) {
      log('Failed to get download directory: $error');
      _showSnackbar(getx.GetSnackBar(
        message: '${S.current.error}: $error',
        duration: const Duration(seconds: 4),
      ));
      return false;
    }
    if (target == null) return false;
    final requestedFilename =
        _safeFilename(filename ?? _getFilenameFromUrl(url));

    late final DownloadDestination destination;
    try {
      destination =
          await _reserveDestination(target, requestedFilename, taskId);
    } catch (error) {
      log('Failed to reserve download file: $error');
      _showSnackbar(getx.GetSnackBar(
        message: S.current.downloadDirectoryNotWritable,
        duration: const Duration(seconds: 4),
      ));
      return false;
    }
    final task = DownloadTask(
      id: taskId,
      url: url,
      filename: destination.filename,
      filePath: destination.filePath ?? '',
      partialFilePath: destination.partialFilePath,
      directoryReference: destination.directoryReference,
      fileReference: destination.fileReference,
      destination: destination,
    );
    _activeTasks[taskId] = task;
    _notifyChanged();

    _showSnackbar(getx.GetSnackBar(
      message: S.current.startDownloadFile(task.filename),
      duration: const Duration(seconds: 2),
      backgroundColor: Colors.green,
    ));

    try {
      task.status = DownloadStatus.downloading;
      _notifyChanged();
      unawaited(NotificationManager.showDownloadProgressNotification());
      await _runHttpDownload(task, headers ?? const {}, client ?? _dio);
      if (_cancelledTaskIds.contains(taskId)) {
        throw const FileSystemException('Download cancelled');
      }

      await destination.finalize();
      if (_cancelledTaskIds.contains(taskId)) {
        await _discardDestination(destination);
        throw const FileSystemException('Download cancelled');
      }
      task
        ..filename = destination.filename
        ..filePath = destination.filePath ?? ''
        ..fileReference = destination.fileReference
        ..status = DownloadStatus.completed
        ..endTime = DateTime.now()
        ..progress = 1.0;
      if (task.totalBytes == 0) task.totalBytes = task.receivedBytes;
      _activeTasks.remove(taskId);
      if (!_removeWhenFinished.remove(taskId)) {
        _completedTasks.insert(0, task);
      }
      _notifyChanged(persistHistory: true, filesChanged: true);
      unawaited(NotificationManager.showSingleFileCompleteNotification(task));
      _showSnackbar(getx.GetSnackBar(
        message: S.current.downloadCompleteFile(task.filename),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.blue,
        mainButton: TextButton(
          onPressed: () => unawaited(_openTaskFile(task)),
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
        _showSnackbar(getx.GetSnackBar(
          message: S.current.downloadFailedFile(task.filename),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ));
      }
      await _discardDestination(destination);
      _activeTasks.remove(taskId);
      if (!_removeWhenFinished.remove(taskId)) {
        _completedTasks.insert(0, task);
      }
      _notifyChanged(persistHistory: true, filesChanged: true);
      if (_activeTasks.isEmpty) {
        unawaited(NotificationManager.cancelDownloadNotification());
      } else {
        unawaited(NotificationManager.showDownloadProgressNotification());
      }
      return false;
    } finally {
      task.cancelToken = null;
      _cancelledTaskIds.remove(taskId);
      _removeWhenFinished.remove(taskId);
      if (destination.filePath != null) {
        _reservedFilePaths.remove(destination.filePath);
      }
    }
  }

  static Future<void> _runHttpDownload(
      DownloadTask task, Map<String, String> headers, Dio client) async {
    while (true) {
      await _waitForResume(task);
      final token = CancelToken();
      task.cancelToken = token;
      try {
        await _downloadHttpAttempt(task, headers, token, client);
        await _waitForResume(task);
        return;
      } on DioException catch (error) {
        final pausedByUser = error.type == DioExceptionType.cancel &&
            token.isCancelled &&
            task.pauseRequested &&
            !_cancelledTaskIds.contains(task.id);
        if (!pausedByUser) rethrow;
      } finally {
        task.cancelToken = null;
      }
    }
  }

  static Future<void> _downloadHttpAttempt(DownloadTask task,
      Map<String, String> headers, CancelToken token, Dio client) async {
    final destination = task.destination!;
    var restarted = false;
    while (true) {
      await _waitForResume(task);
      final length = await destination.length();
      final strongEtag =
          task.etag != null && !task.etag!.startsWith('W/') ? task.etag : null;
      final validator = strongEtag ?? task.lastModified;
      final offset = validator == null ? 0 : length;
      final requestHeaders = Map<String, String>.from(headers)
        ..removeWhere((key, _) => const {'range', 'if-range', 'accept-encoding'}
            .contains(key.toLowerCase()))
        ..['Accept-Encoding'] = 'identity';
      if (offset > 0) {
        requestHeaders['Range'] = 'bytes=$offset-';
        requestHeaders['If-Range'] = validator!;
      }
      final requestToken = CancelToken();
      unawaited(token.whenCancel.then((_) => requestToken.cancel()));
      final response = await client.get<ResponseBody>(
        task.url,
        cancelToken: requestToken,
        options: Options(
          responseType: ResponseType.stream,
          headers: requestHeaders,
          validateStatus: (status) =>
              status == 200 || status == 206 || status == 416,
        ),
      );
      final input = StreamIterator(response.data!.stream);
      try {
        final status = response.statusCode!;
        final encoding =
            response.headers.value('content-encoding')?.toLowerCase();
        final encoded = encoding != null && encoding != 'identity';
        if (encoded && encoding != 'gzip') {
          throw const FormatException(
              'Unsupported compressed download response');
        }
        final responseEtag = response.headers.value('etag');
        final responseLastModified = response.headers.value('last-modified');
        final validatorChanged = strongEtag != null
            ? responseEtag != strongEtag
            : task.lastModified != null &&
                responseLastModified != task.lastModified;
        if (offset > 0 &&
            (status == 416 ||
                (status == 206 && (validatorChanged || encoded)))) {
          if (restarted) {
            throw const FormatException('Invalid partial download response');
          }
          await destination.truncate();
          task
            ..receivedBytes = 0
            ..totalBytes = 0
            ..progress = 0
            ..etag = null
            ..lastModified = null;
          restarted = true;
          continue;
        }

        int? total;
        var writeOffset = 0;
        if (status == 206 && !encoded) {
          final range = response.headers.value('content-range');
          final match = range == null
              ? null
              : RegExp(r'^bytes (\d+)-(\d+)/(\d+)$').firstMatch(range);
          if (match == null) {
            throw const FormatException('Invalid partial download response');
          }
          final start = int.parse(match.group(1)!);
          final end = int.parse(match.group(2)!);
          total = int.parse(match.group(3)!);
          if (start != offset || end < start || end != total - 1) {
            throw const FormatException('Invalid partial download response');
          }
          writeOffset = offset;
        } else if (status != 200) {
          throw const FormatException('Unexpected download response');
        }
        if (!encoded) {
          total ??= int.tryParse(
              response.headers.value(Headers.contentLengthHeader) ?? '');
        }
        if (writeOffset == 0) await destination.truncate();
        task
          ..etag = encoded ? null : responseEtag
          ..lastModified = encoded ? null : responseLastModified
          ..totalBytes = total ?? 0
          ..receivedBytes = writeOffset
          ..progress = total == null || total == 0 ? 0 : writeOffset / total;
        while (await input.moveNext()) {
          final chunk = input.current;
          await destination.write(writeOffset, chunk);
          writeOffset += chunk.length;
          task.receivedBytes = writeOffset;
          if (task.totalBytes > 0) {
            task.progress =
                (task.receivedBytes / task.totalBytes).clamp(0.0, 1.0);
          }
          _notifyDownloadProgress(task);
        }
        await destination.flush();
        if (total != null && task.receivedBytes != total) {
          throw const FormatException('Incomplete download response');
        }
        return;
      } finally {
        await input.cancel();
        requestToken.cancel();
      }
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

  static Future<void> _discardDestination(
      DownloadDestination destination) async {
    try {
      await destination.discard();
    } catch (error) {
      log('Failed to discard download target: $error');
    }
  }

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

    final taskId = '${DateTime.now().millisecondsSinceEpoch}-${_nextTaskId++}';
    final DownloadDirectoryTarget? target;
    try {
      target = await _getDownloadTargetForTask();
    } catch (error) {
      log('Failed to get download directory: $error');
      _showSnackbar(getx.GetSnackBar(
        message: '${S.current.error}: $error',
        duration: const Duration(seconds: 4),
      ));
      return false;
    }
    if (target == null) return false;
    final requestedFilename =
        _safeFilename(filename ?? _getFilenameFromUrl(source));
    late final DownloadDestination destination;
    try {
      destination =
          await _reserveDestination(target, requestedFilename, taskId);
    } catch (error) {
      log('Failed to reserve Blob download file: $error');
      _showSnackbar(getx.GetSnackBar(
        message: S.current.downloadDirectoryNotWritable,
        duration: const Duration(seconds: 4),
      ));
      return false;
    }
    final task = DownloadTask(
      id: taskId,
      url: source,
      filename: destination.filename,
      filePath: destination.filePath ?? '',
      partialFilePath: destination.partialFilePath,
      directoryReference: destination.directoryReference,
      fileReference: destination.fileReference,
      destination: destination,
      totalBytes: totalBytes,
    );
    _activeTasks[taskId] = task;
    _notifyChanged();

    _showSnackbar(getx.GetSnackBar(
      message: S.current.startDownloadFile(task.filename),
      duration: const Duration(seconds: 2),
      backgroundColor: Colors.green,
    ));

    try {
      task.status = DownloadStatus.downloading;
      _notifyChanged();
      unawaited(NotificationManager.showDownloadProgressNotification());

      await destination.truncate();
      while (task.receivedBytes < totalBytes) {
        await _waitForResume(task);
        final chunk = await readChunk(task.receivedBytes);
        await _waitForResume(task);
        if (task.status == DownloadStatus.paused) continue;
        if (chunk.isEmpty || task.receivedBytes + chunk.length > totalBytes) {
          throw const FormatException('Invalid Blob download data');
        }

        await destination.write(task.receivedBytes, chunk);
        task.receivedBytes += chunk.length;
        task.progress = totalBytes == 0 ? 1 : task.receivedBytes / totalBytes;
        _notifyDownloadProgress(task);
      }

      if (_cancelledTaskIds.contains(taskId)) {
        throw const FileSystemException('Download cancelled');
      }
      await destination.flush();
      if (_cancelledTaskIds.contains(taskId)) {
        throw const FileSystemException('Download cancelled');
      }
      await destination.finalize();
      if (_cancelledTaskIds.contains(taskId)) {
        await _discardDestination(destination);
        throw const FileSystemException('Download cancelled');
      }

      task
        ..filename = destination.filename
        ..filePath = destination.filePath ?? ''
        ..fileReference = destination.fileReference
        ..status = DownloadStatus.completed
        ..endTime = DateTime.now()
        ..progress = 1.0;
      _activeTasks.remove(taskId);
      if (!_removeWhenFinished.remove(taskId)) {
        _completedTasks.insert(0, task);
      }
      _notifyChanged(persistHistory: true, filesChanged: true);

      await NotificationManager.showSingleFileCompleteNotification(task);
      _showSnackbar(getx.GetSnackBar(
        message: S.current.downloadCompleteFile(task.filename),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.blue,
        mainButton: TextButton(
          onPressed: () => unawaited(_openTaskFile(task)),
          child: Text(S.current.open),
        ),
      ));
      log('文件下载完成: ${task.filename}');
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
      await _discardDestination(destination);
      _activeTasks.remove(taskId);
      if (!_removeWhenFinished.remove(taskId)) {
        _completedTasks.insert(0, task);
      }
      _notifyChanged(persistHistory: true, filesChanged: true);

      if (task.status == DownloadStatus.failed) {
        log('下载失败: $error');
        _showSnackbar(getx.GetSnackBar(
          message: S.current.downloadFailedFile(task.filename),
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
      _removeWhenFinished.remove(taskId);
      if (destination.filePath != null) {
        _reservedFilePaths.remove(destination.filePath);
      }
    }
  }

  static void pauseDownload(String taskId) {
    final task = _activeTasks[taskId];
    if (task == null ||
        task.status != DownloadStatus.downloading ||
        task.pauseRequested) {
      return;
    }
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
      _removeWhenFinished.add(taskId);
      cancelDownload(taskId);
      return;
    }
    _completedTasks.removeWhere((task) => task.id == taskId);
    _notifyChanged(persistHistory: true);
  }

  static Future<void> retryDownload(String taskId) async {
    await initialize();
    final index = _completedTasks.indexWhere((task) => task.id == taskId);
    if (index < 0) return;
    final task = _completedTasks[index];
    if (task.status != DownloadStatus.failed &&
        task.status != DownloadStatus.cancelled) {
      return;
    }
    if (task.url.isEmpty) return;
    _completedTasks.removeAt(index);
    _notifyChanged(persistHistory: true);
    await downloadFileWithProgress(url: task.url, filename: task.filename);
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

  static String _basename(String path) =>
      path.replaceAll('\\', '/').split('/').last;

  static String _safeFilename(String name) {
    final filename = _basename(name).replaceAll(RegExp(r'[\x00-\x1f]'), '_');
    if (filename.isEmpty || filename == '.' || filename == '..') {
      return 'download_${DateTime.now().millisecondsSinceEpoch}';
    }
    return filename;
  }

  static String _getUniqueFilePath(String originalPath) {
    final file = File(originalPath);
    if (!file.existsSync() && !_reservedFilePaths.contains(originalPath)) {
      return originalPath;
    }

    final directory = file.parent.path;
    final filename = _basename(file.path);
    final extensionIndex = filename.lastIndexOf('.');
    final name =
        extensionIndex > 0 ? filename.substring(0, extensionIndex) : filename;
    final extension =
        extensionIndex > 0 ? filename.substring(extensionIndex) : '';
    var counter = 1;
    String newPath;
    do {
      newPath =
          '$directory${Platform.pathSeparator}${name}_${counter++}$extension';
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
          _showSnackbar(getx.GetSnackBar(
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

  static Future<bool> _openTaskFile(DownloadTask task) async {
    final destination = task.destination;
    if (destination != null && destination.fileReference != null) {
      return destination.open();
    }
    if (task.filePath.isEmpty) return false;
    await _openFile(task.filePath);
    return true;
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
            _showSnackbar(getx.GetSnackBar(
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
            _showSnackbar(getx.GetSnackBar(
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
          _showSnackbar(getx.GetSnackBar(
            message: S.current.fileNotFound,
            duration: const Duration(seconds: 3),
          ));
          break;
        case ResultType.permissionDenied:
          if (_isApkFile(filePath)) {
            _showSnackbar(getx.GetSnackBar(
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
            _showSnackbar(getx.GetSnackBar(
              message: S.current.noPermissionToOpenFile,
              duration: const Duration(seconds: 3),
            ));
          }
          break;
        case ResultType.error:
          _showSnackbar(getx.GetSnackBar(
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
      _showSnackbar(getx.GetSnackBar(
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

  static Future<DownloadFile?> getDownloadFileForTask(DownloadTask task) async {
    final destination = task.destination;
    if (destination != null) return destination.stat();
    if (task.filePath.isEmpty) return null;
    return _statPathFile(
      task.filePath,
      task.directoryReference ?? '',
      task.filename,
    );
  }

  static Future<DownloadFile?> _statPathFile(
      String path, String directoryReference, String filename) async {
    final file = File(path);
    if (!await file.exists()) return null;
    final stat = await file.stat();
    if (stat.type != FileSystemEntityType.file) return null;
    return DownloadFile(
      reference: file.path,
      directoryReference: directoryReference,
      name: filename,
      size: stat.size,
      modifiedAt: stat.modified.millisecondsSinceEpoch,
      mimeType: null,
    );
  }

  static Future<List<DownloadFile>> getDownloadedFileMetadata() async {
    await initialize();
    final files = <DownloadFile>[];
    final seen = <String>{};
    final directoryReferences = <String>{
      for (final task in _completedTasks)
        if (task.directoryReference != null) task.directoryReference!,
    };
    DownloadDirectoryTarget? currentTarget;
    try {
      currentTarget = await getDownloadDirectoryTarget();
      if (currentTarget != null) {
        directoryReferences.add(currentTarget.reference);
      }
    } catch (error) {
      log('Failed to get current download directory: $error');
    }

    if (_usesNativeDownloadStorage) {
      for (final reference in directoryReferences) {
        try {
          for (final file
              in await NativeBridge.downloadStorage.listFiles(reference)) {
            if (seen.add(file.reference)) files.add(file);
          }
        } catch (error) {
          log('Failed to list native download files: $error');
        }
      }
      return files;
    }

    final directories = <String, String>{
      for (final entry in _directoryReferences.entries) entry.value: entry.key,
    };
    if (currentTarget?.directory != null) {
      directories[currentTarget!.directory!.path] = currentTarget.reference;
    }
    for (final entry in directories.entries) {
      final directory = Directory(entry.key);
      if (!await directory.exists()) continue;
      try {
        await for (final entity in directory.list(followLinks: false)) {
          if (entity is! File ||
              entity.path.split(Platform.pathSeparator).last.startsWith('.') ||
              entity.path.endsWith('.part')) {
            continue;
          }
          final name = _basename(entity.path);
          final file = await _statPathFile(entity.path, entry.value, name);
          if (file != null && seen.add(file.reference)) files.add(file);
        }
      } catch (error) {
        log('Failed to list download files: $error');
      }
    }
    return files;
  }

  static Future<bool> openDownloadedFile(DownloadFile file) async {
    if (_usesNativeDownloadStorage) {
      return NativeBridge.downloadStorage.openFile(file.reference);
    }
    await _openFile(file.reference);
    return true;
  }

  static Future<bool> openDownloadedFileLocation(DownloadFile file) async {
    if (_usesNativeDownloadStorage) {
      return NativeBridge.downloadStorage
          .openDirectory(file.directoryReference);
    }
    final directory = File(file.reference).parent.path;
    await openFileManager(
      androidConfig: AndroidConfig(
        folderType: AndroidFolderType.other,
        folderPath: directory,
      ),
      iosConfig: IosConfig(folderPath: directory),
    );
    return true;
  }

  static Future<bool> openDownloadDirectory() async {
    try {
      final target = await getDownloadDirectoryTarget();
      if (target == null) return false;
      if (target.isNative) {
        return NativeBridge.downloadStorage.openDirectory(target.reference);
      }
      final directory = target.directory!;
      await openFileManager(
        androidConfig: AndroidConfig(
          folderType: AndroidFolderType.other,
          folderPath: directory.path,
        ),
        iosConfig: IosConfig(folderPath: directory.path),
      );
      return true;
    } catch (error) {
      log('Failed to open download directory: $error');
      return false;
    }
  }

  static Future<bool> deleteDownloadedFile(DownloadFile file) async {
    try {
      if (_usesNativeDownloadStorage) {
        await NativeBridge.downloadStorage.deleteFile(file.reference);
      } else {
        final localFile = File(file.reference);
        if (await localFile.exists()) await localFile.delete();
      }
      _notifyChanged(filesChanged: true);
      return true;
    } catch (error) {
      log('Failed to delete download file: $error');
      return false;
    }
  }

  /// 列出已下载的文件
  static Future<List<FileSystemEntity>> getDownloadedFiles() async {
    final files = <FileSystemEntity>[];
    try {
      await _loadDirectoryReferences();
      final paths = <String>{
        ..._directoryReferences.values,
      };
      final currentDirectory = await _getOpenListDownloadDirectory();
      if (currentDirectory != null) paths.add(currentDirectory.path);
      for (final path in paths) {
        final directory = Directory(path);
        if (!await directory.exists()) continue;
        try {
          files.addAll(await directory.list(followLinks: false).toList());
        } catch (error) {
          log('获取下载文件列表失败: $error');
        }
      }
    } catch (e) {
      log('获取下载文件列表失败: $e');
    }
    return files;
  }

  static Future<bool> clearDownloadDirectory() async {
    if (_activeTasks.isNotEmpty) return false;
    await initialize();
    try {
      final target = await getDownloadDirectoryTarget();
      if (target == null || _activeTasks.isNotEmpty) return false;
      if (target.isNative) {
        await NativeBridge.downloadStorage.clearDirectory(target.reference);
      } else {
        final directory = target.directory!;
        if (await directory.exists()) {
          await for (final entity in directory.list(followLinks: false)) {
            if (entity is File) await entity.delete();
          }
        }
      }
      _completedTasks
          .removeWhere((task) => task.directoryReference == target.reference);
      _notifyChanged(persistHistory: true, filesChanged: true);
      return true;
    } catch (error) {
      log('Failed to clear download directory: $error');
      return false;
    }
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
        _notifyChanged(filesChanged: true);
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
