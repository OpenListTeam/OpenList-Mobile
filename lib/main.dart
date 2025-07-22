import 'package:openlist_flutter/generated/l10n.dart';
import 'package:openlist_flutter/pages/openlist/openlist.dart';
import 'package:openlist_flutter/pages/app_update_dialog.dart';
import 'package:openlist_flutter/pages/settings/settings.dart';
import 'package:openlist_flutter/pages/web/web.dart';
import 'package:openlist_flutter/pages/download_manager_page.dart';
import 'package:openlist_flutter/utils/download_manager.dart';
import 'package:openlist_flutter/utils/notification_manager.dart';
import 'package:fade_indexed_stack/fade_indexed_stack.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import 'contant/native_bridge.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化通知管理器
  await NotificationManager.initialize();
  
  // Android
  if (!kIsWeb &&
      kDebugMode &&
      defaultTargetPlatform == TargetPlatform.android) {
    await InAppWebViewController.setWebContentsDebuggingEnabled(kDebugMode);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'OpenList',
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blueGrey,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      darkTheme:ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.blueGrey,
        /* dark theme settings */
      ),
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const MyHomePage(title: ""),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});

  final String title;
  static const webPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(_MainController());

    return Scaffold(
        body: Obx(
          () => FadeIndexedStack(
            lazy: true,
            index: controller.selectedIndex.value,
            children: [
              WebScreen(key: webGlobalKey),
              const OpenListScreen(),
              const DownloadManagerPage(),
              const SettingsScreen()
            ],
          ),
        ),
        bottomNavigationBar: Obx(() => NavigationBar(
                destinations: [
                  NavigationDestination(
                    icon: const Icon(Icons.preview),
                    label: S.current.webPage,
                  ),
                  NavigationDestination(
                    icon: SvgPicture.asset(
                      "assets/openlist.svg",
                      color: Theme.of(context).hintColor,
                      width: 32,
                      height: 32,
                    ),
                    label: S.current.appName,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.arrow_downward),
                    label: _getDownloadLabel(),
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.settings),
                    label: S.current.settings,
                  ),
                ],
                selectedIndex: controller.selectedIndex.value,
                onDestinationSelected: (int index) {
                  // Web
                  if (controller.selectedIndex.value == webPageIndex &&
                      controller.selectedIndex.value == webPageIndex) {
                    webGlobalKey.currentState?.onClickNavigationBar();
                  }

                  controller.setPageIndex(index);
                })));
  }

  String _getDownloadLabel() {
    int activeCount = DownloadManager.activeTasks.length;
    if (activeCount > 0) {
      return S.current.downloadManagerWithCount(activeCount);
    } else {
      return S.current.downloadManager;
    }
  }
}

class _MainController extends GetxController {
  final selectedIndex = 1.obs;

  setPageIndex(int index) {
    selectedIndex.value = index;
  }

  @override
  void onInit() async {
    final webPage = await NativeBridge.appConfig.isAutoOpenWebPageEnabled();
    if (webPage) {
      setPageIndex(MyHomePage.webPageIndex);
    }

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      if (await NativeBridge.appConfig.isAutoCheckUpdateEnabled()) {
        AppUpdateDialog.checkUpdateAndShowDialog(Get.context!, null);
      }
    });

    super.onInit();
  }
}