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
    final theme = Theme.of(context);
    final openlistUrl =
        "https://github.com/OpenListTeam/OpenList/releases/tag/$_openlistVersion";
    final appUrl =
        "https://github.com/OpenListTeam/OpenList-Mobile/releases/tag/$_version";
    
    return Dialog(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SvgPicture.asset(
                "assets/openlist.svg",
                width: 72,
                height: 72,
              ),
              const SizedBox(height: 16),
              Text(
                S.of(context).appName,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$_version ($_versionCode)',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  S.of(context).about,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  leading: Icon(
                    Icons.folder_open,
                    color: theme.colorScheme.primary,
                  ),
                  title: Text(S.of(context).openlist),
                  subtitle: Text(_openlistVersion.isNotEmpty 
                      ? _openlistVersion
                      : S.of(context).about),
                  trailing: const Icon(Icons.open_in_new, size: 20),
                  onTap: () {
                    IntentUtils.getUrlIntent(openlistUrl).launchChooser(S.of(context).openlist);
                  },
                  onLongPress: () {
                    Clipboard.setData(ClipboardData(text: openlistUrl));
                    Get.showSnackbar(GetSnackBar(
                      message: S.of(context).copiedToClipboard,
                      duration: const Duration(seconds: 1),
                    ));
                  },
                ),
              ),
              const SizedBox(height: 8),
              Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  leading: Icon(
                    Icons.phone_android,
                    color: theme.colorScheme.secondary,
                  ),
                  title: Text(S.of(context).openlistMobile),
                  subtitle: Text(_version),
                  trailing: const Icon(Icons.open_in_new, size: 20),
                  onTap: () {
                    IntentUtils.getUrlIntent(appUrl).launchChooser(S.of(context).openlistMobile);
                  },
                  onLongPress: () {
                    Clipboard.setData(ClipboardData(text: appUrl));
                    Get.showSnackbar(GetSnackBar(
                      message: S.of(context).copiedToClipboard,
                      duration: const Duration(seconds: 1),
                    ));
                  },
                ),
              ),
              const SizedBox(height: 8),
              Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  leading: Icon(
                    Icons.description_outlined,
                    color: theme.colorScheme.tertiary,
                  ),
                  title: Text(S.of(context).openSourceLicenses),
                  subtitle: Text(S.of(context).viewThirdPartyLicenses),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    showLicensePage(
                      context: context,
                      applicationName: S.of(context).appName,
                      applicationVersion: '$_version ($_versionCode)',
                      applicationIcon: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SvgPicture.asset(
                          "assets/openlist.svg",
                          width: 48,
                          height: 48,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: () => Navigator.pop(context),
                  child: Text(S.of(context).ok),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
