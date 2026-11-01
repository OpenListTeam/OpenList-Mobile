import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:openlist_mobile/api/session.dart';
import 'package:openlist_mobile/design/theme.dart';
import 'package:openlist_mobile/pages/native/users_page.dart';
import 'package:openlist_mobile/pages/native/tls_page.dart';
import 'package:openlist_mobile/pages/openlist/pwd_edit_dialog.dart';
import 'package:openlist_mobile/screens/storages_screen.dart';
import 'package:openlist_mobile/screens/server_detail_screen.dart';
import 'package:openlist_mobile/utils/language_controller.dart';
import 'package:openlist_mobile/utils/language_manager.dart';
import 'package:openlist_mobile/utils/theme_controller.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

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
          GetBuilder<ThemeController>(
            builder: (themeController) {
              return _SettingsTile(
                icon: Icons.brightness_6,
                title: 'Theme',
                subtitle: themeController.getThemeName(),
                onTap: () {
                  _showThemeSelector(context);
                },
              );
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

          // Admin section (only if admin)
          if (session.user?.isAdmin ?? false) ...[
            _SectionHeader(title: 'Administration'),
            _SettingsTile(
              icon: Icons.people,
              title: 'User Management',
              subtitle: 'Manage users and permissions',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UsersPage()),
                );
              },
            ),
            _SettingsTile(
              icon: Icons.storage,
              title: 'Storage Management',
              subtitle: 'Configure storage backends',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StoragesScreen()),
                );
              },
            ),
            if (Platform.isAndroid) ...[
              _SettingsTile(
                icon: Icons.security,
                title: 'TLS Certificates',
                subtitle: 'Manage SSL/TLS certificates',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TlsPage()),
                  );
                },
              ),
              _SettingsTile(
                icon: Icons.lock,
                title: 'Change Admin Password',
                subtitle: 'Update server admin password',
                onTap: () async {
                  await AdminPassword.showEditor(context);
                },
              ),
            ],
            const SizedBox(height: AppDesign.space24),
          ],

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
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final version = snapshot.data?.version ?? '...';
              return _SettingsTile(
                icon: Icons.info_outline,
                title: 'Version',
                subtitle: version,
                onTap: () {
                  _showAboutDialog(context);
                },
              );
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
            onTap: () async {
              final url = Uri.parse('https://github.com/OpenListTeam/OpenList');
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              } else {
                Get.snackbar('Error', 'Could not open URL');
              }
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
    final themeController = Get.find<ThemeController>();
    final currentMode = themeController.themeMode;

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
              trailing: currentMode == ThemeMode.system
                  ? const Icon(Icons.check)
                  : null,
              onTap: () async {
                await themeController.changeTheme(ThemeMode.system);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.light_mode),
              title: const Text('Light'),
              trailing: currentMode == ThemeMode.light
                  ? const Icon(Icons.check)
                  : null,
              onTap: () async {
                await themeController.changeTheme(ThemeMode.light);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: const Text('Dark'),
              trailing: currentMode == ThemeMode.dark
                  ? const Icon(Icons.check)
                  : null,
              onTap: () async {
                await themeController.changeTheme(ThemeMode.dark);
                Navigator.pop(context);
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

  void _showAboutDialog(BuildContext context) async {
    final packageInfo = await PackageInfo.fromPlatform();

    if (!context.mounted) return;

    showAboutDialog(
      context: context,
      applicationName: 'OpenList',
      applicationVersion: packageInfo.version,
      applicationIcon: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: AppDesign.primaryBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.folder_open,
          size: 40,
          color: AppDesign.primaryBlue,
        ),
      ),
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
