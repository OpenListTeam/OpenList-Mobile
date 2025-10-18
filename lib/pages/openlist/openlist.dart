import 'package:openlist_mobile/generated_api.dart';
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
                tooltip: S.current.setAdminPassword,
                onPressed: () {
                  showDialog(
                      context: context,
                      builder: (context) => PwdEditDialog(onConfirm: (pwd) {
                            Get.showSnackbar(GetSnackBar(
                                title: S.current.setAdminPassword,
                                message: pwd,
                                duration: const Duration(seconds: 1)));
                            Android().setAdminPwd(pwd);
                          }));
                },
                icon: const Icon(Icons.password),
              ),
              IconButton(
                tooltip: S.of(context).editOpenListConfig,
                onPressed: () {
                  Get.to(() => const ConfigEditorPage());
                },
                icon: const Icon(Icons.edit_note),
              ),
              IconButton(
                tooltip: S.of(context).desktopShortcut,
                onPressed: () async  {
                  Android().addShortcut();
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
                            Get.showSnackbar(GetSnackBar(
                                message: S.of(context).currentIsLatestVersion,
                                duration: const Duration(seconds: 2)));
                          }
                        });
                      },
                      child: Text(S.of(context).checkForUpdates),
                    ),
                    PopupMenuItem(
                      value: 2,
                      onTap: () {
                        showDialog(context: context, builder: ((context){
                          return const AppAboutDialog();
                        }));
                      },
                      child: Text(S.of(context).about),
                    ),
                  ];
                },
                icon: const Icon(Icons.more_vert),
              )
            ]),
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
              }),
        ),
        body: Obx(() => LogListView(logs: ui.logs.value)));
  }
}

class MyEventReceiver extends Event {
  Function(Log log) logCb;
  Function(bool isRunning) statusCb;

  MyEventReceiver(this.statusCb, this.logCb);

  @override
  void onServiceStatusChanged(bool isRunning) {
    statusCb(isRunning);
  }

  @override
  void onServerLog(int level, String time, String log) {
    logCb(Log(level, time, log));
  }
}

class OpenListController extends GetxController {
  final ScrollController _scrollController = ScrollController();
  var isSwitch = false.obs;
  var openlistVersion = "".obs;

  var logs = <Log>[].obs;

  void clearLog() {
    logs.clear();
  }

  void addLog(Log log) {
    logs.add(log);
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  @override
  void onInit() {
    // 设置日志接收器，但状态变化只通过ServiceManager处理
    Event.setup(MyEventReceiver(
        (isRunning) {
          // 不在这里更新状态，避免冲突
          print('Event receiver status: $isRunning');
        }, 
        (log) => addLog(log)));
    
    Android().getOpenListVersion().then((value) => openlistVersion.value = value);
    
    // 获取初始状态
    ServiceManager.instance.checkServiceStatus().then((isRunning) {
      isSwitch.value = isRunning;
    });

    // 只监听ServiceManager的状态变化
    ServiceManager.instance.serviceStatusStream.listen((isRunning) {
      print('ServiceManager status changed: $isRunning');
      isSwitch.value = isRunning;
    });

    super.onInit();
  }
}