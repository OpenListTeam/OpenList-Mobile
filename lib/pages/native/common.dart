import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:openlist_mobile/api/openlist_client.dart';

import '../../generated/l10n.dart';

/// Human readable error for API and unexpected failures.
String errorText(Object e) => e is ApiException ? e.message : '$e';

void showMessage(String message, {String? title, int seconds = 2}) {
  Get.closeCurrentSnackbar();
  Get.showSnackbar(
    GetSnackBar(
      title: title,
      message: message,
      duration: Duration(seconds: seconds),
    ),
  );
}

void showError(Object e, {String? title}) => showMessage(
  errorText(e),
  title: title ?? S.current.operationFailed,
  seconds: 3,
);

String formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var v = bytes.toDouble();
  var i = 0;
  while (v >= 1024 && i < units.length - 1) {
    v /= 1024;
    i++;
  }
  return '${v.toStringAsFixed(i == 0 ? 0 : 1)} ${units[i]}';
}

String formatTime(DateTime? t) {
  if (t == null) return '';
  final l = t.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${l.year}-${two(l.month)}-${two(l.day)} ${two(l.hour)}:${two(l.minute)}';
}

String formatDuration(int seconds) {
  final d = Duration(seconds: seconds);
  final h = d.inHours;
  final m = d.inMinutes % 60;
  final s = d.inSeconds % 60;
  if (d.inDays > 0) return '${d.inDays}d ${h % 24}h ${m}m';
  return h > 0 ? '${h}h ${m}m' : '${m}m ${s}s';
}

/// Single text field dialog; returns null when cancelled or empty.
Future<String?> promptText(
  BuildContext context, {
  required String title,
  String label = '',
  String initial = '',
  bool obscure = false,
}) {
  final ctrl = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        obscureText: obscure,
        decoration: InputDecoration(labelText: label),
        onSubmitted: (v) {
          final value = obscure ? v : v.trim();
          Navigator.pop(ctx, value.isEmpty ? null : value);
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(S.current.cancel),
        ),
        FilledButton(
          onPressed: () {
            final value = obscure ? ctrl.text : ctrl.text.trim();
            Navigator.pop(ctx, value.isEmpty ? null : value);
          },
          child: Text(S.current.confirm),
        ),
      ],
    ),
  );
}

Future<bool> confirmDialog(
  BuildContext context,
  String message, {
  String? title,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: title == null ? null : Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(S.current.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(S.current.confirm),
        ),
      ],
    ),
  );
  return ok == true;
}

/// Centered message with an optional action, used for empty and error states.
class StateMessage extends StatelessWidget {
  const StateMessage({
    super.key,
    required this.icon,
    required this.text,
    this.action,
    this.onAction,
  });

  final IconData icon;
  final String text;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).hintColor),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center),
            if (action != null) ...[
              const SizedBox(height: 12),
              FilledButton.tonal(onPressed: onAction, child: Text(action!)),
            ],
          ],
        ),
      ),
    );
  }
}
