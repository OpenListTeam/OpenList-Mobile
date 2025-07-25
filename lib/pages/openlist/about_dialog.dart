import 'dart:ffi';

import 'package:openlist_mobile/contant/native_bridge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../../generated/l10n.dart';
import '../../generated_api.dart';
import '../../utils/intent_utils.dart';

class AppAboutDialog extends StatefulWidget {
  const AppAboutDialog({super.key});

  @override
  State<AppAboutDialog> createState() {
    return _AppAboutDialogState();
  }
}

class _AppAboutDialogState extends State<AppAboutDialog> {
  String _openlistVersion = "";
  String _version = "";
  int _versionCode = 0;

  Future<Void?> updateVer() async {
    _openlistVersion = await Android().getOpenListVersion();
    _version = await NativeBridge.common.getVersionName();
    _versionCode = await NativeBridge.common.getVersionCode();
    return null;
  }

  @override
  void initState() {
    updateVer().then((value) => setState(() {}));

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final openlistUrl =
        "https://github.com/OpenListTeam/OpenList/releases/tag/$_openlistVersion";
    final appUrl =
        "https://github.com/OpenListTeam/OpenList-Mobile/releases/tag/$_version";
    return AboutDialog(
      applicationName: S.of(context).appName,
      applicationVersion: '$_version ($_versionCode)',
      applicationIcon: SvgPicture.asset(
        "assets/openlist.svg",
        width: 48,
        height: 48,
      ),
      children: [
        TextButton(
          onPressed: () {
            IntentUtils.getUrlIntent(openlistUrl).launchChooser("OpenList");
          },
          onLongPress: () {
            Clipboard.setData(ClipboardData(text: openlistUrl));
            Get.showSnackbar(GetSnackBar(
                message: S.of(context).copiedToClipboard,
                duration: const Duration(seconds: 1)));
          },
          child: const Text("OpenList"),
        ),
        TextButton(
            onPressed: () {
              IntentUtils.getUrlIntent(appUrl).launchChooser("OpenList Mobile");
            },
            onLongPress: () {
              Clipboard.setData(ClipboardData(text: appUrl));
              Get.showSnackbar(GetSnackBar(
                  message: S.of(context).copiedToClipboard,
                  duration: const Duration(seconds: 1)));
            },
            child: const Text("OpenList Mobile")),
      ],
    );
  }
}
