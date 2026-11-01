import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:openlist_mobile/api/session.dart';
import 'package:openlist_mobile/design/theme.dart';
import 'package:openlist_mobile/screens/storages_screen.dart';
import 'package:openlist_mobile/screens/server_detail_screen.dart';
import 'package:openlist_mobile/utils/language_controller.dart';
import 'package:openlist_mobile/utils/language_manager.dart';

/// Settings screen
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = OpenListSession.instance;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // User info section
          if (session.isConnected) ...[
            _SectionHeader(title: 'Account'),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: AppDesign.space16),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppDesign.primaryBlue.withOpacity(0.1),
                  child: Icon(
                    Icons.person,
                    color: AppDesign.primaryBlue,
                  ),
                ),
                title: Text(
                  session.user?.username ?? 'Unknown',
                  style: AppDesign.body1.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                subtitle: Text(
                  session.user?.isAdmin ?? false ? 'Administrator' : 'User',
                  style: AppDesign.body2.copyWith(
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                trailing: session.kind == ConnectionKind.remote
                    ? TextButton(
                        onPressed: () async {
                          final confirmed = await _showConfirmDialog(
                            context,
                            'Sign Out',
                            'Are you sure you want to sign out?',
                          );
                          if (confirmed) {
                            await session.logout();
                            await session.connectLocal();
                          }
                        },
                        child: const Text('Sign Out'),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: AppDesign.space24),
          ],

          // Server section (Android only)
          if (Platform.isAndroid) ...[
            _SectionHeader(title: 'Server'),
            _SettingsTile(
              icon: Icons.dns,
              title: 'Server Details',
              subtitle: 'View runtime info and connection details',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ServerDetailScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: AppDesign.space24),
          ],

          // Storage section
          _SectionHeader(title: 'Storage'),
          _SettingsTile(
            icon: Icons.storage,
            title: 'Manage Storages',
            subtitle: 'Add, edit, or remove storage locations',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StoragesScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: AppDesign.space24),

          // Appearance section
          _SectionHeader(title: 'Appearance'),
          _SettingsTile(
            icon: Icons.brightness_6,
            title: 'Theme',
            subtitle: 'System default',
            onTap: () {
              _showThemeSelector(context);
            },
          ),
          _SettingsTile(
            icon: Icons.language,
            title: 'Language',
            subtitle: _getLanguageName(),
            onTap: () {
              _showLanguageSelector(context);
            },
          ),
          const SizedBox(height: AppDesign.space24),

          // Cache section
          _SectionHeader(title: 'Cache'),
          _SettingsTile(
            icon: Icons.cleaning_services,
            title: 'Clear Cache',
            subtitle: 'Free up storage space',
            onTap: () {
              _showClearCacheDialog(context);
            },
          ),
          const SizedBox(height: AppDesign.space24),

          // About section
          _SectionHeader(title: 'About'),
          _SettingsTile(
            icon: Icons.info_outline,
            title: 'Version',
            subtitle: '4.2.9',
            onTap: () {
              _showAboutDialog(context);
            },
          ),
          _SettingsTile(
            icon: Icons.description,
            title: 'Open Source Licenses',
            onTap: () {
              showLicensePage(context: context);
            },
          ),
          _SettingsTile(
            icon: Icons.link,
            title: 'GitHub Repository',
            subtitle: 'github.com/OpenListTeam/OpenList',
            onTap: () {
              // TODO: Open URL
              Get.snackbar('Info', 'Opening GitHub...');
            },
          ),

          const SizedBox(height: AppDesign.space64),
        ],
      ),
    );
  }

  String _getLanguageName() {
    final controller = Get.find<LanguageController>();
    if (controller.locale == null) return 'System default';
    if (controller.locale?.languageCode == 'zh') return '简体中文';
    return 'English';
  }

  void _showThemeSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: AppDesign.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.brightness_auto),
              title: const Text('System Default'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Set theme to system
              },
            ),
            ListTile(
              leading: const Icon(Icons.light_mode),
              title: const Text('Light'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Set theme to light
              },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: const Text('Dark'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Set theme to dark
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageSelector(BuildContext context) {
    final controller = Get.find<LanguageController>();

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: AppDesign.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('System Default'),
              onTap: () async {
                await controller.changeLanguage(
                  LanguageOption(name: 'followSystem', code: '', locale: null),
                );
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('English'),
              onTap: () async {
                await controller.changeLanguage(
                  LanguageOption(name: 'english', code: 'en', locale: const Locale('en')),
                );
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('简体中文'),
              onTap: () async {
                await controller.changeLanguage(
                  LanguageOption(name: 'simplifiedChinese', code: 'zh', locale: const Locale('zh')),
                );
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context) async {
    final confirmed = await _showConfirmDialog(
      context,
      'Clear Cache',
      'This will remove all cached data. Continue?',
    );

    if (confirmed) {
      // TODO: Clear cache
      Get.snackbar('Success', 'Cache cleared');
    }
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'OpenList',
      applicationVersion: '4.2.9',
      applicationIcon: const FlutterLogo(size: 48),
      children: [
        const SizedBox(height: AppDesign.space16),
        const Text(
          'OpenList is an open-source file management and sharing platform.',
        ),
      ],
    );
  }

  Future<bool> _showConfirmDialog(
    BuildContext context,
    String title,
    String message,
  ) async {
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
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDesign.space16,
        AppDesign.space8,
        AppDesign.space16,
        AppDesign.space12,
      ),
      child: Text(
        title,
        style: AppDesign.headline3.copyWith(
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      leading: Icon(icon, color: AppDesign.primaryBlue),
      title: Text(
        title,
        style: AppDesign.body1.copyWith(
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: AppDesign.body2.copyWith(
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            )
          : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
