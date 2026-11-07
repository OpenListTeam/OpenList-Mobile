import 'package:flutter/material.dart';
import 'package:openlist_mobile/design/theme.dart';

/// File list item for different view modes
class FileListItem extends StatelessWidget {
  const FileListItem({
    super.key,
    required this.name,
    required this.isDirectory,
    this.size = 0,
    this.modified,
    this.thumbnail,
    this.selected = false,
    this.onTap,
    this.onLongPress,
  });

  final String name;
  final bool isDirectory;
  final int size;
  final DateTime? modified;
  final String? thumbnail;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: selected
          ? colorScheme.primary.withOpacity(0.1)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDesign.space16,
            vertical: AppDesign.space12,
          ),
          child: Row(
            children: [
              // Icon or thumbnail
              _buildLeading(isDark, colorScheme),
              const SizedBox(width: AppDesign.space12),
              // File info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppDesign.body1.copyWith(
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppDesign.space4),
                    Text(
                      _buildSubtitle(),
                      style: AppDesign.caption.copyWith(
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(
                  Icons.check_circle,
                  color: colorScheme.primary,
                  size: 24,
                )
              else
                Icon(
                  Icons.chevron_right,
                  color: isDark ? Colors.white54 : Colors.black45,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeading(bool isDark, ColorScheme colorScheme) {
    if (thumbnail != null && thumbnail!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppDesign.radiusSmall),
        child: Image.network(
          thumbnail!,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildIcon(isDark, colorScheme),
        ),
      );
    }
    return _buildIcon(isDark, colorScheme);
  }

  Widget _buildIcon(bool isDark, ColorScheme colorScheme) {
    final icon = _getFileIcon();
    final color = isDirectory ? colorScheme.primary : _getFileColor();

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDesign.radiusSmall),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  IconData _getFileIcon() {
    if (isDirectory) return Icons.folder;

    final ext = name.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(ext)) {
      return Icons.image;
    }
    if (['mp4', 'avi', 'mkv', 'mov', 'wmv'].contains(ext)) {
      return Icons.videocam;
    }
    if (['mp3', 'wav', 'flac', 'aac', 'm4a'].contains(ext)) {
      return Icons.audiotrack;
    }
    if (['pdf'].contains(ext)) return Icons.picture_as_pdf;
    if (['doc', 'docx', 'txt', 'md'].contains(ext)) return Icons.description;
    if (['zip', 'rar', '7z', 'tar', 'gz'].contains(ext)) return Icons.folder_zip;

    return Icons.insert_drive_file;
  }

  Color _getFileColor() {
    final ext = name.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(ext)) {
      return Colors.purple;
    }
    if (['mp4', 'avi', 'mkv', 'mov', 'wmv'].contains(ext)) {
      return Colors.red;
    }
    if (['mp3', 'wav', 'flac', 'aac', 'm4a'].contains(ext)) {
      return Colors.orange;
    }
    if (['pdf'].contains(ext)) return Colors.red.shade700;
    if (['doc', 'docx', 'txt', 'md'].contains(ext)) return Colors.blue;
    if (['zip', 'rar', '7z', 'tar', 'gz'].contains(ext)) return Colors.amber;

    return Colors.grey;
  }

  String _buildSubtitle() {
    if (isDirectory) {
      return modified != null ? _formatDate(modified!) : 'Folder';
    }
    final sizeStr = _formatBytes(size);
    final dateStr = modified != null ? _formatDate(modified!) : '';
    return dateStr.isNotEmpty ? '$sizeStr • $dateStr' : sizeStr;
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.month}/${date.day}';
    }
  }
}

/// Grid item for thumbnail view
class FileGridItem extends StatelessWidget {
  const FileGridItem({
    super.key,
    required this.name,
    required this.isDirectory,
    this.thumbnail,
    this.selected = false,
    this.onTap,
    this.onLongPress,
  });

  final String name;
  final bool isDirectory;
  final String? thumbnail;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: selected ? AppDesign.elevationMedium : AppDesign.elevationLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDesign.radiusCard),
        side: selected
            ? BorderSide(color: colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(AppDesign.radiusCard),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thumbnail or icon
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black)
                      .withOpacity(0.03),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppDesign.radiusCard),
                  ),
                ),
                child: thumbnail != null && thumbnail!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppDesign.radiusCard),
                        ),
                        child: Image.network(
                          thumbnail!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildIconCenter(),
                        ),
                      )
                    : _buildIconCenter(),
              ),
            ),
            // File name
            Padding(
              padding: const EdgeInsets.all(AppDesign.space12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: AppDesign.body2.copyWith(
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (selected)
                    Icon(
                      Icons.check_circle,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconCenter() {
    final icon = isDirectory
        ? Icons.folder
        : Icons.insert_drive_file;
    final color = isDirectory ? AppDesign.primaryBlue : Colors.grey;

    return Center(
      child: Icon(icon, size: 48, color: color.withOpacity(0.5)),
    );
  }
}
