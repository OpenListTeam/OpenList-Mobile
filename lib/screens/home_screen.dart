import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:openlist_mobile/api/session.dart';
import 'package:openlist_mobile/design/theme.dart';
import 'package:openlist_mobile/generated_api.dart';
import 'package:openlist_mobile/utils/service_manager.dart';
import 'package:openlist_mobile/widgets/server_status_card.dart';
import 'package:openlist_mobile/widgets/cards.dart';
import 'package:openlist_mobile/screens/server_detail_screen.dart';

/// Home/Dashboard screen - Content-first design with server controls
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _sm = ServiceManager.instance;
  final _session = OpenListSession.instance;

  ServerStatus? _status;
  String _mode = 'local';

  @override
  void initState() {
    super.initState();
    _load();
    _sm.serverStatusStream.listen((status) {
      if (mounted) setState(() => _status = status);
    });
  }

  Future<void> _load() async {
    try {
      await _sm.checkServiceStatus();
      final mode = await _sm.getMode();
      if (mounted) {
        setState(() {
          _status = _sm.status;
          _mode = mode;
        });
      }
    } catch (e) {
      debugPrint('Failed to load home data: $e');
    }
  }

  Future<void> _handleStartStop() async {
    final isRunning = _status?.running ?? false;

    if (isRunning) {
      final confirmed = await _showConfirmDialog(
        'Stop Server',
        'Are you sure you want to stop the server?',
      );
      if (!confirmed) return;

      await _sm.stopService();
    } else {
      await _sm.startService();
    }

    await Future.delayed(const Duration(milliseconds: 500));
    await _load();
  }

  Future<void> _handleModeChange() async {
    final newMode = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => _NetworkModeSheet(currentMode: _mode),
    );

    if (newMode != null && newMode != _mode) {
      try {
        await _sm.setMode(newMode);
        setState(() => _mode = newMode);

        if (_status?.running ?? false) {
          _showMessage('Mode changed. Restart server to apply.');
        }
      } catch (e) {
        _showMessage('Failed to change mode: $e');
      }
    }
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OpenList'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Notifications
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppDesign.space24),
          children: [
            // Server status card (Android only, or always visible with limited controls on iOS)
            if (Platform.isAndroid || true) // Show on both for now
              ServerStatusCard(
                status: _status,
                mode: _mode,
                onStartStop: _handleStartStop,
                onModeChange: _handleModeChange,
                onTapDetails: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ServerDetailScreen(),
                    ),
                  );
                },
              ),

            // Quick Access section
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDesign.space16,
                AppDesign.space24,
                AppDesign.space16,
                AppDesign.space12,
              ),
              child: Text(
                'Quick Access',
                style: AppDesign.headline3.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87,
                ),
              ),
            ),

            SizedBox(
              height: 120,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppDesign.space16),
                scrollDirection: Axis.horizontal,
                children: [
                  QuickAccessItem(
                    icon: Icons.access_time,
                    label: 'Recent',
                    subtitle: 'Files',
                    onTap: () {
                      // Navigate to files with recent filter
                      Get.find<_MainNavigationController>().setPageIndex(1);
                    },
                  ),
                  QuickAccessItem(
                    icon: Icons.star,
                    label: 'Favorites',
                    subtitle: 'Folders',
                    onTap: () {
                      // Navigate to favorites
                    },
                  ),
                  QuickAccessItem(
                    icon: Icons.image,
                    label: 'Photos',
                    subtitle: 'All images',
                    onTap: () {
                      // Navigate to photos
                    },
                  ),
                  QuickAccessItem(
                    icon: Icons.videocam,
                    label: 'Videos',
                    subtitle: 'All videos',
                    onTap: () {
                      // Navigate to videos
                    },
                  ),
                ],
              ),
            ),

            // Storages section
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDesign.space16,
                AppDesign.space24,
                AppDesign.space16,
                AppDesign.space12,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Storages',
                    style: AppDesign.headline3.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black87,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Navigate to storages page
                      Get.find<_MainNavigationController>().setPageIndex(3);
                    },
                    child: const Text('See All'),
                  ),
                ],
              ),
            ),

            // Storage cards (placeholder - will load from API)
            StorageCard(
              name: 'Local Storage',
              type: 'Local',
              status: 'work',
              usedBytes: 5 * 1024 * 1024 * 1024, // 5 GB
              totalBytes: 20 * 1024 * 1024 * 1024, // 20 GB
              onTap: () {
                // Navigate to this storage
              },
            ),

            const SizedBox(height: AppDesign.space16),
          ],
        ),
      ),
    );
  }
}

/// Network mode selection bottom sheet
class _NetworkModeSheet extends StatelessWidget {
  const _NetworkModeSheet({required this.currentMode});

  final String currentMode;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppDesign.space24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDesign.space24),
            child: Text(
              'Network Mode',
              style: AppDesign.headline3.copyWith(
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: AppDesign.space16),
          _ModeOption(
            icon: Icons.computer,
            title: 'Localhost Only',
            description: 'Only accessible from this device',
            selected: currentMode == 'local',
            onTap: () => Navigator.pop(context, 'local'),
          ),
          _ModeOption(
            icon: Icons.wifi,
            title: 'LAN Access',
            description: 'Accessible from devices on the same network',
            selected: currentMode == 'lan',
            onTap: () => Navigator.pop(context, 'lan'),
          ),
          _ModeOption(
            icon: Icons.public,
            title: 'Public Access',
            description: 'Accessible from anywhere (requires proper security)',
            selected: currentMode == 'public',
            onTap: () => Navigator.pop(context, 'public'),
          ),
        ],
      ),
    );
  }
}

class _ModeOption extends StatelessWidget {
  const _ModeOption({
    required this.icon,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: Icon(
        icon,
        color: selected ? colorScheme.primary : (isDark ? Colors.white70 : Colors.black54),
      ),
      title: Text(
        title,
        style: AppDesign.body1.copyWith(
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      subtitle: Text(
        description,
        style: AppDesign.body2.copyWith(
          color: isDark ? Colors.white70 : Colors.black54,
        ),
      ),
      trailing: selected
          ? Icon(Icons.check_circle, color: colorScheme.primary)
          : null,
      onTap: onTap,
    );
  }
}

/// Main navigation controller (needed for quick access navigation)
class _MainNavigationController extends GetxController {
  final selectedIndex = 0.obs;

  void setPageIndex(int index) {
    selectedIndex.value = index;
  }
}
