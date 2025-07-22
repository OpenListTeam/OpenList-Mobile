import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../generated/l10n.dart';

class PwdEditDialog extends StatefulWidget {
  final ValueChanged<String> onConfirm;

  const PwdEditDialog({super.key, required this.onConfirm});

  @override
  State<PwdEditDialog> createState() {
    return _PwdEditDialogState();
  }
}

class _PwdEditDialogState extends State<PwdEditDialog>
    with SingleTickerProviderStateMixin {
  final TextEditingController pwdController = TextEditingController();

  @override
  void dispose() {
    pwdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(S.of(context).modifyAdminPassword),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: pwdController,
            decoration: const InputDecoration(
              labelText: "admin密码",
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {Get.back();},
          child: Text(S.of(context).cancel),
        ),
        FilledButton(
          onPressed: () {
            Get.back();
            widget.onConfirm(pwdController.text);
          },
          child: Text(S.of(context).confirm),
        ),
      ],
    );
  }
}
