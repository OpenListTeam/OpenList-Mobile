import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:openlist_mobile/api/upload_queue.dart';
import 'package:openlist_mobile/design/theme.dart';
import 'package:openlist_mobile/generated/l10n.dart';
import 'package:openlist_mobile/generated_api.dart';
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
                if (DownloadManager.activeTasks.isEmpty)
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
  List<DownloadFile> _files = [];
  Map<String, DownloadFile> _taskFiles = {};
  bool _loadingFiles = true;
  bool _refreshingFiles = false;
  bool _refreshPending = false;
  int _filesVersion = 0;

  @override
  void initState() {
    super.initState();
    _filesVersion = DownloadManager.filesVersion;
    DownloadManager.addListener(_onDownloadManagerChanged);
    unawaited(_refreshFiles());
  }

  @override
  void dispose() {
    DownloadManager.removeListener(_onDownloadManagerChanged);
    super.dispose();
  }

  void _onDownloadManagerChanged() {
    if (!mounted) return;
    setState(() {});
    if (_filesVersion == DownloadManager.filesVersion) return;
    if (_refreshingFiles) {
      _refreshPending = true;
      return;
    }
    unawaited(_refreshFiles());
  }

  Future<void> _refreshFiles() async {
    if (_refreshingFiles) {
      _refreshPending = true;
      return;
    }
    _refreshingFiles = true;
    do {
      _refreshPending = false;
      final version = DownloadManager.filesVersion;
      if (mounted) setState(() => _loadingFiles = true);
      final files = await DownloadManager.getDownloadedFileMetadata();
      final byReference = {
        for (final file in files) file.reference: file,
      };
      final taskFiles = <String, DownloadFile>{};
      for (final task in DownloadManager.completedTasks) {
        final reference = task.fileReference ?? task.filePath;
        final file = byReference[reference];
        if (file != null) taskFiles[task.id] = file;
      }
      if (!mounted) break;
      if (version != DownloadManager.filesVersion) {
        _refreshPending = true;
        continue;
      }
      setState(() {
        _files = files;
        _taskFiles = taskFiles;
        _filesVersion = version;
        _loadingFiles = false;
      });
      if (version != DownloadManager.filesVersion) _refreshPending = true;
    } while (_refreshPending && mounted);
    _refreshingFiles = false;
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
    final trackedReferences = <String>{
      for (final task in tasks)
        if (task.fileReference != null)
          task.fileReference!
        else if (task.filePath.isNotEmpty)
          task.filePath,
    };
    final untrackedFiles = _files
        .where((file) => !trackedReferences.contains(file.reference))
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
    final file = _taskFiles[task.id];
    final state = switch (task.status) {
      DownloadStatus.pending => UploadState.queued,
      DownloadStatus.downloading => UploadState.running,
      DownloadStatus.paused => UploadState.paused,
      DownloadStatus.cancelling => UploadState.cancelling,
      DownloadStatus.completed => UploadState.succeeded,
      DownloadStatus.failed => UploadState.failed,
      DownloadStatus.cancelled => UploadState.canceled,
    };
    final activeTask = task.status == DownloadStatus.pending ||
        task.status == DownloadStatus.downloading ||
        task.status == DownloadStatus.paused ||
        task.status == DownloadStatus.cancelling;
    final canRetry = !activeTask &&
        (task.status == DownloadStatus.failed ||
            task.status == DownloadStatus.cancelled) &&
        task.url.isNotEmpty;
    Widget? trailing;
    if (!activeTask) {
      trailing = PopupMenuButton<String>(
        onSelected: (value) => _handleTaskAction(task, file, value),
        itemBuilder: (context) => [
          if (file != null && task.status == DownloadStatus.completed)
            PopupMenuItem(value: 'open', child: Text(S.current.openFile)),
          if (file != null && task.status == DownloadStatus.completed)
            PopupMenuItem(
                value: 'location', child: Text(S.current.showInFileManager)),
          if (file != null && task.status == DownloadStatus.completed)
            PopupMenuItem(value: 'info', child: Text(S.current.fileInfo)),
          if (file != null && task.status == DownloadStatus.completed)
            PopupMenuItem(
                value: 'delete_file', child: Text(S.current.deleteFile)),
          PopupMenuItem(
              value: 'delete_record', child: Text(S.current.deleteRecord)),
        ],
      );
    }
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
      canRetry: canRetry,
      onPause: () {
        switch (task.status) {
          case DownloadStatus.pending:
            DownloadManager.cancelDownload(task.id);
          case DownloadStatus.downloading:
            DownloadManager.pauseDownload(task.id);
          case DownloadStatus.paused:
          case DownloadStatus.cancelling:
          case DownloadStatus.completed:
          case DownloadStatus.failed:
          case DownloadStatus.cancelled:
            break;
        }
      },
      onResume: canRetry
          ? () => unawaited(DownloadManager.retryDownload(task.id))
          : () => DownloadManager.resumeDownload(task.id),
      onCancel: activeTask && task.status != DownloadStatus.cancelling
          ? () => DownloadManager.cancelDownload(task.id)
          : () => DownloadManager.removeTask(task.id),
      trailing: trailing,
    );
  }

  Future<void> _handleTaskAction(
      DownloadTask task, DownloadFile? file, String action) async {
    if (file == null && action != 'delete_record') return;
    switch (action) {
      case 'open':
        await DownloadManager.openDownloadedFile(file!);
      case 'location':
        await DownloadManager.openDownloadedFileLocation(file!);
      case 'info':
        await _showFileInfo(file!);
      case 'delete_file':
        if (await _confirm(S.current.confirmDelete,
            S.current.confirmDeleteFile(task.filename))) {
          await DownloadManager.deleteDownloadedFile(file!);
          await _refreshFiles();
        }
      case 'delete_record':
        if (await _confirm(S.current.confirmDelete,
            S.current.confirmDeleteRecord(task.filename))) {
          DownloadManager.removeTask(task.id);
        }
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

  Future<void> _showFileInfo(DownloadFile file) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.current.fileInfo),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${S.current.fileName}: ${file.name}'),
            Text('${S.current.size}: ${_formatFileSize(file.size)}'),
            Text(
              '${S.current.modifiedTime}: ${_formatDateTime(DateTime.fromMillisecondsSinceEpoch(file.modifiedAt))}',
            ),
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
    final opened = await DownloadManager.openDownloadDirectory();
    if (!opened && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(S.current.openFileFailed(''))));
    }
  }

  Future<void> _clearDownloadFiles() async {
    if (DownloadManager.activeTasks.isNotEmpty) return;
    final target = await DownloadManager.getDownloadDirectoryTarget();
    if (target == null || !mounted) return;
    if (!await _confirm(
        S.current.confirmClear, '${S.current.confirmClearAllFiles}\n\n${target.name}')) {
      return;
    }
    final cleared = await DownloadManager.clearDownloadDirectory();
    if (!mounted) return;
    if (!cleared) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(S.current.clearFailed)));
    }
    await _refreshFiles();
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
    required this.onChanged,
  });

  final DownloadFile file;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context) {
    final filename = file.name;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(_downloadFileIcon(filename)),
        title: Text(filename, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
            '${_formatFileSize(file.size)} · ${_formatDateTime(DateTime.fromMillisecondsSinceEpoch(file.modifiedAt))}'),
        onTap: () => DownloadManager.openDownloadedFile(file),
        trailing: PopupMenuButton<String>(
          onSelected: (action) async {
            switch (action) {
              case 'open':
                await DownloadManager.openDownloadedFile(file);
              case 'location':
                await DownloadManager.openDownloadedFileLocation(file);
              case 'info':
                if (!context.mounted) return;
                await showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(S.current.fileInfo),
                    content: Text(
                      '${S.current.fileName}: ${file.name}\n'
                      '${S.current.size}: ${_formatFileSize(file.size)}\n'
                      '${S.current.modifiedTime}: ${_formatDateTime(DateTime.fromMillisecondsSinceEpoch(file.modifiedAt))}',
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
                  await DownloadManager.deleteDownloadedFile(file);
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
                    onPressed: isQueued ? onCancel : onPause,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: type == _TransferType.download && isActive
                        ? S.current.pause
                        : S.current.cancel,
                  ),
                if (isPaused ||
                    (isActive && type == _TransferType.download)) ...[
                  const SizedBox(width: AppDesign.space8),
                  IconButton(
                    icon: const Icon(Icons.cancel_outlined, size: 20),
                    onPressed: onCancel,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: S.current.cancel,
                  ),
                ] else if (!isActive &&
                    !isQueued &&
                    !isCancelling &&
                    trailing == null) ...[
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
