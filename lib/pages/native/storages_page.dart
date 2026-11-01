import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:openlist_mobile/api/models.dart';
import 'package:openlist_mobile/api/session.dart';

import '../../generated/l10n.dart';
import 'common.dart';
import 'storage_edit_page.dart';

/// Lists mounted storages (admin only) with enable/disable/delete actions.
class StoragesPage extends StatefulWidget {
  const StoragesPage({super.key});

  @override
  State<StoragesPage> createState() => _StoragesPageState();
}

class _StoragesPageState extends State<StoragesPage> {
  List<Storage> _storages = const [];
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
      final list = await OpenListSession.instance.admin.listStorages();
      list.sort((a, b) => a.order != b.order
          ? a.order.compareTo(b.order)
          : a.mountPath.compareTo(b.mountPath));
      _storages = list;
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

  Future<void> _edit([Storage? s]) async {
    final changed = await Get.to<bool>(() => StorageEditPage(storage: s));
    if (changed == true) await _load();
  }

  void _showActions(Storage s) {
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
            ListTile(title: Text(s.mountPath), subtitle: Text(s.driver)),
            item(Icons.edit_outlined, S.current.edit, () => _edit(s)),
            s.disabled
                ? item(Icons.play_arrow, S.current.enable,
                    () => _act(() => admin.enableStorage(s.id)))
                : item(Icons.pause, S.current.disable,
                    () => _act(() => admin.disableStorage(s.id))),
            item(Icons.delete_outline, S.current.delete, () async {
              if (await confirmDialog(
                  context, S.current.confirmDeleteStorage(s.mountPath))) {
                await _act(() => admin.deleteStorage(s.id));
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
      appBar: AppBar(title: Text(S.of(context).storages), actions: [
        IconButton(
          tooltip: S.of(context).reloadAll,
          icon: const Icon(Icons.sync),
          onPressed: () =>
              _act(OpenListSession.instance.admin.reloadAllStorages),
        ),
      ]),
      floatingActionButton: FloatingActionButton(
        tooltip: S.of(context).addStorage,
        onPressed: () => _edit(),
        child: const Icon(Icons.add),
      ),
      body: _body(context),
    );
  }

  Widget _body(BuildContext context) {
    if (_loading && _storages.isEmpty) {
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
      child: ListView.builder(
        itemCount: _storages.length,
        itemBuilder: (_, i) {
          final s = _storages[i];
          final scheme = Theme.of(context).colorScheme;
          final status = s.disabled ? S.of(context).storageDisabled : s.status;
          return ListTile(
            leading: Icon(Icons.storage,
                color: s.disabled
                    ? Theme.of(context).disabledColor
                    : (s.isWorking ? scheme.primary : scheme.error)),
            title: Text(s.mountPath),
            subtitle: Text(
              [s.driver, status, if (s.remark.isNotEmpty) s.remark].join(' · '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => _edit(s),
            onLongPress: () => _showActions(s),
            trailing: IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () => _showActions(s)),
          );
        },
      ),
    );
  }
}
