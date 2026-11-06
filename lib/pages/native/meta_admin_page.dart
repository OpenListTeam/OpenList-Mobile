import 'package:flutter/material.dart';
import 'package:openlist_mobile/api/session.dart';

import '../../generated/l10n.dart';
import 'common.dart';

class MetaAdminPage extends StatefulWidget {
  const MetaAdminPage({super.key});

  @override
  State<MetaAdminPage> createState() => _MetaAdminPageState();
}

class _MetaAdminPageState extends State<MetaAdminPage> {
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
      final items = await OpenListSession.instance.admin.listMetas();
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
    final values = <String, dynamic>{
      'id': source?['id'],
      'path': source?['path'] ?? '/',
      'read_users': List<int>.from(source?['read_users'] ?? const []),
      'read_users_sub': source?['read_users_sub'] == true,
      'write_users': List<int>.from(source?['write_users'] ?? const []),
      'write_users_sub': source?['write_users_sub'] == true,
      'password': source?['password'] ?? '',
      'p_sub': source?['p_sub'] == true,
      'write': source?['write'] == true,
      'w_sub': source?['w_sub'] == true,
      'hide': source?['hide'] ?? '',
      'h_sub': source?['h_sub'] == true,
      'readme': source?['readme'] ?? '',
      'r_sub': source?['r_sub'] == true,
      'header': source?['header'] ?? '',
      'header_sub': source?['header_sub'] == true,
    };
    final controllers = <String, TextEditingController>{
      for (final key in ['path', 'password', 'hide', 'readme', 'header'])
        key: TextEditingController(text: '${values[key]}'),
      'read_users': TextEditingController(
          text: (values['read_users'] as List<int>).join(',')),
      'write_users': TextEditingController(
          text: (values['write_users'] as List<int>).join(',')),
    };
    try {
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text(source == null ? S.current.create : S.current.edit),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  for (final key in [
                    'path',
                    'password',
                    'read_users',
                    'write_users',
                    'hide',
                    'readme',
                    'header',
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextField(
                        controller: controllers[key],
                        minLines:
                            ['hide', 'readme', 'header'].contains(key) ? 2 : 1,
                        maxLines:
                            ['hide', 'readme', 'header'].contains(key) ? 5 : 1,
                        decoration: InputDecoration(
                          labelText: switch (key) {
                            'path' => S.current.adminMetaPath,
                            'password' => S.current.adminMetaPassword,
                            'hide' => S.current.adminMetaHide,
                            'readme' => S.current.adminMetaReadme,
                            'header' => S.current.adminMetaHeader,
                            _ =>
                              '$key (${S.current.adminUserIdsCommaSeparated})',
                          },
                        ),
                      ),
                    ),
                  for (final entry in const {
                    'write': 'write',
                    'p_sub': 'p_sub',
                    'read_users_sub': 'read_users_sub',
                    'write_users_sub': 'write_users_sub',
                    'w_sub': 'w_sub',
                    'h_sub': 'h_sub',
                    'r_sub': 'r_sub',
                    'header_sub': 'header_sub',
                  }.entries)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(entry.key == 'write'
                          ? S.current.adminWriteAccess
                          : entry.value),
                      value: values[entry.key] == true,
                      onChanged: (value) =>
                          setDialogState(() => values[entry.key] = value),
                    ),
                ]),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(S.current.cancel),
              ),
              FilledButton(
                onPressed: () {
                  final readUsers = _parseIds(controllers['read_users']!.text);
                  final writeUsers =
                      _parseIds(controllers['write_users']!.text);
                  if (controllers['path']!.text.trim().isEmpty ||
                      readUsers == null ||
                      writeUsers == null) {
                    showMessage(S.current.adminMetaInvalidInput);
                    return;
                  }
                  values
                    ..['path'] = controllers['path']!.text.trim()
                    ..['password'] = controllers['password']!.text
                    ..['read_users'] = readUsers
                    ..['write_users'] = writeUsers
                    ..['hide'] = controllers['hide']!.text
                    ..['readme'] = controllers['readme']!.text
                    ..['header'] = controllers['header']!.text;
                  Navigator.pop(dialogContext, values);
                },
                child: Text(S.current.save),
              ),
            ],
          ),
        ),
      );
      if (result == null || !mounted) return;
      setState(() => _saving = true);
      try {
        await OpenListSession.instance.admin
            .saveMeta(result, create: source == null);
        showMessage(S.current.operationDone);
        await _load();
      } catch (e) {
        showError(e);
      }
      if (mounted) setState(() => _saving = false);
    } finally {
      for (final controller in controllers.values) {
        controller.dispose();
      }
    }
  }

  List<int>? _parseIds(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return [];
    final ids = <int>[];
    for (final part in trimmed.split(',')) {
      final id = int.tryParse(part.trim());
      if (id == null || id <= 0) return null;
      ids.add(id);
    }
    return ids;
  }

  Future<void> _delete(Map<String, dynamic> item) async {
    if (!await confirmDialog(context, S.current.adminDeleteMetaConfirm,
        title: S.current.delete)) {
      return;
    }
    try {
      await OpenListSession.instance.admin.deleteMeta(item['id'] as int);
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
          title: Text(S.of(context).metaManagement),
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
                        icon: Icons.rule_folder_outlined,
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
                            return ListTile(
                              title: Text('${item['path'] ?? ''}'),
                              subtitle: Text(
                                  '${S.current.adminWriteAccess}: ${item['write'] == true}  ${S.current.adminMetaPassword}: ${item['password'] == '' ? '—' : '••••••'}'),
                              trailing: PopupMenuButton<String>(
                                onSelected: (action) => action == 'edit'
                                    ? _edit(item)
                                    : _delete(item),
                                itemBuilder: (_) => [
                                  PopupMenuItem(
                                      value: 'edit',
                                      child: Text(S.current.edit)),
                                  PopupMenuItem(
                                      value: 'delete',
                                      child: Text(S.current.delete)),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
      );
}
