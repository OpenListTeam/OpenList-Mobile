import 'dart:async';
import 'dart:io';

import 'package:openlist_mobile/generated_api.dart';
import 'package:openlist_mobile/pages/native/server_page.dart';
import 'package:openlist_mobile/pages/openlist/about_dialog.dart';
import 'package:openlist_mobile/pages/openlist/pwd_edit_dialog.dart';
import 'package:openlist_mobile/pages/openlist/config_editor_page.dart';
import 'package:openlist_mobile/pages/app_update_dialog.dart';
import 'package:openlist_mobile/widgets/switch_floating_action_button.dart';
import 'package:openlist_mobile/utils/service_manager.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../generated/l10n.dart';
import 'log_list_view.dart';

class OpenListScreen extends StatelessWidget {
  const OpenListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ui = Get.put(OpenListController());

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        title: Obx(() => Text("OpenList - ${ui.openlistVersion.value}")),
        actions: [
          IconButton(
            tooltip: S.of(context).serverRuntime,
            onPressed: () => Get.to(() => const ServerPage()),
            icon: const Icon(Icons.dns_outlined),
          ),
          IconButton(
            tooltip: S.current.setAdminPassword,
            onPressed: () => AdminPassword.showEditor(context),
            icon: const Icon(Icons.password),
          ),
          IconButton(
            tooltip: S.of(context).editOpenListConfig,
            onPressed: () {
              Get.to(() => const ConfigEditorPage());
            },
            icon: const Icon(Icons.edit_note),
          ),
          // Desktop shortcut is only available on Android
          if (Platform.isAndroid)
            IconButton(
              tooltip: S.of(context).desktopShortcut,
              onPressed: () async {
                try {
                  await Android().addShortcut();
                  Get.showSnackbar(
                    GetSnackBar(
                      message: S.of(context).desktopShortcut,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                } catch (e) {
                  Get.showSnackbar(
                    GetSnackBar(
                      message: 'Error: $e',
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.add_home),
            ),
          PopupMenuButton(
            tooltip: S.of(context).moreOptions,
            itemBuilder: (context) {
              return [
                PopupMenuItem(
                  value: 1,
                  onTap: () async {
                    AppUpdateDialog.checkUpdateAndShowDialog(context, (b) {
                      if (!b) {
                        Get.showSnackbar(
                          GetSnackBar(
                            message: S.of(context).currentIsLatestVersion,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    });
                  },
                  child: Text(S.of(context).checkForUpdates),
                ),
                PopupMenuItem(
                  value: 2,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: ((context) {
                        return const AppAboutDialog();
                      }),
                    );
                  },
                  child: Text(S.of(context).about),
                ),
              ];
            },
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      floatingActionButton: Obx(
        () => SwitchFloatingButton(
          isSwitch: ui.isSwitch.value,
          onSwitchChange: (s) async {
            ui.clearLog();
            if (s) {
              // 启动服务
              await ServiceManager.instance.startService();
            } else {
              // 停止服务
              await ServiceManager.instance.stopService();
            }
          },
        ),
      ),
      body: Obx(
        () => LogListView(
          logs: ui.logs.toList(),
          controller: ui.scrollController,
        ),
      ),
    );
  }
}

class OpenListController extends GetxController {
  final ScrollController scrollController = ScrollController();
  var isSwitch = false.obs;
  var openlistVersion = "".obs;

  var logs = <Log>[].obs;
  final List<StreamSubscription> _subs = [];

  void clearLog() {
    logs.clear();
  }

  void addLog(Log log) {
    logs.add(log);
    if (scrollController.hasClients) {
      scrollController.jumpTo(scrollController.position.maxScrollExtent);
    }
  }

  @override
  void onInit() {
    // ServiceManager owns the Event channel; subscribe to its streams.
    _subs.add(
      ServiceManager.instance.logStream.listen(
        (e) => addLog(Log(e.level, e.time, e.message)),
      ),
    );
    // Logs emitted before this page opened (e.g. after a boot start).
    ServiceManager.instance.getRecentLogs().then((list) {
      for (final e in list) {
        addLog(Log(e.level, e.time, e.message));
      }
    });

    Android().getOpenListVersion().then(
      (value) => openlistVersion.value = value,
    );

    // 获取初始状态
    ServiceManager.instance.checkServiceStatus().then((isRunning) async {
      isSwitch.value = isRunning;
      if (Platform.isIOS && !isRunning) {
        await ServiceManager.instance.startService();
      }
    });

    // 只监听ServiceManager的状态变化
    _subs.add(
      ServiceManager.instance.serviceStatusStream.listen((isRunning) {
        isSwitch.value = isRunning;
      }),
    );

    super.onInit();
  }

  @override
  void onClose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.onClose();
  }
}
