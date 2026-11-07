import 'package:flutter/material.dart';
import 'package:openlist_mobile/api/session.dart';

import '../../generated/l10n.dart';
import 'common.dart';

class SharesAdminPage extends StatefulWidget {
  const SharesAdminPage({super.key});

  @override
  State<SharesAdminPage> createState() => _SharesAdminPageState();
}

class _SharesAdminPageState extends State<SharesAdminPage> {
  List<Map<String, dynamic>> _items = const [];
  Object? _error;
  bool _loading = true;
  bool _saving = false;
  int _generation = 0;

  Future<void> _load() async {
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await OpenListSession.instance.admin.listShares();
      if (!mounted || generation != _generation) return;
      _items = items;
    } catch (e) {
      if (!mounted || generation != _generation) return;
      _error = e;
    }
    if (mounted && generation == _generation) {
      setState(() => _loading = false);
    }
  }

  Future<void> _edit([Map<String, dynamic>? source]) async {
    final files = TextEditingController(
        text: ((source?['files'] as List?) ?? const []).join('\n'));
    final id = TextEditingController(text: '${source?['id'] ?? ''}');
    final newId = TextEditingController();
    final remark = TextEditingController(text: '${source?['remark'] ?? ''}');
    final password = TextEditingController(text: '${source?['pwd'] ?? ''}');
    final maxAccess =
        TextEditingController(text: '${source?['max_accessed'] ?? 0}');
    final accessed = TextEditingController(text: '${source?['accessed'] ?? 0}');
    final expires = TextEditingController(text: '${source?['expires'] ?? ''}');
    final readme = TextEditingController(text: '${source?['readme'] ?? ''}');
    final header = TextEditingController(text: '${source?['header'] ?? ''}');
    try {
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(source == null ? S.current.create : S.current.edit),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                _field(id, S.current.adminShareId),
                if (source != null) _field(newId, S.current.adminShareNewId),
                _field(files, S.current.adminShareFiles,
                    minLines: 2, maxLines: 6),
                _field(remark, S.current.adminShareRemark),
                _field(password, S.current.adminSharePassword, obscure: true),
                _field(maxAccess, S.current.adminShareMaxAccess,
                    keyboardType: TextInputType.number),
                if (source != null)
                  _field(accessed, S.current.adminShareAccessed,
                      keyboardType: TextInputType.number),
                _field(expires, S.current.adminShareExpires),
                _field(readme, S.current.adminShareReadme,
                    minLines: 2, maxLines: 5),
                _field(header, S.current.adminShareHeader,
                    minLines: 2, maxLines: 5),
              ]),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(S.current.cancel)),
            FilledButton(
                onPressed: () {
                  final paths = files.text
                      .split('\n')
                      .map((path) => path.trim())
                      .where((path) => path.isNotEmpty)
                      .toList();
                  final max = int.tryParse(maxAccess.text.trim());
                  final count = int.tryParse(accessed.text.trim());
                  final expiryText = expires.text.trim();
                  final expiry = expiryText.isEmpty
                      ? null
                      : DateTime.tryParse(expiryText)
                          ?.toUtc()
                          .toIso8601String();
                  if (paths.isEmpty ||
                      max == null ||
                      max < 0 ||
                      count == null ||
                      count < 0 ||
                      (expiryText.isNotEmpty && expiry == null)) {
                    showMessage(S.current.adminMetaInvalidInput);
                    return;
                  }
                  final value = <String, dynamic>{
                    'files': paths,
                    'expires': expiry,
                    'pwd': password.text,
                    'max_accessed': max,
                    'disabled': source?['disabled'] == true,
                    'order_by': source?['order_by'] ?? 'name',
                    'order_direction': source?['order_direction'] ?? 'asc',
                    'extract_folder': source?['extract_folder'] ?? 'front',
                    'remark': remark.text,
                    'readme': readme.text,
                    'header': header.text,
                    'accessed': count,
                  };
                  if (id.text.trim().isNotEmpty) {
                    value['id'] = id.text.trim();
                  }
                  if (newId.text.trim().isNotEmpty) {
                    value['new_id'] = newId.text.trim();
                    value['id'] = source?['id'];
                  }
                  Navigator.pop(dialogContext, value);
                },
                child: Text(S.current.save)),
          ],
        ),
      );
      if (result == null || !mounted) return;
      setState(() => _saving = true);
      try {
        await OpenListSession.instance.admin
            .saveShare(result, create: source == null);
        await _load();
      } catch (e) {
        showError(e);
      }
      if (mounted) setState(() => _saving = false);
    } finally {
      for (final controller in [
        files,
        id,
        newId,
        remark,
        password,
        maxAccess,
        accessed,
        expires,
        readme,
        header,
      ]) {
        controller.dispose();
      }
    }
  }

  Widget _field(TextEditingController controller, String label,
      {int minLines = 1,
      int maxLines = 1,
      bool obscure = false,
      TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        minLines: minLines,
        maxLines: maxLines,
        obscureText: obscure,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  Future<void> _delete(Map<String, dynamic> item) async {
    if (!await confirmDialog(context, S.current.confirmDelete,
        title: S.current.delete)) {
      return;
    }
    try {
      await OpenListSession.instance.admin.deleteShare('${item['id'] ?? ''}');
      await _load();
    } catch (e) {
      showError(e);
    }
  }

  Future<void> _toggle(Map<String, dynamic> item, bool enabled) async {
    try {
      await OpenListSession.instance.admin
          .setShareEnabled('${item['id'] ?? ''}', enabled: enabled);
      await _load();
    } catch (e) {
      showError(e);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(S.of(context).adminShareManagement),
          actions: [
            IconButton(
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.refresh)),
            IconButton(
                onPressed: _saving ? null : () => _edit(),
                icon: const Icon(Icons.add)),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? StateMessage(
                    icon: Icons.error_outline,
                    text: errorText(_error!),
                    action: S.of(context).retry,
                    onAction: _load,
                  )
                : _items.isEmpty
                    ? StateMessage(
                        icon: Icons.share_outlined,
                        text: S.of(context).adminEmpty,
                        action: S.of(context).create,
                        onAction: () => _edit(),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          itemCount: _items.length,
                          itemBuilder: (context, index) {
                            final item = _items[index];
                            final enabled = item['disabled'] != true;
                            final paths = ((item['files'] as List?) ?? const [])
                                .map((path) => '$path')
                                .join(', ');
                            return ListTile(
                              title: Text('${item['id'] ?? ''}'),
                              subtitle: Text(paths,
                                  maxLines: 2, overflow: TextOverflow.ellipsis),
                              leading: Icon(enabled
                                  ? Icons.link
                                  : Icons.link_off_outlined),
                              trailing: PopupMenuButton<String>(
                                onSelected: (action) => switch (action) {
                                  'edit' => _edit(item),
                                  'toggle' => _toggle(item, !enabled),
                                  _ => _delete(item),
                                },
                                itemBuilder: (_) => [
                                  PopupMenuItem(
                                      value: 'edit',
                                      child: Text(S.current.edit)),
                                  PopupMenuItem(
                                      value: 'toggle',
                                      child: Text(enabled
                                          ? S.current.disable
                                          : S.current.enable)),
                                  PopupMenuItem(
                                      value: 'delete',
                                      child: Text(S.current.delete)),
                                ],
                              ),
                              onTap: () => _edit(item),
                            );
                          },
                        ),
                      ),
      );
}
