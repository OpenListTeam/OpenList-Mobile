import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:openlist_mobile/api/session.dart';
import 'package:openlist_mobile/contant/native_bridge.dart';
import 'package:openlist_mobile/design/theme.dart';
import 'package:openlist_mobile/generated/l10n.dart';
import 'package:openlist_mobile/pages/native/users_page.dart';
import 'package:openlist_mobile/pages/native/settings_admin_page.dart';
import 'package:openlist_mobile/pages/native/tls_page.dart';
import 'package:openlist_mobile/pages/openlist/pwd_edit_dialog.dart';
import 'package:openlist_mobile/screens/storages_screen.dart';
import 'package:openlist_mobile/screens/server_detail_screen.dart';
import 'package:openlist_mobile/utils/language_controller.dart';
import 'package:openlist_mobile/utils/language_manager.dart';
import 'package:openlist_mobile/utils/service_manager.dart';
import 'package:openlist_mobile/utils/theme_controller.dart';
import 'package:openlist_mobile/utils/download_manager.dart';
import 'package:openlist_mobile/utils/download_destination.dart';
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
        title: Text(S.current.settings),
      ),
      body: ListView(
        children: [
          // User info section
          if (session.isConnected) ...[
            _SectionHeader(title: S.current.account),
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
                  session.user?.isAdmin ?? false
                      ? S.current.administrator
                      : S.current.user,
                  style: AppDesign.body2.copyWith(
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                trailing: session.kind == ConnectionKind.remote
                    ? TextButton(
                        onPressed: () async {
                          final confirmed = await _showConfirmDialog(
                            context,
                            S.current.signOutConfirmTitle,
                            S.current.signOutConfirmMessage,
                          );
                          if (confirmed) {
                            await session.logout();
                            await session.connectLocal();
                          }
                        },
                        child: Text(S.current.signOut),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: AppDesign.space24),
          ],

          // Server section (Android only)
          if (Platform.isAndroid) ...[
            _SectionHeader(title: S.current.server),
            _SettingsTile(
              icon: Icons.dns,
              title: S.current.serverDetails,
              subtitle: S.current.serverDetailsDesc,
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
          _SectionHeader(title: S.current.storage),
          _PlatformStorageSettings(),
          _SettingsTile(
            icon: Icons.storage,
            title: S.current.manageStorages,
            subtitle: S.current.manageStoragesDesc,
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
          _SectionHeader(title: S.current.appearance),
          GetBuilder<ThemeController>(
            builder: (themeController) {
              return _SettingsTile(
                icon: Icons.brightness_6,
                title: S.current.theme,
                subtitle: themeController.getThemeName(),
                onTap: () {
                  _showThemeSelector(context);
                },
              );
            },
          ),
          _SettingsTile(
            icon: Icons.language,
            title: S.current.language,
            subtitle: _getLanguageName(),
            onTap: () {
              _showLanguageSelector(context);
            },
          ),
          const SizedBox(height: AppDesign.space24),

          // Admin section (only if admin)
          if (session.user?.isAdmin ?? false) ...[
            _SectionHeader(title: S.current.administration),
            _SettingsTile(
              icon: Icons.tune,
              title: S.current.coreSettings,
              subtitle: S.current.coreSettingsDesc,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SettingsAdminPage(),
                  ),
                );
              },
            ),
            _SettingsTile(
              icon: Icons.people,
              title: S.current.userManagement,
              subtitle: S.current.userManagementDesc,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UsersPage()),
                );
              },
            ),
            if (Platform.isAndroid) ...[
              _SettingsTile(
                icon: Icons.security,
                title: S.current.tlsCertificates,
                subtitle: S.current.tlsCertificatesDesc,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TlsPage()),
                  );
                },
              ),
              _SettingsTile(
                icon: Icons.lock,
                title: S.current.changeAdminPassword,
                subtitle: S.current.changeAdminPasswordDesc,
                onTap: () async {
                  await AdminPassword.showEditor(context);
                },
              ),
            ],
            const SizedBox(height: AppDesign.space24),
          ],

          // Cache section
          _SectionHeader(title: S.current.cache),
          _SettingsTile(
            icon: Icons.cleaning_services,
            title: S.current.clearCache,
            subtitle: S.current.clearCacheDesc,
            onTap: () {
              _showClearCacheDialog(context);
            },
          ),
          const SizedBox(height: AppDesign.space24),

          // About section
          _SectionHeader(title: S.current.about),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final version = snapshot.data?.version ?? '...';
              return _SettingsTile(
                icon: Icons.info_outline,
                title: S.current.version,
                subtitle: version,
                onTap: () {
                  _showAboutDialog(context);
                },
              );
            },
          ),
          _SettingsTile(
            icon: Icons.description,
            title: S.current.openSourceLicenses,
            onTap: () {
              showLicensePage(context: context);
            },
          ),
          _SettingsTile(
            icon: Icons.link,
            title: S.current.githubRepo,
            subtitle: 'github.com/OpenListTeam/OpenList',
            onTap: () async {
              final url = Uri.parse('https://github.com/OpenListTeam/OpenList');
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              } else {
                Get.snackbar(S.current.error, S.current.couldNotOpenUrl);
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
    if (controller.locale == null) return S.current.systemDefault;
    if (controller.locale?.languageCode == 'zh')
      return S.current.simplifiedChinese;
    return S.current.english;
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
              title: Text(S.current.themeSystem),
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
              title: Text(S.current.themeLight),
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
              title: Text(S.current.themeDark),
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
              title: Text(S.current.systemDefault),
              onTap: () async {
                await controller.changeLanguage(
                  LanguageOption(name: 'followSystem', code: '', locale: null),
                );
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text(S.current.english),
              onTap: () async {
                await controller.changeLanguage(
                  LanguageOption(
                      name: 'english', code: 'en', locale: const Locale('en')),
                );
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text(S.current.simplifiedChinese),
              onTap: () async {
                await controller.changeLanguage(
                  LanguageOption(
                      name: 'simplifiedChinese',
                      code: 'zh',
                      locale: const Locale('zh')),
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
      S.current.clearCache,
      S.current.clearCacheDesc,
    );

    if (confirmed) {
      // TODO: Clear cache
      Get.snackbar(S.current.success, S.current.cacheCleared);
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
            child: Text(S.current.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(S.current.confirm),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _PlatformStorageSettings extends StatefulWidget {
  const _PlatformStorageSettings();

  @override
  State<_PlatformStorageSettings> createState() =>
      _PlatformStorageSettingsState();
}

class _PlatformStorageSettingsState extends State<_PlatformStorageSettings> {
  String _downloadDirectory = '';
  String _dataDirectory = '';
  bool _askForDirectory = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final values = await Future.wait([
      DownloadManager.getDownloadDirectoryTarget(),
      DownloadManager.getAskForDownloadDirectory(),
      if (Platform.isAndroid) NativeBridge.appConfig.getDataDir(),
    ]);
    if (!mounted) return;
    final target = values[0] as DownloadDirectoryTarget?;
    setState(() {
      _downloadDirectory = target?.name ?? '';
      _askForDirectory = values[1] as bool;
      if (Platform.isAndroid) _dataDirectory = values[2] as String;
    });
  }

  Future<void> _pickDownloadDirectory() async {
    final target = await DownloadManager.chooseDownloadDirectory();
    if (target == null || !mounted) return;
    if (!target.isNative && target.directory != null) {
      if (!await DownloadManager.setDownloadDirectory(target.directory!.path)) {
        if (mounted) {
          Get.snackbar(S.current.error, S.current.downloadDirectoryNotWritable);
        }
        return;
      }
    }
    if (mounted) setState(() => _downloadDirectory = target.name);
  }

  Future<bool> _confirmRestart() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(S.current.confirm),
        content: Text(S.current.configSavedRestartRequired),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(S.current.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(S.current.confirm),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _pickDataDirectory() async {
    final path = await FilePicker.platform.getDirectoryPath(
      dialogTitle: S.current.dataDirectory,
    );
    if (path == null) return;
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(S.current.dataDirectory),
            content: Text(S.current.dataDirectoryChangeWarning),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(S.current.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(S.current.confirm),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) return;
    try {
      await NativeBridge.appConfig.setDataDir(path);
    } catch (error) {
      if (mounted) {
        Get.snackbar(S.current.error, S.current.downloadDirectoryNotWritable);
      }
      return;
    }
    if (!mounted) return;
    setState(() => _dataDirectory = path);
    if (await ServiceManager.instance.checkServiceStatus() && mounted) {
      final restart = await _confirmRestart();
      if (restart) await ServiceManager.instance.restartService();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (Platform.isAndroid) ...[
          _SettingsTile(
            icon: Icons.download,
            title: S.current.downloadDirectory,
            subtitle: _downloadDirectory.isEmpty
                ? S.current.defaultDirectory
                : _downloadDirectory,
            onTap: _pickDownloadDirectory,
          ),
        ],
        SwitchListTile(
          secondary: const Icon(Icons.folder_copy_outlined),
          title: Text(S.current.askForDownloadDirectory),
          subtitle: Text(S.current.askForDownloadDirectoryDesc),
          value: _askForDirectory,
          onChanged: (value) async {
            await DownloadManager.setAskForDownloadDirectory(value);
            if (mounted) setState(() => _askForDirectory = value);
          },
        ),
        if (Platform.isAndroid)
          _SettingsTile(
            icon: Icons.folder,
            title: S.current.dataDirectory,
            subtitle: _dataDirectory,
            onTap: _pickDataDirectory,
          ),
      ],
    );
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
