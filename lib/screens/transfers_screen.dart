import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:openlist_mobile/api/upload_queue.dart';
import 'package:openlist_mobile/design/theme.dart';
import 'package:openlist_mobile/generated/l10n.dart';
import 'package:openlist_mobile/utils/download_manager.dart';

/// Transfers screen showing uploads and downloads
class TransfersScreen extends StatefulWidget {
  const TransfersScreen({super.key});

  @override
  State<TransfersScreen> createState() => _TransfersScreenState();
}

class _TransfersScreenState extends State<TransfersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _uploadQueue = UploadQueue.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _uploadQueue.addListener(_onQueueUpdate);
    DownloadManager.addListener(_onQueueUpdate);
    unawaited(DownloadManager.initialize());
  }

  @override
  void dispose() {
    _uploadQueue.removeListener(_onQueueUpdate);
    DownloadManager.removeListener(_onQueueUpdate);
    _tabController.dispose();
    super.dispose();
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
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                  value: 'resume_all', child: Text(S.current.retryFailed)),
              PopupMenuItem(
                  value: 'clear_completed',
                  child: Text(S.current.clearCompleted)),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _UploadsTab(uploadQueue: _uploadQueue),
          const _DownloadsTab(),
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
      case UploadState.succeeded:
        return S.current.completed;
      case UploadState.failed:
        return S.current.failed;
      case UploadState.canceled:
        return S.current.canceled;
    }
  }
}

class _DownloadsTab extends StatelessWidget {
  const _DownloadsTab();

  @override
  Widget build(BuildContext context) {
    final tasks = DownloadManager.allTasks;
    if (tasks.isEmpty) {
      return _EmptyView(
        icon: Icons.download,
        message: S.current.noDownloads,
        description: S.current.downloadedFilesWillAppearHere,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppDesign.space16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        final state = switch (task.status) {
          DownloadStatus.pending => UploadState.queued,
          DownloadStatus.downloading => UploadState.running,
          DownloadStatus.completed => UploadState.succeeded,
          DownloadStatus.failed => UploadState.failed,
          DownloadStatus.cancelled => UploadState.canceled,
        };
        return _TransferCard(
          key: ValueKey('download-${task.id}'),
          name: task.filename,
          progress: task.totalBytes > 0 ? task.progress : null,
          detail: [
            Uri.tryParse(task.url)?.host,
            task.progressText,
            task.errorMessage,
          ].where((value) => value != null && value.isNotEmpty).join(' · '),
          status: task.statusText,
          type: _TransferType.download,
          state: state,
          canRetry: false,
          onPause: () => DownloadManager.cancelDownload(task.id),
          onResume: () {},
          onCancel: state == UploadState.running
              ? () => DownloadManager.cancelDownload(task.id)
              : () => DownloadManager.removeTask(task.id),
        );
      },
    );
  }
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
    required this.progress,
    required this.detail,
    required this.status,
    required this.type,
    required this.state,
    this.canRetry = true,
    required this.onPause,
    required this.onResume,
    required this.onCancel,
  });

  final String name;
  final double? progress;
  final String detail;
  final String status;
  final _TransferType type;
  final UploadState state;
  final bool canRetry;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCompleted = state == UploadState.succeeded;
    final isActive = state == UploadState.running;
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
                  type == _TransferType.upload ? Icons.upload : Icons.download,
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
                else if (isActive)
                  IconButton(
                    icon: const Icon(Icons.pause_circle, size: 20),
                    onPressed: onPause,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: S.current.cancel,
                  ),
                const SizedBox(width: AppDesign.space8),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: onCancel,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: S.current.delete,
                ),
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
