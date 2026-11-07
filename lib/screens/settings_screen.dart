import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import 'package:get/get.dart';
import 'package:openlist_mobile/api/session.dart';
import 'package:openlist_mobile/contant/native_bridge.dart';
import 'package:openlist_mobile/design/theme.dart';
import 'package:openlist_mobile/generated/l10n.dart';
import 'package:openlist_mobile/pages/native/users_page.dart';
import 'package:openlist_mobile/pages/native/server_page.dart';
import 'package:openlist_mobile/pages/native/settings_admin_page.dart';
import 'package:openlist_mobile/pages/native/meta_admin_page.dart';
import 'package:openlist_mobile/pages/native/shares_admin_page.dart';
import 'package:openlist_mobile/pages/native/index_admin_page.dart';
import 'package:openlist_mobile/pages/native/media_admin_page.dart';
import 'package:openlist_mobile/pages/native/transcode_admin_page.dart';
import 'package:openlist_mobile/pages/native/storages_page.dart';
import 'package:openlist_mobile/pages/native/tasks_page.dart';
import 'package:openlist_mobile/pages/native/tls_page.dart';
import 'package:openlist_mobile/pages/openlist/pwd_edit_dialog.dart';
import 'package:openlist_mobile/screens/server_detail_screen.dart';
import 'package:openlist_mobile/utils/android_storage_permission.dart';
import 'package:openlist_mobile/utils/download_destination.dart';
import 'package:openlist_mobile/utils/download_manager.dart';
import 'package:openlist_mobile/utils/language_controller.dart';
import 'package:openlist_mobile/utils/language_manager.dart';
import 'package:openlist_mobile/utils/service_manager.dart';
import 'package:openlist_mobile/utils/theme_controller.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Settings screen
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = OpenListSession.instance;
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) => _build(context, session),
    );
  }

  Widget _build(BuildContext context, OpenListSession session) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasLocalCore = session.kind == ConnectionKind.local;
    final isAdmin = session.user?.isAdmin ?? false;

    return Scaffold(
      appBar: AppBar(title: Text(S.current.settings)),
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
                  child: Icon(Icons.person, color: AppDesign.primaryBlue),
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
                  MaterialPageRoute(builder: (_) => const ServerDetailScreen()),
                );
              },
            ),
            const SizedBox(height: AppDesign.space24),
          ],

          // Storage section
          _SectionHeader(title: S.current.storage),
          _PlatformStorageSettings(),
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

          // Local core password management is available without an API session.
          if (hasLocalCore || isAdmin) ...[
            _SectionHeader(title: S.current.administration),
            if (hasLocalCore)
              _SettingsTile(
                icon: Icons.lock,
                title: S.current.changeAdminPassword,
                subtitle: S.current.changeAdminPasswordDesc,
                onTap: () async {
                  await AdminPassword.showEditor(context);
                },
              ),
            if (isAdmin) ...[
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
                icon: Icons.rule_folder_outlined,
                title: S.current.metaManagement,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MetaAdminPage()),
                  );
                },
              ),
              _SettingsTile(
                icon: Icons.share,
                title: S.current.adminShareManagement,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SharesAdminPage()),
                  );
                },
              ),
              _SettingsTile(
                icon: Icons.manage_search,
                title: S.current.adminIndexes,
                subtitle: S.current.adminManualScan,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const IndexAdminPage()),
                  );
                },
              ),
              _SettingsTile(
                icon: Icons.perm_media_outlined,
                title: S.current.adminMediaTitle,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MediaAdminPage()),
                  );
                },
              ),
              _SettingsTile(
                icon: Icons.video_settings_outlined,
                title: S.current.transcodeManagement,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TranscodeAdminPage(),
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
              _SettingsTile(
                icon: Icons.storage,
                title: S.current.manageStorages,
                subtitle: S.current.manageStoragesDesc,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const StoragesPage()),
                  );
                },
              ),
              _SettingsTile(
                icon: Icons.task_alt,
                title: S.current.tasks,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TasksPage()),
                  );
                },
              ),
              if (Platform.isAndroid && hasLocalCore) ...[
                _SettingsTile(
                  icon: Icons.dns,
                  title: S.current.serverRuntime,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ServerPage()),
                    );
                  },
                ),
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
              ],
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
                    name: 'english',
                    code: 'en',
                    locale: const Locale('en'),
                  ),
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
                    locale: const Locale('zh'),
                  ),
                );
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _clearCache() async {
    PaintingBinding.instance.imageCache.clear();

    PaintingBinding.instance.imageCache.clearLiveImages();
  }

  void _showClearCacheDialog(BuildContext context) async {
    final confirmed = await _showConfirmDialog(
      context,
      S.current.clearCache,
      S.current.clearCacheDesc,
    );

    if (confirmed) {
      try {
        await _clearCache();
        if (context.mounted) {
          Get.snackbar(S.current.success, S.current.cacheCleared);
        }
      } catch (error) {
        if (context.mounted) {
          Get.snackbar(S.current.error, '$error');
        }
      }
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
        child: Icon(Icons.folder_open, size: 40, color: AppDesign.primaryBlue),
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
  bool _allFilesGranted = true;
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(onResume: _refreshPermission);
    _load();
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  Future<void> _refreshPermission() async {
    try {
      final granted = await AndroidStoragePermission.isGranted();
      if (mounted && granted != _allFilesGranted) {
        setState(() => _allFilesGranted = granted);
      }
    } catch (error) {
      if (mounted) Get.snackbar(S.current.error, '$error');
    }
  }

  Future<void> _load() async {
    try {
      final values = await Future.wait([
        DownloadManager.getDownloadDirectoryTarget(),
        DownloadManager.getAskForDownloadDirectory(),
        AndroidStoragePermission.isGranted(),
        if (Platform.isAndroid) NativeBridge.appConfig.getDataDir(),
      ]);
      if (!mounted) return;
      final target = values[0] as DownloadDirectoryTarget?;
      setState(() {
        _downloadDirectory = target?.name ?? '';
        _askForDirectory = values[1] as bool;
        _allFilesGranted = values[2] as bool;
        if (Platform.isAndroid) _dataDirectory = values[3] as String;
      });
    } catch (error) {
      if (mounted) Get.snackbar(S.current.error, '$error');
    }
  }

  Future<void> _grantAllFilesAccess() async {
    final granted = await AndroidStoragePermission.request();
    if (mounted) setState(() => _allFilesGranted = granted);
  }

  Future<void> _pickDownloadDirectory() async {
    try {
      final target = await DownloadManager.chooseDownloadDirectory();
      if (target == null || !mounted) return;
      if (!target.isNative && target.directory != null) {
        if (!await DownloadManager.setDownloadDirectory(
          target.directory!.path,
        )) {
          if (mounted) {
            Get.snackbar(
              S.current.error,
              S.current.downloadDirectoryNotWritable,
            );
          }
          return;
        }
      }
      if (mounted) setState(() => _downloadDirectory = target.name);
    } catch (error) {
      if (mounted) Get.snackbar(S.current.error, '$error');
    }
  }

  Future<void> _pickDataDirectory() async {
    if (!await AndroidStoragePermission.ensure(context)) return;
    final path = await FilePicker.getDirectoryPath(
      dialogTitle: S.current.dataDirectory,
    );
    if (path == null) return;
    final serviceRunning = await ServiceManager.instance.checkServiceStatus();
    if (!mounted) return;
    final confirmation = [
      S.current.dataDirectoryChangeWarning,
      if (serviceRunning) S.current.dataDirectoryRestartRequired,
    ].join('\n\n');
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(S.current.dataDirectory),
            content: Text(confirmation),
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

    final previousPath = _dataDirectory;
    try {
      await NativeBridge.appConfig.setDataDir(path);
    } catch (error) {
      if (mounted) Get.snackbar(S.current.error, '$error');
      return;
    }
    if (!mounted) return;
    setState(() => _dataDirectory = path);
    if (serviceRunning && !await ServiceManager.instance.restartService()) {
      try {
        await NativeBridge.appConfig.setDataDir(previousPath);
        if (mounted) setState(() => _dataDirectory = previousPath);
      } catch (error) {
        if (mounted) Get.snackbar(S.current.error, '$error');
      }
      if (mounted) {
        Get.snackbar(S.current.error, S.current.serviceRestartFailed);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (Platform.isAndroid) ...[
          if (!_allFilesGranted)
            _SettingsTile(
              icon: Icons.admin_panel_settings_outlined,
              title: S.current.grantManagerStoragePermission,
              subtitle: S.current.grantStoragePermissionDesc,
              onTap: _grantAllFilesAccess,
            ),
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
