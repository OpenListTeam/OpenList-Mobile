import 'package:flutter/material.dart';
import 'package:openlist_mobile/api/models.dart';
import 'package:openlist_mobile/api/session.dart';

import '../../generated/l10n.dart';
import 'common.dart';

String roleText(int role) => switch (role) {
      UserRole.admin => S.current.roleAdmin,
      UserRole.guest => S.current.roleGuest,
      _ => S.current.roleGeneral,
    };

String permText(int bit) => switch (bit) {
      UserPerm.seeHides => S.current.permSeeHides,
      UserPerm.accessWithoutPassword => S.current.permAccessWithoutPassword,
      UserPerm.offlineDownload => S.current.permOfflineDownload,
      UserPerm.write => S.current.permWrite,
      UserPerm.rename => S.current.permRename,
      UserPerm.move => S.current.permMove,
      UserPerm.copy => S.current.permCopy,
      UserPerm.remove => S.current.permRemove,
      UserPerm.webdavRead => S.current.permWebdavRead,
      UserPerm.webdavManage => S.current.permWebdavManage,
      UserPerm.ftpAccess => S.current.permFtpAccess,
      UserPerm.ftpManage => S.current.permFtpManage,
      UserPerm.readArchives => S.current.permReadArchives,
      UserPerm.decompress => S.current.permDecompress,
      UserPerm.share => S.current.permShare,
      _ => S.current.permCustomShareId,
    };

/// Creates a general user, or edits an existing one. The core forbids
/// creating admin/guest users and changing a user's role, so role is shown
/// read-only.
class UserEditPage extends StatefulWidget {
  const UserEditPage({super.key, this.user});

  final AdminUser? user;

  @override
  State<UserEditPage> createState() => _UserEditPageState();
}

class _UserEditPageState extends State<UserEditPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _username;
  late final TextEditingController _password;
  late final TextEditingController _basePath;
  late int _permission;
  late bool _disabled;
  bool _saving = false;

  bool get _isNew => widget.user == null;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _username = TextEditingController(text: u?.username ?? '');
    _password = TextEditingController();
    _basePath = TextEditingController(text: u?.basePath ?? '/');
    _permission = u?.permission ?? 0;
    _disabled = u?.disabled ?? false;
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _basePath.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    // Start from the raw user so unmodelled fields round-trip on update.
    final body = widget.user?.toJson() ?? <String, dynamic>{'role': UserRole.general};
    body
      ..['username'] = _username.text.trim()
      ..['password'] = _password.text
      ..['base_path'] = _basePath.text.trim().isEmpty ? '/' : _basePath.text.trim()
      ..['permission'] = _permission
      ..['disabled'] = _disabled;
    try {
      final admin = OpenListSession.instance.admin;
      _isNew ? await admin.createUser(body) : await admin.updateUser(body);
      if (mounted) Navigator.of(context).pop(true);
      showMessage(S.current.saved);
      return;
    } catch (e) {
      showMessage(S.current.saveFailed(errorText(e)), seconds: 3);
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    final isAdmin = u?.isAdmin ?? false;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? S.of(context).addUser : S.of(context).editUser),
        actions: [
          IconButton(
            tooltip: S.of(context).save,
            icon: const Icon(Icons.check),
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
      body: AbsorbPointer(
        absorbing: _saving,
        child: Form(
          key: _formKey,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            if (_saving) const LinearProgressIndicator(),
            TextFormField(
              controller: _username,
              decoration: InputDecoration(labelText: '${S.of(context).username} *'),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? S.current.requiredField : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              obscureText: true,
              decoration: InputDecoration(
                labelText: _isNew ? '${S.of(context).password} *' : S.of(context).password,
                helperText: _isNew ? null : S.of(context).passwordKeepHint,
              ),
              validator: (v) =>
                  _isNew && (v ?? '').isEmpty ? S.current.requiredField : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _basePath,
              decoration: InputDecoration(labelText: S.of(context).basePath),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(S.of(context).role),
              subtitle: Text(roleText(u?.role ?? UserRole.general)),
            ),
            if (!isAdmin)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(S.of(context).userDisabled),
                value: _disabled,
                onChanged: (v) => setState(() => _disabled = v),
              ),
            const Divider(),
            ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(S.of(context).permissions)),
            for (final bit in UserPerm.all)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(permText(bit)),
                value: (_permission >> bit) & 1 == 1,
                onChanged: (v) => setState(() {
                  _permission = v == true
                      ? _permission | (1 << bit)
                      : _permission & ~(1 << bit);
                }),
              ),
          ]),
        ),
      ),
    );
  }
}
