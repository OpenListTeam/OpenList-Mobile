import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:openlist_mobile/api/loopback_http.dart';
import 'package:openlist_mobile/api/native_upload.dart';
import 'package:openlist_mobile/api/session.dart';
import 'package:openlist_mobile/contant/native_bridge.dart';
import 'package:openlist_mobile/design/theme.dart';
import 'package:openlist_mobile/generated/l10n.dart';
import 'package:openlist_mobile/pages/app_update_dialog.dart';
import 'package:openlist_mobile/pages/openlist/pwd_edit_dialog.dart';
import 'package:openlist_mobile/screens/home_screen.dart';
import 'package:openlist_mobile/screens/files_screen.dart';
import 'package:openlist_mobile/screens/transfers_screen.dart';
import 'package:openlist_mobile/screens/settings_screen.dart';
import 'package:openlist_mobile/utils/language_controller.dart';
import 'package:openlist_mobile/utils/notification_manager.dart';
import 'package:openlist_mobile/utils/service_manager.dart';
import 'package:openlist_mobile/utils/web_browser_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = LoopbackHttpOverrides();
  unawaited(NativeUploader.instance.restore());

  // Initialize language controller
  Get.put(LanguageController());

  await WebBrowserManager.instance.initialize();

  // Initialize notification manager
  await NotificationManager.initialize();

  // Initialize service manager (supports both Android and iOS)
  await ServiceManager.instance.initialize();

  // For iOS: Ensure service is started on first launch
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    try {
      final isRunning = await ServiceManager.instance.checkServiceStatus();
      if (!isRunning) {
        await ServiceManager.instance.startService();
      }
    } catch (e) {
      debugPrint('Failed to start iOS service on launch: $e');
    }
  }

  // Android WebView debugging
  if (!kIsWeb &&
      kDebugMode &&
      defaultTargetPlatform == TargetPlatform.android) {
    await InAppWebViewController.setWebContentsDebuggingEnabled(kDebugMode);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LanguageController>(
      builder: (languageController) {
        Locale? appLocale = languageController.locale;

        return GetMaterialApp(
          title: 'OpenList',
          themeMode: ThemeMode.system,
          theme: AppDesign.lightTheme(),
          darkTheme: AppDesign.darkTheme(),
          locale: appLocale,
          fallbackLocale: const Locale('en'),
          supportedLocales: S.delegate.supportedLocales,
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const MainNavigationScreen(),
        );
      },
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  final _controller = Get.put(MainNavigationController());

  @override
  void initState() {
    super.initState();
    _controller.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        body: IndexedStack(
          index: _controller.selectedIndex.value,
          children: const [
            HomeScreen(),
            FilesScreen(),
            TransfersScreen(),
            SettingsScreen(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _controller.selectedIndex.value,
          onDestinationSelected: _controller.setPageIndex,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.folder_outlined),
              selectedIcon: Icon(Icons.folder),
              label: 'Files',
            ),
            NavigationDestination(
              icon: Icon(Icons.swap_vert),
              selectedIcon: Icon(Icons.swap_vert),
              label: 'Transfers',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

class MainNavigationController extends GetxController {
  final selectedIndex = 0.obs;
  final _session = OpenListSession.instance;

  void setPageIndex(int index) {
    selectedIndex.value = index;
  }

  Future<void> initialize() async {
    // Restore session
    try {
      await _session.restore();
    } catch (e) {
      debugPrint('Failed to restore session: $e');
    }

    // Post-frame initialization
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      // Prompt for admin password on first launch
      unawaited(AdminPassword.promptOnFirstLaunch());

      // Check for updates if enabled
      if (await NativeBridge.appConfig.isAutoCheckUpdateEnabled()) {
        AppUpdateDialog.checkUpdateAndShowDialog(Get.context!, null);
      }
    });
  }
}
