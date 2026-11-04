import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_file_manager/open_file_manager.dart';
import 'package:open_filex/open_filex.dart';
import 'package:openlist_mobile/api/upload_queue.dart';
import 'package:openlist_mobile/design/theme.dart';
import 'package:openlist_mobile/generated/l10n.dart';
import 'package:openlist_mobile/utils/download_manager.dart';

/// Transfers screen showing uploads and downloads
class TransfersScreen extends StatefulWidget {
  const TransfersScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<TransfersScreen> createState() => _TransfersScreenState();
}

class _TransfersScreenState extends State<TransfersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _uploadQueue = UploadQueue.instance;
  final _downloadsKey = GlobalKey<_DownloadsTabState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _tabController.addListener(_onTabChanged);
    _uploadQueue.addListener(_onQueueUpdate);
    DownloadManager.addListener(_onQueueUpdate);
    unawaited(DownloadManager.initialize());
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _uploadQueue.removeListener(_onQueueUpdate);
    DownloadManager.removeListener(_onQueueUpdate);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (mounted) setState(() {});
  }

  void _onQueueUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.current.transfers),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: S.current.uploads),
            Tab(text: S.current.downloads),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'pause_all':
                  // Pause is handled per-item
                  Get.snackbar(
                      S.current.info, S.current.pauseIndividualTransfers);
                  break;
                case 'resume_all':
                  // Resume all failed/canceled uploads
                  for (final job in _uploadQueue.jobs) {
                    if (job.state == UploadState.failed ||
                        job.state == UploadState.canceled) {
                      _uploadQueue.retry(job);
                    }
                  }
                  break;
                case 'clear_completed':
                  _uploadQueue.clearFinished();
                  DownloadManager.clearCompletedTasks();
                  _downloadsKey.currentState?._refreshFiles();
                  break;
                case 'open_download_directory':
                  _downloadsKey.currentState?._openDownloadDirectory();
                  break;
                case 'clear_download_files':
                  _downloadsKey.currentState?._clearDownloadFiles();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                  value: 'resume_all', child: Text(S.current.retryFailed)),
              PopupMenuItem(
                  value: 'clear_completed',
                  child: Text(S.current.clearRecords)),
              if (_tabController.index == 1) ...[
                PopupMenuItem(
                    value: 'open_download_directory',
                    child: Text(S.current.openDirectory)),
                PopupMenuItem(
                    value: 'clear_download_files',
                    child: Text(S.current.clearAll)),
              ],
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _UploadsTab(uploadQueue: _uploadQueue),
          _DownloadsTab(key: _downloadsKey),
        ],
      ),
    );
  }
}

class _UploadsTab extends StatelessWidget {
  const _UploadsTab({required this.uploadQueue});

  final UploadQueue uploadQueue;

  @override
  Widget build(BuildContext context) {
    final jobs = uploadQueue.jobs;
    final hasUploads = jobs.isNotEmpty;

    if (!hasUploads) {
      return _EmptyView(
        icon: Icons.upload,
        message: S.current.noUploads,
        description: S.current.uploadFilesFromFilesScreen,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppDesign.space16),
      itemCount: jobs.length,
      itemBuilder: (context, index) {
        final job = jobs[index];
        return _TransferCard(
          key: ValueKey(job),
          name: job.name,
          progress: job.progress,
          detail: _formatDetail(job),
          status: _formatStatus(job),
          type: _TransferType.upload,
          state: job.state,
          onPause: () {
            uploadQueue.cancel(job);
          },
          onResume: () {
            uploadQueue.retry(job);
          },
          onCancel: () {
            if (job.isFinished) {
              uploadQueue.remove(job);
            } else {
              uploadQueue.cancel(job);
            }
          },
        );
      },
    );
  }

  String _formatDetail(UploadJob job) {
    final error = job.error?.toString();
    return [job.dir, if (error != null) error].join(' · ');
  }

  String _formatStatus(UploadJob job) {
    switch (job.state) {
      case UploadState.queued:
        return S.current.waiting;
      case UploadState.running:
        final progress = job.progress;
        return progress == null
            ? S.current.uploading
            : '${(progress * 100).toStringAsFixed(0)}%';
      case UploadState.paused:
        return S.current.paused;
      case UploadState.cancelling:
        return S.current.cancelling;
      case UploadState.succeeded:
        return S.current.completed;
      case UploadState.failed:
        return S.current.failed;
      case UploadState.canceled:
        return S.current.canceled;
    }
  }
}

class _DownloadsTab extends StatefulWidget {
  const _DownloadsTab({super.key});

  @override
  State<_DownloadsTab> createState() => _DownloadsTabState();
}

class _DownloadsTabState extends State<_DownloadsTab> {
  List<FileSystemEntity> _files = [];
  Map<String, FileStat?> _fileStats = {};
  bool _loadingFiles = true;

  @override
  void initState() {
    super.initState();
    _refreshFiles();
  }

  Future<void> _refreshFiles() async {
    setState(() => _loadingFiles = true);
    final files = await DownloadManager.getDownloadedFiles();
    final stats = <String, FileStat?>{};
    for (final file in files) {
      try {
        stats[file.path] = await file.stat();
      } on FileSystemException {
        stats[file.path] = null;
      }
    }
    if (!mounted) return;
    setState(() {
      _files = files;
      _fileStats = stats;
      _loadingFiles = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tasks = DownloadManager.allTasks;
    final active = tasks
        .where((task) =>
            task.status == DownloadStatus.pending ||
            task.status == DownloadStatus.downloading ||
            task.status == DownloadStatus.paused ||
            task.status == DownloadStatus.cancelling)
        .toList();
    final completed = tasks.where((task) => !active.contains(task)).toList();
    final trackedPaths = tasks.map((task) => task.filePath).toSet();
    final trackedNames = tasks
        .where((task) => task.status == DownloadStatus.completed)
        .map((task) => task.filename)
        .toSet();
    final untrackedFiles = _files
        .where((file) =>
            file is File &&
            !file.path.endsWith('.part') &&
            !trackedPaths.contains(file.path) &&
            !trackedNames
                .contains(file.path.split(Platform.pathSeparator).last))
        .toList();

    if (tasks.isEmpty && untrackedFiles.isEmpty && !_loadingFiles) {
      return _EmptyView(
        icon: Icons.download,
        message: S.current.noDownloads,
        description: S.current.downloadedFilesWillAppearHere,
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshFiles,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: AppDesign.space16),
        children: [
          if (_loadingFiles && tasks.isEmpty) const LinearProgressIndicator(),
          if (active.isNotEmpty) ...[
            _DownloadSectionHeader(
              title: '${S.current.inProgress} (${active.length})',
            ),
            for (final task in active) _downloadTaskCard(task),
          ],
          if (completed.isNotEmpty || untrackedFiles.isNotEmpty) ...[
            _DownloadSectionHeader(
              title:
                  '${S.current.completed} (${completed.length + untrackedFiles.length})',
            ),
            for (final task in completed) _downloadTaskCard(task),
            for (final file in untrackedFiles)
              _DownloadedFileTile(
                file: file,
                stat: _fileStats[file.path],
                onChanged: _refreshFiles,
              ),
          ],
          if (tasks.isEmpty && untrackedFiles.isEmpty)
            const SizedBox(height: 420),
        ],
      ),
    );
  }

  Widget _downloadTaskCard(DownloadTask task) {
    final matchingFiles = _files.where((file) =>
        file.path.split(Platform.pathSeparator).last == task.filename);
    final filePath = task.filePath.isNotEmpty
        ? task.filePath
        : matchingFiles.isEmpty
            ? null
            : matchingFiles.first.path;
    final state = switch (task.status) {
      DownloadStatus.pending => UploadState.queued,
      DownloadStatus.downloading => UploadState.running,
      DownloadStatus.paused => UploadState.paused,
      DownloadStatus.cancelling => UploadState.cancelling,
      DownloadStatus.completed => UploadState.succeeded,
      DownloadStatus.failed => UploadState.failed,
      DownloadStatus.cancelled => UploadState.canceled,
    };
    return _TransferCard(
      key: ValueKey('download-${task.id}'),
      name: task.filename,
      icon: _downloadFileIcon(task.filename),
      progress: task.totalBytes > 0 ? task.progress : null,
      detail: [
        task.progressText,
        _formatDateTime(task.startTime),
        if (task.endTime != null) _formatDateTime(task.endTime!),
        task.errorMessage,
      ].where((value) => value != null && value.isNotEmpty).join(' · '),
      status: task.statusText,
      type: _TransferType.download,
      state: state,
      canRetry: false,
      onPause: () => DownloadManager.pauseDownload(task.id),
      onResume: () => DownloadManager.resumeDownload(task.id),
      onCancel: state == UploadState.running || state == UploadState.paused
          ? () => DownloadManager.cancelDownload(task.id)
          : () => DownloadManager.removeTask(task.id),
      trailing: PopupMenuButton<String>(
        onSelected: (value) => _handleTaskAction(task, filePath, value),
        itemBuilder: (context) => [
          if (filePath != null && task.status == DownloadStatus.completed)
            PopupMenuItem(value: 'open', child: Text(S.current.openFile)),
          if (filePath != null && task.status == DownloadStatus.completed)
            PopupMenuItem(
                value: 'location', child: Text(S.current.showInFileManager)),
          if (filePath != null && task.status == DownloadStatus.completed)
            PopupMenuItem(value: 'info', child: Text(S.current.fileInfo)),
          if (filePath != null && task.status == DownloadStatus.completed)
            PopupMenuItem(
                value: 'delete_file', child: Text(S.current.deleteFile)),
          PopupMenuItem(
              value: 'delete_record', child: Text(S.current.deleteRecord)),
        ],
      ),
    );
  }

  Future<void> _handleTaskAction(
      DownloadTask task, String? filePath, String action) async {
    switch (action) {
      case 'open':
        if (filePath != null) await OpenFilex.open(filePath);
      case 'location':
        if (filePath != null) await _openFileManager(filePath);
      case 'info':
        if (filePath != null) await _showFileInfo(filePath);
      case 'delete_file':
        if (filePath != null &&
            await _confirm(S.current.confirmDelete,
                S.current.confirmDeleteFile(task.filename))) {
          await DownloadManager.deleteFileAtPath(filePath);
          await _refreshFiles();
        }
      case 'delete_record':
        DownloadManager.removeTask(task.id);
    }
  }

  Future<bool> _confirm(String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(S.current.cancel)),
              FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(S.current.confirm)),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _showFileInfo(String path) async {
    final stat = await File(path).stat();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.current.fileInfo),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                '${S.current.fileName}: ${path.split(Platform.pathSeparator).last}'),
            Text('${S.current.size}: ${_formatFileSize(stat.size)}'),
            Text(
                '${S.current.modifiedTime}: ${_formatDateTime(stat.modified)}'),
            SelectableText('${S.current.filePath}: $path'),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(S.current.ok)),
        ],
      ),
    );
  }

  Future<void> _openDownloadDirectory() async {
    final path = await DownloadManager.getDownloadDirectoryPath();
    if (path == null || !mounted) return;
    await openFileManager(
      androidConfig: AndroidConfig(
        folderType: AndroidFolderType.other,
        folderPath: path,
      ),
      iosConfig: IosConfig(folderPath: path),
    );
  }

  Future<void> _clearDownloadFiles() async {
    if (!await _confirm(S.current.confirmClear, S.current.confirmClearAllFiles))
      return;
    final cleared = await DownloadManager.clearDownloadDirectory();
    if (!cleared || !mounted) return;
    DownloadManager.clearCompletedTasks();
    await _refreshFiles();
  }

  Future<void> _openFileManager(String path) async {
    final directory = File(path).parent.path;
    await openFileManager(
      androidConfig: AndroidConfig(
        folderType: AndroidFolderType.other,
        folderPath: directory,
      ),
      iosConfig: IosConfig(folderPath: directory),
    );
  }
}

IconData _downloadFileIcon(String filename) {
  final extension =
      filename.contains('.') ? filename.split('.').last.toLowerCase() : '';
  return switch (extension) {
    'pdf' => Icons.picture_as_pdf,
    'jpg' || 'jpeg' || 'png' || 'gif' => Icons.image,
    'mp4' || 'avi' || 'mkv' => Icons.video_file,
    'mp3' || 'wav' => Icons.audio_file,
    'zip' || 'rar' || '7z' => Icons.archive,
    'doc' || 'docx' => Icons.description,
    'xls' || 'xlsx' => Icons.table_chart,
    'apk' => Icons.android,
    _ => Icons.insert_drive_file,
  };
}

class _DownloadSectionHeader extends StatelessWidget {
  const _DownloadSectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
      );
}

class _DownloadedFileTile extends StatelessWidget {
  const _DownloadedFileTile({
    required this.file,
    required this.stat,
    required this.onChanged,
  });

  final FileSystemEntity file;
  final FileStat? stat;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context) {
    final filename = file.path.split(Platform.pathSeparator).last;
    final extension =
        filename.contains('.') ? filename.split('.').last.toLowerCase() : '';
    final icon = switch (extension) {
      'pdf' => Icons.picture_as_pdf,
      'jpg' || 'jpeg' || 'png' || 'gif' => Icons.image,
      'mp4' || 'avi' || 'mkv' => Icons.video_file,
      'mp3' || 'wav' => Icons.audio_file,
      'zip' || 'rar' || '7z' => Icons.archive,
      'apk' => Icons.android,
      _ => Icons.insert_drive_file,
    };
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(icon),
        title: Text(filename, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: stat == null
            ? null
            : Text(
                '${_formatFileSize(stat!.size)} · ${_formatDateTime(stat!.modified)}'),
        onTap: () => OpenFilex.open(file.path),
        trailing: PopupMenuButton<String>(
          onSelected: (action) async {
            switch (action) {
              case 'open':
                await OpenFilex.open(file.path);
              case 'location':
                final directory = file.parent.path;
                await openFileManager(
                  androidConfig: AndroidConfig(
                    folderType: AndroidFolderType.other,
                    folderPath: directory,
                  ),
                  iosConfig: IosConfig(folderPath: directory),
                );
              case 'info':
                final refreshedStat = await file.stat();
                if (!context.mounted) return;
                await showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(S.current.fileInfo),
                    content: Text(
                      '${S.current.fileName}: $filename\n'
                      '${S.current.size}: ${_formatFileSize(refreshedStat.size)}\n'
                      '${S.current.modifiedTime}: ${_formatDateTime(refreshedStat.modified)}\n'
                      '${S.current.filePath}: ${file.path}',
                    ),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(S.current.ok)),
                    ],
                  ),
                );
              case 'delete':
                final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(S.current.confirmDelete),
                        content: Text(S.current.confirmDeleteFile(filename)),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text(S.current.cancel)),
                          FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text(S.current.delete)),
                        ],
                      ),
                    ) ??
                    false;
                if (confirmed) {
                  await DownloadManager.deleteFileAtPath(file.path);
                  await onChanged();
                }
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(value: 'open', child: Text(S.current.openFile)),
            PopupMenuItem(
                value: 'location', child: Text(S.current.showInFileManager)),
            PopupMenuItem(value: 'info', child: Text(S.current.fileInfo)),
            PopupMenuItem(value: 'delete', child: Text(S.current.deleteFile)),
          ],
        ),
      ),
    );
  }
}

String _formatDateTime(DateTime dateTime) =>
    '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
    '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

String _formatFileSize(int bytes) {
  if (bytes < 1024) return '${bytes}B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
  if (bytes < 1024 * 1024 * 1024)
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({
    required this.icon,
    required this.message,
    required this.description,
  });

  final IconData icon;
  final String message;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDesign.space32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppDesign.space24),
            Text(
              message,
              style: AppDesign.headline3,
            ),
            const SizedBox(height: AppDesign.space12),
            Text(
              description,
              style: AppDesign.body2,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

enum _TransferType { upload, download }

class _TransferCard extends StatelessWidget {
  const _TransferCard({
    super.key,
    required this.name,
    this.icon,
    required this.progress,
    required this.detail,
    required this.status,
    required this.type,
    required this.state,
    this.canRetry = true,
    this.trailing,
    required this.onPause,
    required this.onResume,
    required this.onCancel,
  });

  final String name;
  final IconData? icon;
  final double? progress;
  final String detail;
  final String status;
  final _TransferType type;
  final UploadState state;
  final bool canRetry;
  final Widget? trailing;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCompleted = state == UploadState.succeeded;
    final isActive = state == UploadState.running;
    final isQueued = state == UploadState.queued;
    final isPaused = state == UploadState.paused;
    final isCancelling = state == UploadState.cancelling;
    final isFailed = state == UploadState.failed;
    final isCanceled = state == UploadState.canceled;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDesign.space16,
        vertical: AppDesign.space8,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDesign.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon ??
                      (type == _TransferType.upload
                          ? Icons.upload
                          : Icons.download),
                  color: isCompleted
                      ? AppDesign.successGreen
                      : (isFailed || isCanceled)
                          ? AppDesign.errorRed
                          : AppDesign.primaryBlue,
                  size: 20,
                ),
                const SizedBox(width: AppDesign.space12),
                Expanded(
                  child: Text(
                    name,
                    style: AppDesign.body1.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isCompleted)
                  Icon(
                    Icons.check_circle,
                    color: AppDesign.successGreen,
                    size: 20,
                  )
                else if ((isFailed || isCanceled) && canRetry)
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    onPressed: onResume,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: S.current.retry,
                  )
                else if (isCancelling)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (isPaused)
                  IconButton(
                    icon: const Icon(Icons.play_circle_outline, size: 20),
                    onPressed: onResume,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: S.current.resume,
                  )
                else if (isActive || isQueued)
                  IconButton(
                    icon: Icon(
                      type == _TransferType.download && isActive
                          ? Icons.pause_circle
                          : Icons.cancel_outlined,
                      size: 20,
                    ),
                    onPressed: onPause,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: type == _TransferType.download && isActive
                        ? S.current.pause
                        : S.current.cancel,
                  ),
                if (isPaused || isQueued) ...[
                  const SizedBox(width: AppDesign.space8),
                  IconButton(
                    icon: const Icon(Icons.cancel_outlined, size: 20),
                    onPressed: onCancel,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: S.current.cancel,
                  ),
                ] else if (!isActive && !isCancelling) ...[
                  const SizedBox(width: AppDesign.space8),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: onCancel,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: S.current.delete,
                  ),
                ],
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: AppDesign.space12),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDesign.space4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor:
                    isDark ? AppDesign.borderDark : AppDesign.borderLight,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isCompleted
                      ? AppDesign.successGreen
                      : (isFailed || isCanceled)
                          ? AppDesign.errorRed
                          : AppDesign.primaryBlue,
                ),
              ),
            ),
            const SizedBox(height: AppDesign.space12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  status,
                  style: AppDesign.caption.copyWith(
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                if (detail.isNotEmpty)
                  Flexible(
                    child: Text(
                      detail,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: AppDesign.caption.copyWith(
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
