import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:openlist_mobile/api/admin_api.dart';
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

const _offlineDownloadGroup = 5;

final _offlineDownloadKeys = <String>{
  for (final config in offlineDownloadToolConfigs) ...config.fields.keys,
};

SettingItem _offlinePlaceholder(String key) => SettingItem({
      'key': key,
      'value': '',
      'type': key.endsWith('_seedtime') ? 'number' : 'string',
      'group': _offlineDownloadGroup,
      'flag': 1,
    });

List<SettingItem> _completeOfflineSettings(List<SettingItem> loaded) {
  final byKey = {for (final item in loaded) item.key: item};
  for (final key in _offlineDownloadKeys) {
    byKey.putIfAbsent(key, () => _offlinePlaceholder(key));
  }
  return [
    for (final config in offlineDownloadToolConfigs)
      for (final key in config.fields.keys) byKey[key]!,
    for (final item in loaded)
      if (!_offlineDownloadKeys.contains(item.key)) item,
  ];
}

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
  int _formGeneration = 0;
  bool _allowExit = false;

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
    final group = _group;
    final gen = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
      _formGeneration++;
    });
    try {
      final loaded =
          (await OpenListSession.instance.admin.listSettings([group]))
              .where((e) => !e.deprecated)
              .toList();
      final items = group == _offlineDownloadGroup
          ? _completeOfflineSettings(loaded)
          : loaded;
      if (!mounted || gen != _generation || group != _group) return;
      _items = items;
      _original = {for (final i in items) i.key: i.value};
    } catch (e) {
      if (!mounted || gen != _generation || group != _group) return;
      _error = e;
    }
    if (mounted && gen == _generation) setState(() => _loading = false);
  }

  Future<void> _refresh() async {
    if (_loading || _saving) return;
    if (_hasChanges &&
        !await confirmDialog(context, S.current.discardUnsavedSettings,
            title: S.current.refresh)) {
      return;
    }
    if (mounted) await _load();
  }

  bool get _hasChanges =>
      _items.any((item) => !item.readOnly && _original[item.key] != item.value);

  Future<void> _save() async {
    if (_saving || _loading) return;
    final group = _group;
    final changed = _items
        .where((i) => !i.readOnly && _original[i.key] != i.value)
        .toList();
    if (changed.isEmpty) {
      showMessage(S.current.noChanges);
      return;
    }
    if (group == 9) {
      try {
        final buckets = _decodeBuckets();
        final names = <String>{};
        for (final bucket in buckets) {
          if (bucket['name']!.trim().isEmpty ||
              bucket['path']!.trim().isEmpty) {
            showMessage(S.current.s3BucketFieldsRequired);
            return;
          }
          if (!names.add(bucket['name']!.trim().toLowerCase())) {
            showMessage(S.current.s3BucketNamesMustBeUnique);
            return;
          }
        }
      } on FormatException {
        showMessage(S.current.s3InvalidBucketConfig);
        return;
      }
    }
    setState(() => _saving = true);
    try {
      final values = {for (final item in _items) item.key: item.value};
      final handled = <String>{};
      for (final config in offlineDownloadToolConfigs) {
        if (!changed.any((item) => config.fields.containsKey(item.key))) {
          continue;
        }
        await OpenListSession.instance.admin
            .configureOfflineDownload(config, values);
        handled.addAll(config.fields.keys);
      }
      final regular =
          changed.where((item) => !handled.contains(item.key)).toList();
      if (regular.isNotEmpty) {
        await OpenListSession.instance.admin.saveSettings(regular);
      }
      if (!mounted || group != _group) return;
      _original = {for (final i in _items) i.key: i.value};
      showMessage(S.current.saved);
    } catch (e) {
      if (mounted && group == _group) {
        showMessage(S.current.saveFailed(errorText(e)), seconds: 3);
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  List<Map<String, String>> _decodeBuckets() {
    final raw = _items.where((item) => item.key == 's3_buckets').firstOrNull;
    if (raw == null || raw.value.isEmpty) return [];
    final decoded = jsonDecode(raw.value);
    if (decoded is! List) throw const FormatException('Invalid bucket list');
    return decoded.map((value) {
      if (value is! Map ||
          (value['name'] != null && value['name'] is! String) ||
          (value['path'] != null && value['path'] is! String)) {
        throw const FormatException('Invalid bucket');
      }
      return {
        'name': '${value['name'] ?? ''}',
        'path': '${value['path'] ?? ''}',
      };
    }).toList();
  }

  void _setBuckets(List<Map<String, String>> buckets, {bool rebuild = false}) {
    var item = _items.where((item) => item.key == 's3_buckets').firstOrNull;
    if (item == null) {
      item = SettingItem({
        'key': 's3_buckets',
        'value': '[]',
        'type': 'string',
        'group': 9,
        'flag': 1,
      });
      _items.add(item);
      _original[item.key] = '';
    }
    setState(() {
      item!.value = jsonEncode(buckets);
      if (rebuild) _formGeneration++;
    });
  }

  Future<void> _loadDefaults() async {
    if (_loading || _saving) return;
    if (_hasChanges &&
        !await confirmDialog(context, S.current.discardUnsavedSettings,
            title: S.current.loadDefaultSettings)) {
      return;
    }
    if (!mounted || _loading || _saving) return;
    final group = _group;
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
      _formGeneration++;
    });
    try {
      final items = await OpenListSession.instance.admin.defaultSettings(group);
      if (!mounted || generation != _generation) return;
      final loaded = items.where((item) => !item.deprecated).toList();
      _items = group == _offlineDownloadGroup
          ? _completeOfflineSettings(loaded)
          : loaded;
      setState(() {
        _formGeneration++;
        _loading = false;
      });
    } catch (e) {
      if (mounted && generation == _generation) {
        setState(() {
          _error = e;
          _loading = false;
        });
      }
    }
  }

  Future<void> _selectGroup(int group) async {
    if (group == _group || _saving || _loading) return;
    if (_hasChanges &&
        !await confirmDialog(context, S.current.discardUnsavedSettings,
            title: S.current.coreSettings)) {
      return;
    }
    if (!mounted || _saving || _loading) return;
    setState(() => _group = group);
    await _load();
  }

  Future<void> _deleteSetting(SettingItem item) async {
    if (_saving || _loading) return;
    if (!await confirmDialog(context, S.current.deleteSettingConfirm(item.key),
        title: S.current.deleteSetting)) {
      return;
    }
    if (!mounted || _saving || _loading) return;
    setState(() => _saving = true);
    try {
      await OpenListSession.instance.admin.deleteSetting(item.key);
      _items.remove(item);
      _original.remove(item.key);
      if (mounted) showMessage(S.current.settingDeleted);
    } catch (e) {
      if (mounted) showError(e);
    }
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _generateS3Keys() async {
    final random = Random.secure();
    String generate(int size) =>
        base64Encode(List<int>.generate(size, (_) => random.nextInt(256)))
            .replaceAll('\n', '');
    final access =
        _items.where((item) => item.key == 's3_access_key_id').firstOrNull;
    final secret =
        _items.where((item) => item.key == 's3_secret_access_key').firstOrNull;
    if (access == null || secret == null) return;
    setState(() {
      access.value = generate(15);
      secret.value = generate(30);
      _formGeneration++;
    });
  }

  String _fieldLabel(String key) => switch (key) {
        'seed_site_url' => S.current.seedSiteUrl,
        'seed_default_trackers' => S.current.seedDefaultTrackers,
        's3_access_key_id' => S.current.s3AccessKeyId,
        's3_secret_access_key' => S.current.s3SecretAccessKey,
        _ => key,
      };

  Widget _field(SettingItem item) {
    final help = item.help.isEmpty ? null : item.help;
    final label = _fieldLabel(item.key);
    final key = ValueKey('$_group/${item.key}/$_formGeneration');
    if (item.type == 'bool') {
      return SwitchListTile(
        key: key,
        contentPadding: EdgeInsets.zero,
        title: Text(label),
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
            labelText: label, helperText: help, helperMaxLines: 3),
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
      onChanged: (value) => setState(() => item.value = value),
    );
  }

  Widget _offlineBody(BuildContext context) {
    final byKey = {for (final item in _items) item.key: item};
    final extra = _items
        .where((item) => !_offlineDownloadKeys.contains(item.key))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final config in offlineDownloadToolConfigs) ...[
          Text(config.name, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final key in config.fields.keys) ...[
            _field(byKey[key]!),
            const SizedBox(height: 12),
          ],
          const Divider(height: 24),
        ],
        for (final item in extra) ...[_field(item), const SizedBox(height: 12)],
      ],
    );
  }

  Widget _seedFields(BuildContext context) {
    final values = {for (final item in _items) item.key: item.value};
    final matrix = _seedMatrix(values['seed_default_matrix'] ?? '');
    final policies = _seedPolicies(values['seed_format_policies'] ?? '');
    final format =
        ['oss', 'torrent', 'cas'].contains(values['seed_default_format'])
            ? values['seed_default_format']!
            : 'oss';
    final trackers =
        _items.where((item) => item.key == 'seed_default_trackers').firstOrNull;
    Widget section(String title, List<Widget> children) => Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...children,
              ],
            ),
          ),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (final item in _items)
        if (item.key == 'seed_site_url') ...[
          _field(item),
          const SizedBox(height: 12)
        ],
      if (trackers != null) _settingField(trackers),
      section(S.current.seedDefaultMatrix, [
        Text(S.current.seedDefaultMatrixHelp),
        const SizedBox(height: 8),
        for (final algorithm in ['md5', 'sha1', 'sha256'])
          Column(children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(algorithm.toUpperCase(),
                  style: Theme.of(context).textTheme.titleSmall),
            ),
            Row(children: [
              Expanded(
                child: CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(S.current.seedWholeHash),
                  value: matrix[algorithm]!['whole']!,
                  onChanged: (value) {
                    matrix[algorithm]!['whole'] = value ?? false;
                    _setSeedJson('seed_default_matrix', matrix);
                  },
                ),
              ),
              Expanded(
                child: CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(S.current.seedPiecesHash),
                  value: matrix[algorithm]!['pieces']!,
                  onChanged: (value) {
                    matrix[algorithm]!['pieces'] = value ?? false;
                    _setSeedJson('seed_default_matrix', matrix);
                  },
                ),
              ),
            ]),
          ]),
      ]),
      section(S.current.seedFormatPolicies, [
        Text(S.current.seedFormatPoliciesHelp),
        for (final entry in policies.entries)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_seedFormatLabel(entry.key)),
            value: entry.value == 'on',
            onChanged: (enabled) {
              policies[entry.key] = enabled ? 'on' : 'off';
              _setSeedJson('seed_format_policies', policies);
            },
          ),
        DropdownButtonFormField<String>(
          value: format,
          decoration: InputDecoration(labelText: S.current.seedDefaultFormat),
          items: [
            for (final item in ['oss', 'torrent', 'cas'])
              DropdownMenuItem(
                  value: item, child: Text(_seedFormatLabel(item))),
          ],
          onChanged: (value) =>
              _setValue('seed_default_format', value ?? 'oss'),
        ),
      ]),
      for (final key in [
        'seed_auto_generate_policy',
        'seed_single_direct_preview',
        'seed_cas_direct_access',
      ])
        if (_items.any((item) => item.key == key))
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(switch (key) {
              'seed_auto_generate_policy' => S.current.seedAutoGenerate,
              'seed_single_direct_preview' => S.current.seedSingleDirectPreview,
              _ => S.current.seedCasDirectAccess,
            }),
            value: key == 'seed_auto_generate_policy'
                ? values[key] == 'on'
                : values[key] == 'true',
            onChanged: (enabled) => _setValue(
                key,
                key == 'seed_auto_generate_policy'
                    ? (enabled ? 'on' : 'off')
                    : (enabled ? 'true' : 'false')),
          ),
    ]);
  }

  Map<String, Map<String, bool>> _seedMatrix(String value) {
    final result = <String, Map<String, bool>>{
      for (final algorithm in ['md5', 'sha1', 'sha256'])
        algorithm: {'whole': true, 'pieces': false},
    };
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map) {
        for (final algorithm in result.keys) {
          final entry = decoded[algorithm];
          if (entry is Map) {
            result[algorithm] = {
              'whole': entry['whole'] is bool ? entry['whole'] as bool : true,
              'pieces':
                  entry['pieces'] is bool ? entry['pieces'] as bool : false,
            };
          }
        }
      }
    } on FormatException {
      return result;
    }
    return result;
  }

  Map<String, String> _seedPolicies(String value) {
    final result = {
      for (final format in ['oss', 'torrent', 'cas']) format: 'off'
    };
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map) {
        for (final format in result.keys) {
          result[format] = decoded[format] == 'on' ? 'on' : 'off';
        }
      }
    } on FormatException {
      return result;
    }
    return result;
  }

  String _seedFormatLabel(String format) => switch (format) {
        'torrent' => S.current.seedFormatTorrent,
        'cas' => S.current.seedFormatCas,
        _ => S.current.seedFormatOss,
      };

  void _setValue(String key, String value) {
    final item = _items.where((item) => item.key == key).firstOrNull;
    if (item != null) {
      setState(() {
        item.value = value;
        _formGeneration++;
      });
    }
  }

  void _setSeedJson(String key, Map<String, dynamic> value) =>
      _setValue(key, jsonEncode(value));

  Widget _s3Buckets(BuildContext context) {
    final List<Map<String, String>> buckets;
    try {
      buckets = _decodeBuckets();
    } on FormatException {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(S.current.s3InvalidBucketConfig),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _setBuckets([], rebuild: true),
                icon: const Icon(Icons.restart_alt),
                label: Text(S.current.s3ResetBuckets),
              ),
            ],
          ),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(S.current.s3Buckets,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(S.current.s3RestartToApply,
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            for (var i = 0; i < buckets.length; i++)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(children: [
                    TextFormField(
                      key: ValueKey('s3-bucket-$_formGeneration-$i-name'),
                      initialValue: buckets[i]['name'],
                      decoration:
                          InputDecoration(labelText: S.current.s3BucketName),
                      onChanged: (value) {
                        buckets[i]['name'] = value;
                        _setBuckets(buckets);
                      },
                    ),
                    TextFormField(
                      key: ValueKey('s3-bucket-$_formGeneration-$i-path'),
                      initialValue: buckets[i]['path'],
                      decoration:
                          InputDecoration(labelText: S.current.s3BucketPath),
                      onChanged: (value) {
                        buckets[i]['path'] = value;
                        _setBuckets(buckets);
                      },
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        tooltip: S.current.delete,
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () {
                          buckets.removeAt(i);
                          _setBuckets(buckets, rebuild: true);
                        },
                      ),
                    ),
                  ]),
                ),
              ),
            OutlinedButton.icon(
              onPressed: () => _setBuckets([
                ...buckets,
                {'name': '', 'path': ''},
              ], rebuild: true),
              icon: const Icon(Icons.add),
              label: Text(S.current.s3AddBucket),
            ),
            OutlinedButton.icon(
              onPressed: _generateS3Keys,
              icon: const Icon(Icons.key),
              label: Text(S.current.s3GenerateKeys),
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingField(SettingItem item) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _field(item),
          if (!item.readOnly)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _saving ? null : () => _deleteSetting(item),
                icon: const Icon(Icons.delete_outline),
                label: Text(S.current.deleteSetting),
              ),
            ),
          const SizedBox(height: 12),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: _allowExit || (!_hasChanges && !_saving),
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || _saving || !_hasChanges) return;
        final navigator = Navigator.of(context);
        final discard = await confirmDialog(
            context, S.current.discardUnsavedSettings,
            title: S.current.coreSettings);
        if (!discard || !mounted) return;
        setState(() => _allowExit = true);
        navigator.pop(result);
      },
      child: Scaffold(
        appBar: AppBar(title: Text(S.of(context).coreSettings), actions: [
          IconButton(
            tooltip: S.current.refresh,
            icon: const Icon(Icons.refresh),
            onPressed: _loading || _saving ? null : _refresh,
          ),
          IconButton(
            tooltip: S.current.loadDefaultSettings,
            icon: const Icon(Icons.restore),
            onPressed: _loading || _saving ? null : _loadDefaults,
          ),
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
                      onSelected: (_) => _selectGroup(id),
                    ),
                  ),
              ],
            ),
          ),
          if (_loading || _saving) const LinearProgressIndicator(),
          Expanded(child: _body(context)),
        ]),
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (_error != null) {
      return StateMessage(
          icon: Icons.error_outline,
          text: errorText(_error!),
          action: S.of(context).retry,
          onAction: _refresh);
    }
    if (_loading) return const SizedBox.shrink();
    final seedOnlyKeys = {
      'seed_site_url',
      'seed_default_trackers',
      'seed_default_matrix',
      'seed_format_policies',
      'seed_default_format',
      'seed_auto_generate_policy',
      'seed_single_direct_preview',
      'seed_cas_direct_access',
    };
    return AbsorbPointer(
      absorbing: _saving,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        if (_group == _offlineDownloadGroup && _token != null) ...[
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
        if (_group == _offlineDownloadGroup)
          _offlineBody(context)
        else ...[
          if (_group == 4) _seedFields(context),
          if (_group == 9) _s3Buckets(context),
          for (final item in _items)
            if (!(_group == 4 && seedOnlyKeys.contains(item.key)) &&
                !(_group == 9 && item.key == 's3_buckets'))
              _settingField(item),
        ],
      ]),
    );
  }
}
