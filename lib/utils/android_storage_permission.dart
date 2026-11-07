import 'dart:io';

import 'package:flutter/material.dart';
import 'package:openlist_mobile/contant/native_bridge.dart';
import 'package:openlist_mobile/generated/l10n.dart';
import 'package:permission_handler/permission_handler.dart';

class AndroidStoragePermission {
  static Future<bool> isGranted() async {
    if (!Platform.isAndroid) return true;
    if (await NativeBridge.common.getDeviceSdkInt() < 30) return true;
    return Permission.manageExternalStorage.isGranted;
  }

  static Future<bool> request() async {
    if (await isGranted()) return true;
    await Permission.manageExternalStorage.request();
    return isGranted();
  }

  static Future<bool> ensure(BuildContext context) async {
    if (await isGranted()) return true;
    if (!context.mounted) return false;

    final openSettings = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(S.of(dialogContext).grantManagerStoragePermission),
        content: Text(S.of(dialogContext).grantStoragePermissionDesc),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(S.of(dialogContext).cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(S.of(dialogContext).goToSettings),
          ),
        ],
      ),
    );
    if (openSettings != true || !context.mounted) return false;
    return request();
  }
}
