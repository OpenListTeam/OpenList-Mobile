import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../generated/l10n.dart';
import '../../utils/service_manager.dart';

class PwdEditDialog extends StatefulWidget {
  final ValueChanged<String> onConfirm;
  final String? title;
  final String? message;
  final String? cancelText;

  const PwdEditDialog({
    super.key,
    required this.onConfirm,
    this.title,
    this.message,
    this.cancelText,
  });

  @override
  State<PwdEditDialog> createState() {
    return _PwdEditDialogState();
  }
}

class _PwdEditDialogState extends State<PwdEditDialog>
    with SingleTickerProviderStateMixin {
  final TextEditingController pwdController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    pwdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title ?? S.of(context).modifyAdminPassword),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.message != null) ...[
            Text(widget.message!),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: pwdController,
            obscureText: _obscure,
            autocorrect: false,
            enableSuggestions: false,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: S.of(context).adminPasswordHint,
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {Get.back();},
          child: Text(widget.cancelText ?? S.of(context).cancel),
        ),
        FilledButton(
          onPressed: pwdController.text.trim().isEmpty
              ? null
              : () {
                  Get.back();
                  widget.onConfirm(pwdController.text);
                },
          child: Text(S.of(context).confirm),
        ),
      ],
    );
  }
}

/// Sets the admin password through the core and reports the result.
class AdminPassword {
  static const _promptedKey = 'admin_password_prompted';

  static Future<bool> apply(String pwd) async {
    try {
      await ServiceManager.instance.setAdminPassword(pwd);
      Get.showSnackbar(GetSnackBar(
          title: S.current.setAdminPassword,
          message: S.current.adminPasswordUpdated,
          duration: const Duration(seconds: 2)));
      return true;
    } catch (e) {
      Get.showSnackbar(GetSnackBar(
          title: S.current.setAdminPassword,
          message: 'Error: $e',
          duration: const Duration(seconds: 2)));
      return false;
    }
  }

  static Future<void> showEditor(BuildContext context) => showDialog(
      context: context,
      builder: (context) => PwdEditDialog(onConfirm: apply));

  /// The core creates the admin with a random password the user never sees,
  /// so ask once for a real one. "Later" also counts as answered. Only asks
  /// while the core reports that generated password, so upgrades and users
  /// who already set one from the web UI are left alone.
  static Future<void> promptOnFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_promptedKey) ?? false) return;
    final sm = ServiceManager.instance;
    if (!sm.isServiceRunning) {
      await sm.serviceStatusStream.firstWhere((running) => running);
    }
    final bool generated;
    try {
      final status = jsonDecode(await sm.getRuntimeStatus());
      generated = status is Map && status['admin_password_generated'] == true;
    } catch (e) {
      debugPrint('Admin password check failed: $e');
      return;
    }
    if (!generated) {
      await prefs.setBool(_promptedKey, true);
      return;
    }
    String? pwd;
    await Get.dialog(
      PwdEditDialog(
        title: S.current.adminPasswordSetupTitle,
        message: S.current.adminPasswordSetupMessage,
        cancelText: S.current.later,
        onConfirm: (p) => pwd = p,
      ),
      barrierDismissible: false,
    );
    // A failed update asks again on the next launch.
    if (pwd != null && !await apply(pwd!)) return;
    await prefs.setBool(_promptedKey, true);
  }
}
