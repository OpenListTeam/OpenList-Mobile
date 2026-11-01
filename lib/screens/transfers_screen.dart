import 'package:flutter/material.dart';
import 'package:openlist_mobile/design/theme.dart';

/// Transfers screen showing uploads and downloads
class TransfersScreen extends StatefulWidget {
  const TransfersScreen({super.key});

  @override
  State<TransfersScreen> createState() => _TransfersScreenState();
}

class _TransfersScreenState extends State<TransfersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfers'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Uploads'),
            Tab(text: 'Downloads'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'pause_all':
                  // TODO: Pause all
                  break;
                case 'resume_all':
                  // TODO: Resume all
                  break;
                case 'clear_completed':
                  // TODO: Clear completed
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'pause_all', child: Text('Pause All')),
              const PopupMenuItem(value: 'resume_all', child: Text('Resume All')),
              const PopupMenuItem(value: 'clear_completed', child: Text('Clear Completed')),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _UploadsTab(),
          _DownloadsTab(),
        ],
      ),
    );
  }
}

class _UploadsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: Connect to actual upload queue
    final hasUploads = false;

    if (!hasUploads) {
      return _EmptyView(
        icon: Icons.upload,
        message: 'No uploads',
        description: 'Upload files from the Files screen',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppDesign.space16),
      itemCount: 5, // Placeholder
      itemBuilder: (context, index) {
        return _TransferCard(
          name: 'Example File $index.jpg',
          progress: (index * 20) / 100,
          speed: '2.5 MB/s',
          status: index == 0 ? 'Uploading' : 'Waiting',
          type: _TransferType.upload,
          onPause: () {},
          onResume: () {},
          onCancel: () {},
        );
      },
    );
  }
}

class _DownloadsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: Connect to actual download manager
    final hasDownloads = false;

    if (!hasDownloads) {
      return _EmptyView(
        icon: Icons.download,
        message: 'No downloads',
        description: 'Downloaded files will appear here',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppDesign.space16),
      itemCount: 3, // Placeholder
      itemBuilder: (context, index) {
        return _TransferCard(
          name: 'Downloaded File $index.pdf',
          progress: 1.0,
          speed: 'Completed',
          status: 'Completed',
          type: _TransferType.download,
          onPause: () {},
          onResume: () {},
          onCancel: () {},
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
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
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
    required this.name,
    required this.progress,
    required this.speed,
    required this.status,
    required this.type,
    required this.onPause,
    required this.onResume,
    required this.onCancel,
  });

  final String name;
  final double progress;
  final String speed;
  final String status;
  final _TransferType type;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCompleted = progress >= 1.0;
    final isActive = progress > 0 && progress < 1.0;

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
                  color: AppDesign.primaryBlue,
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
                else if (isActive)
                  IconButton(
                    icon: const Icon(Icons.pause_circle, size: 20),
                    onPressed: onPause,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.play_circle, size: 20),
                    onPressed: onResume,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: onCancel,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
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
                  isCompleted ? AppDesign.successGreen : AppDesign.primaryBlue,
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
                Text(
                  speed,
                  style: AppDesign.caption.copyWith(
                    color: isDark ? Colors.white70 : Colors.black54,
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
