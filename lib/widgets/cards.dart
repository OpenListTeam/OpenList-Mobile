import 'package:flutter/material.dart';
import 'package:openlist_mobile/design/theme.dart';

/// Storage info card showing storage status and space usage
class StorageCard extends StatelessWidget {
  const StorageCard({
    super.key,
    required this.name,
    required this.type,
    required this.status,
    required this.usedBytes,
    required this.totalBytes,
    this.onTap,
  });

  final String name;
  final String type;
  final String status;
  final int usedBytes;
  final int totalBytes;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isConnected = status == 'work';

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDesign.space16,
        vertical: AppDesign.space8,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDesign.radiusCard),
        child: Padding(
          padding: const EdgeInsets.all(AppDesign.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isConnected
                          ? AppDesign.primaryBlue.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(AppDesign.radiusSmall),
                    ),
                    child: Icon(
                      _getTypeIcon(),
                      color: isConnected ? AppDesign.primaryBlue : Colors.grey,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppDesign.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: AppDesign.body1.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppDesign.space4),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: isConnected
                                    ? AppDesign.successGreen
                                    : AppDesign.errorRed,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: AppDesign.space8),
                            Text(
                              isConnected ? 'Connected' : 'Disconnected',
                              style: AppDesign.caption.copyWith(
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                            const SizedBox(width: AppDesign.space8),
                            Text(
                              '•',
                              style: AppDesign.caption.copyWith(
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                            const SizedBox(width: AppDesign.space8),
                            Text(
                              type,
                              style: AppDesign.caption.copyWith(
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ],
              ),
              if (totalBytes > 0) ...[
                const SizedBox(height: AppDesign.space16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatBytes(usedBytes),
                      style: AppDesign.caption.copyWith(
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    Text(
                      _formatBytes(totalBytes),
                      style: AppDesign.caption.copyWith(
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDesign.space8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppDesign.space4),
                  child: LinearProgressIndicator(
                    value: usedBytes / totalBytes,
                    minHeight: 6,
                    backgroundColor:
                        isDark ? AppDesign.borderDark : AppDesign.borderLight,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppDesign.primaryBlue,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getTypeIcon() {
    if (type.toLowerCase().contains('local')) return Icons.folder;
    if (type.toLowerCase().contains('webdav')) return Icons.cloud;
    if (type.toLowerCase().contains('s3')) return Icons.cloud_queue;
    return Icons.storage;
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// Quick access item for recent files or favorite folders
class QuickAccessItem extends StatelessWidget {
  const QuickAccessItem({
    super.key,
    required this.icon,
    required this.label,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(right: AppDesign.space12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDesign.radiusCard),
        child: Container(
          width: 164,
          padding: const EdgeInsets.all(AppDesign.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppDesign.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDesign.radiusSmall),
                ),
                child: Icon(
                  icon,
                  color: AppDesign.primaryBlue,
                  size: 20,
                ),
              ),
              const Spacer(),
              Text(
                label,
                style: AppDesign.body2.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppDesign.space4),
              Text(
                subtitle,
                style: AppDesign.caption.copyWith(
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
