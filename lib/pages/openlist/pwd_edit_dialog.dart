import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:openlist_mobile/api/session.dart';
import 'package:openlist_mobile/generated/l10n.dart';
import 'package:openlist_mobile/utils/service_manager.dart';

class PwdEditDialog extends StatefulWidget {
  final Future<bool> Function(String) onConfirm;
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
  bool _submitting = false;

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
            enabled: !_submitting,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: S.of(context).adminPasswordHint,
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                onPressed: _submitting
                    ? null
                    : () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: Text(widget.cancelText ?? S.of(context).cancel),
        ),
        FilledButton(
          onPressed: _submitting || pwdController.text.trim().isEmpty
              ? null
              : () async {
                  setState(() => _submitting = true);
                  final success = await widget.onConfirm(pwdController.text);
                  if (!context.mounted) return;
                  if (success) {
                    Navigator.pop(context, true);
                  } else {
                    Navigator.pop(context, false);
                  }
                },
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(S.of(context).confirm),
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
      final sm = ServiceManager.instance;
      await sm.setAdminPassword(pwd);
      final session = OpenListSession.instance;
      await session.disconnectLocal();
      if (!await sm.restartServiceAndWait()) {
        throw StateError(S.current.serviceRestartFailed);
      }
      if (session.kind == ConnectionKind.local) await _reconnectLocal();
      Get.showSnackbar(
        GetSnackBar(
          title: S.current.setAdminPassword,
          message: S.current.adminPasswordUpdated,
          duration: const Duration(seconds: 2),
        ),
      );
      return true;
    } catch (e) {
      Get.showSnackbar(
        GetSnackBar(
          title: S.current.setAdminPassword,
          message: 'Error: $e',
          duration: const Duration(seconds: 2),
        ),
      );
      return false;
    }
  }

  static Future<void> _reconnectLocal() async {
    Object? lastError;
    final deadline = DateTime.now().add(const Duration(seconds: 30));
    while (DateTime.now().isBefore(deadline)) {
      try {
        await OpenListSession.instance.connectLocal();
        return;
      } catch (e) {
        lastError = e;
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }
    throw StateError('local session reconnect timed out: $lastError');
  }

  static Future<bool?> showEditor(BuildContext context) => showDialog<bool>(
    context: context,
    builder: (context) => PwdEditDialog(onConfirm: apply),
  );

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
    final result = await Get.dialog<bool>(
      PwdEditDialog(
        title: S.current.adminPasswordSetupTitle,
        message: S.current.adminPasswordSetupMessage,
        cancelText: S.current.later,
        onConfirm: apply,
      ),
      barrierDismissible: false,
    );
    // A failed update asks again on the next launch; cancelling counts as later.
    if (result == null) {
      await prefs.setBool(_promptedKey, true);
      return;
    }
    if (!result) return;
    await prefs.setBool(_promptedKey, true);
  }
}
