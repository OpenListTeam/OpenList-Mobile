import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:openlist_mobile/api/models.dart';
import 'package:openlist_mobile/api/session.dart';

import '../../generated/l10n.dart';
import 'common.dart';
import 'user_edit_page.dart';

/// Lists users (admin only) with edit, 2FA reset and delete actions.
class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  List<AdminUser> _users = const [];
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _users = await OpenListSession.instance.admin.listUsers();
    } catch (e) {
      _error = e;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _act(Future<void> Function() fn) async {
    try {
      await fn();
      showMessage(S.current.operationDone);
    } catch (e) {
      showError(e);
    }
    if (mounted) await _load();
  }

  Future<void> _edit([AdminUser? u]) async {
    final changed = await Get.to<bool>(() => UserEditPage(user: u));
    if (changed == true) await _load();
  }

  void _showActions(AdminUser u) {
    final admin = OpenListSession.instance.admin;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        Widget item(IconData icon, String label, VoidCallback fn) => ListTile(
              leading: Icon(icon),
              title: Text(label),
              onTap: () {
                Navigator.pop(ctx);
                fn();
              },
            );
        return SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(title: Text(u.username), subtitle: Text(roleText(u.role))),
            item(Icons.edit_outlined, S.current.edit, () => _edit(u)),
            item(Icons.lock_reset, S.current.reset2fa,
                () => _act(() => admin.cancelUser2fa(u.id))),
            if (!u.isAdmin && !u.isGuest)
              item(Icons.delete_outline, S.current.delete, () async {
                if (await confirmDialog(
                    context, S.current.confirmDeleteUser(u.username))) {
                  await _act(() => admin.deleteUser(u.id));
                }
              }),
          ]),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).users)),
      floatingActionButton: FloatingActionButton(
        tooltip: S.of(context).addUser,
        onPressed: () => _edit(),
        child: const Icon(Icons.person_add_alt),
      ),
      body: _body(context),
    );
  }

  Widget _body(BuildContext context) {
    if (_loading && _users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return StateMessage(
          icon: Icons.error_outline,
          text: errorText(_error!),
          action: S.of(context).retry,
          onAction: _load);
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(children: [
        for (final u in _users)
          ListTile(
            leading: Icon(u.isAdmin
                ? Icons.admin_panel_settings_outlined
                : u.isGuest
                    ? Icons.person_outline
                    : Icons.person),
            title: Text(u.username),
            subtitle: Text('${roleText(u.role)} · ${u.basePath}'),
            trailing: u.disabled ? Text(S.of(context).userDisabled) : null,
            onTap: () => _showActions(u),
          ),
      ]),
    );
  }
}
