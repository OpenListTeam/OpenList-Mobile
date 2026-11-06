import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:openlist_mobile/api/models.dart';
import 'package:openlist_mobile/api/session.dart';

import '../../generated/l10n.dart';
import 'common.dart';

/// Setting groups from `internal/model/setting.go`.
final _groups = <(int, String Function())>[
  (1, () => S.current.groupSite),
  (2, () => S.current.groupStyle),
  (3, () => S.current.groupPreview),
  (4, () => S.current.groupGlobal),
  (5, () => S.current.groupOfflineDownload),
  (6, () => S.current.groupIndex),
  (7, () => S.current.groupSso),
  (8, () => S.current.groupLdap),
  (9, () => S.current.groupS3),
  (10, () => S.current.groupFtp),
  (11, () => S.current.groupTraffic),
  (12, () => S.current.groupMedia),
  (13, () => S.current.groupTranscode),
];

/// Edits site settings group by group (admin only); saves changed items only.
class SettingsAdminPage extends StatefulWidget {
  const SettingsAdminPage({super.key});

  @override
  State<SettingsAdminPage> createState() => _SettingsAdminPageState();
}

class _SettingsAdminPageState extends State<SettingsAdminPage> {
  int _group = _groups.first.$1;
  List<SettingItem> _items = const [];
  String? _token;
  bool _resettingToken = false;

  /// Values as loaded, keyed by setting key, to detect changes.
  Map<String, String> _original = const {};
  Object? _error;
  bool _loading = true;
  bool _saving = false;

  /// Bumped per load so a slow response for an old group is dropped.
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _load();
    _loadToken();
  }

  Future<void> _loadToken() async {
    try {
      final items = await OpenListSession.instance.admin.listSettings([0]);
      final token = items
          .where((item) => item.key == 'token')
          .map((item) => item.value)
          .firstOrNull;
      if (mounted) setState(() => _token = token);
    } catch (_) {
      if (mounted) setState(() => _token = null);
    }
  }

  Future<void> _resetToken() async {
    if (!await confirmDialog(
      context,
      S.current.resetTokenConfirm,
      title: S.current.resetToken,
    )) {
      return;
    }
    setState(() => _resettingToken = true);
    try {
      final token = await OpenListSession.instance.admin.resetToken();
      if (mounted) {
        setState(() => _token = token);
        showMessage(S.current.resetTokenSuccess);
      }
    } catch (e) {
      if (mounted) showError(e);
    }
    if (mounted) setState(() => _resettingToken = false);
  }

  Future<void> _load() async {
    final gen = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items =
          (await OpenListSession.instance.admin.listSettings([_group]))
              .where((e) => !e.deprecated)
              .toList();
      if (!mounted || gen != _generation) return;
      _items = items;
      _original = {for (final i in items) i.key: i.value};
    } catch (e) {
      if (!mounted || gen != _generation) return;
      _error = e;
    }
    if (mounted && gen == _generation) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final changed = _items
        .where((i) => !i.readOnly && _original[i.key] != i.value)
        .toList();
    if (changed.isEmpty) {
      showMessage(S.current.noChanges);
      return;
    }
    setState(() => _saving = true);
    try {
      await OpenListSession.instance.admin.saveSettings(changed);
      _original = {for (final i in _items) i.key: i.value};
      showMessage(S.current.saved);
    } catch (e) {
      showMessage(S.current.saveFailed(errorText(e)), seconds: 3);
    }
    if (mounted) setState(() => _saving = false);
  }

  Widget _field(SettingItem item) {
    final help = item.help.isEmpty ? null : item.help;
    final key = ValueKey('$_group/${item.key}');
    if (item.type == 'bool') {
      return SwitchListTile(
        key: key,
        contentPadding: EdgeInsets.zero,
        title: Text(item.key),
        subtitle: help == null ? null : Text(help),
        value: item.value == 'true',
        onChanged: item.readOnly
            ? null
            : (v) => setState(() => item.value = v ? 'true' : 'false'),
      );
    }
    final options = item.optionList;
    if (item.type == 'select' && options.isNotEmpty) {
      return DropdownButtonFormField<String>(
        key: key,
        value: options.contains(item.value) ? item.value : null,
        isExpanded: true,
        decoration: InputDecoration(
            labelText: item.key, helperText: help, helperMaxLines: 3),
        items: [
          for (final o in options) DropdownMenuItem(value: o, child: Text(o))
        ],
        onChanged:
            item.readOnly ? null : (v) => setState(() => item.value = v ?? ''),
      );
    }
    final multiline = item.type == 'text';
    return TextFormField(
      key: key,
      initialValue: item.value,
      readOnly: item.readOnly,
      minLines: multiline ? 2 : 1,
      maxLines: multiline ? 8 : 1,
      keyboardType: item.type == 'number' ? TextInputType.number : null,
      decoration: InputDecoration(
          labelText: item.key, helperText: help, helperMaxLines: 3),
      onChanged: (v) => item.value = v,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).coreSettings), actions: [
        IconButton(
          tooltip: S.of(context).save,
          icon: const Icon(Icons.check),
          onPressed: _saving || _loading || _error != null ? null : _save,
        ),
      ]),
      body: Column(children: [
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              for (final (id, label) in _groups)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(label()),
                    selected: _group == id,
                    onSelected: _saving
                        ? null
                        : (_) {
                            if (_group == id) return;
                            setState(() => _group = id);
                            _load();
                          },
                  ),
                ),
            ],
          ),
        ),
        if (_loading || _saving) const LinearProgressIndicator(),
        Expanded(child: _body(context)),
      ]),
    );
  }

  Widget _body(BuildContext context) {
    if (_error != null) {
      return StateMessage(
          icon: Icons.error_outline,
          text: errorText(_error!),
          action: S.of(context).retry,
          onAction: _load);
    }
    if (_loading) return const SizedBox.shrink();
    return AbsorbPointer(
      absorbing: _saving,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        if (_token != null) ...[
          Text(S.current.apiToken,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SelectableText(_token!),
          const SizedBox(height: 8),
          Row(children: [
            OutlinedButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: _token!));
                showMessage(S.current.copiedToClipboard);
              },
              icon: const Icon(Icons.copy),
              label: Text(S.current.copy),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: _resettingToken ? null : _resetToken,
              icon: const Icon(Icons.refresh),
              label: Text(S.current.resetToken),
            ),
          ]),
          const Divider(height: 32),
        ],
        for (final i in _items) ...[_field(i), const SizedBox(height: 12)],
      ]),
    );
  }
}
