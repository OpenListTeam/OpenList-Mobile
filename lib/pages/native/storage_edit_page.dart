import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:openlist_mobile/api/models.dart';
import 'package:openlist_mobile/api/session.dart';
import 'package:openlist_mobile/utils/android_storage_permission.dart';
import 'package:openlist_mobile/utils/driver_localization.dart';

import '../../generated/l10n.dart';
import 'common.dart';

/// Converts a form value to the JSON type the core expects for [type].
dynamic typedValue(String type, dynamic v) {
  switch (type) {
    case 'bool':
      return v == true || v == 'true';
    case 'number':
    case 'int':
    case 'int8':
    case 'int16':
    case 'int32':
    case 'int64':
    case 'uint':
    case 'uint8':
    case 'uint16':
    case 'uint32':
    case 'uint64':
      return v is num ? v.toInt() : int.tryParse('$v'.trim()) ?? 0;
    case 'float':
    case 'float32':
    case 'float64':
      return v is num ? v.toDouble() : double.tryParse('$v'.trim()) ?? 0.0;
    default:
      return v == null ? '' : '$v';
  }
}

bool isBoolType(String type) => type == 'bool';

/// Create or edit a storage with a form generated from driver info.
class StorageEditPage extends StatefulWidget {
  const StorageEditPage({super.key, this.storage});

  /// Null when creating a new storage.
  final Storage? storage;

  @override
  State<StorageEditPage> createState() => _StorageEditPageState();
}

class _StorageEditPageState extends State<StorageEditPage> {
  final _formKey = GlobalKey<FormState>();
  List<String> _drivers = const [];
  String? _driver;
  DriverInfo? _info;
  Object? _error;
  bool _loading = true;
  bool _saving = false;

  /// Current values keyed by item name, for common and additional items.
  final Map<String, dynamic> _common = {};
  final Map<String, dynamic> _addition = {};
  Map<String, dynamic> _rawAddition = {};

  bool get _isNew => widget.storage == null;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final admin = OpenListSession.instance.admin;
      if (_isNew) {
        _drivers = (await admin.driverNames())..sort();
        _loading = false;
      } else {
        await _selectDriver(widget.storage!.driver);
        return;
      }
    } catch (e) {
      _error = e;
      _loading = false;
    }
    if (mounted) setState(() {});
  }

  Future<void> _selectDriver(String driver) async {
    setState(() {
      _driver = driver;
      _loading = true;
      _error = null;
    });
    try {
      final info = await OpenListSession.instance.admin.driverInfo(driver);
      _common.clear();
      _addition.clear();
      final raw = widget.storage?.raw ?? const {};
      Map<String, dynamic> added = {};
      final a = widget.storage?.addition ?? '';
      if (a.isNotEmpty) {
        try {
          added = Map<String, dynamic>.from(jsonDecode(a));
        } catch (_) {}
      }
      _rawAddition = added;
      for (final i in info.common) {
        _common[i.name] = raw.containsKey(i.name)
            ? raw[i.name]
            : i.defaultValue;
      }
      for (final i in info.additional) {
        _addition[i.name] = added.containsKey(i.name)
            ? added[i.name]
            : i.defaultValue;
      }
      _info = info;
    } catch (e) {
      _error = e;
    }
    if (mounted) setState(() => _loading = false);
  }

  /// Builds the request body; edits start from the raw storage so fields the
  /// form does not show are preserved.
  Map<String, dynamic> _body() {
    final info = _info!;
    final body = widget.storage?.toJson() ?? <String, dynamic>{};
    body['driver'] = _driver;
    for (final i in info.common) {
      body[i.name] = typedValue(i.type, _common[i.name]);
    }
    final addition = Map<String, dynamic>.from(_rawAddition);
    for (final i in info.additional) {
      addition[i.name] = typedValue(i.type, _addition[i.name]);
    }
    body['addition'] = jsonEncode(addition);
    return body;
  }

  Future<void> _save() async {
    if (_info == null || !(_formKey.currentState?.validate() ?? false)) return;
    if (Platform.isAndroid && _driver == 'Local') {
      if (!await AndroidStoragePermission.ensure(context)) return;
    }
    if (!mounted) return;
    setState(() => _saving = true);
    try {
      final admin = OpenListSession.instance.admin;
      _isNew
          ? await admin.createStorage(_body())
          : await admin.updateStorage(_body());
      // Pop before the snackbar; Get.back would only dismiss the snackbar.
      if (mounted) Navigator.of(context).pop(true);
      showMessage(S.current.saved);
    } catch (e) {
      showMessage(S.current.saveFailed(errorText(e)), seconds: 3);
    }
    if (mounted) setState(() => _saving = false);
  }

  /// Driver notice from `config.alert`, colored by its level.
  Widget _alert(DriverInfo info) {
    final scheme = Theme.of(context).colorScheme;
    final (icon, color) = switch (info.alertLevel) {
      'danger' => (Icons.error_outline, scheme.error),
      'warning' => (Icons.warning_amber_outlined, Colors.orange),
      'success' => (Icons.check_circle_outline, Colors.green),
      _ => (Icons.info_outline, scheme.primary),
    };
    final displayText = DriverLocalization.alertText(
      languageCode: Localizations.localeOf(context).languageCode,
      driver: _driver ?? '',
      text: info.alertText,
    );
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: color.withValues(alpha: 0.08),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(displayText),
      ),
    );
  }

  Widget _field(DriverItem item, Map<String, dynamic> values) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final translatedName = DriverLocalization.fieldLabel(
      languageCode: languageCode,
      driver: _driver ?? '',
      field: item.name,
      fallback: item.name,
    );
    final translatedHelp = DriverLocalization.fieldLabel(
      languageCode: languageCode,
      driver: _driver ?? '',
      field: '${item.name}.help',
      fallback: item.help,
    );
    final label = item.required ? '$translatedName *' : translatedName;
    final help = translatedHelp.isEmpty ? null : translatedHelp;
    final value = values[item.name];
    // Keyed by driver so switching drivers resets the field state.
    final key = ValueKey('$_driver/${item.name}');
    if (isBoolType(item.type)) {
      return SwitchListTile(
        key: key,
        contentPadding: EdgeInsets.zero,
        title: Text(translatedName),
        subtitle: help == null ? null : Text(help),
        value: typedValue('bool', value) as bool,
        onChanged: (v) => setState(() => values[item.name] = v),
      );
    }
    if (item.type == 'select' && item.optionList.isNotEmpty) {
      final options = item.optionList;
      final current = '$value';
      return DropdownButtonFormField<String>(
        key: key,
        value: options.contains(current) ? current : null,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          helperText: help,
          helperMaxLines: 3,
        ),
        items: [
          for (final o in options)
            DropdownMenuItem(
              value: o,
              child: Text(
                DriverLocalization.optionLabel(
                  languageCode: languageCode,
                  driver: _driver ?? '',
                  field: item.name,
                  option: o,
                ),
              ),
            ),
        ],
        onChanged: (v) => values[item.name] = v ?? '',
        validator: (v) => item.required && (v == null || v.isEmpty)
            ? S.current.requiredField
            : null,
      );
    }
    final numeric = typedValue(item.type, '1') is num;
    return TextFormField(
      key: key,
      initialValue: value == null ? '' : '$value',
      minLines: item.type == 'text' ? 2 : 1,
      maxLines: item.type == 'text' ? 6 : 1,
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(signed: true, decimal: true)
          : null,
      decoration: InputDecoration(
        labelText: label,
        helperText: help,
        helperMaxLines: 3,
      ),
      onChanged: (v) => values[item.name] = v,
      validator: (v) {
        final t = (v ?? '').trim();
        if (item.required && t.isEmpty) return S.current.requiredField;
        if (numeric && t.isNotEmpty && num.tryParse(t) == null) {
          return S.current.requiredField;
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final info = _info;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isNew ? S.of(context).addStorage : S.of(context).editStorage,
        ),
        actions: [
          IconButton(
            tooltip: S.of(context).save,
            icon: const Icon(Icons.check),
            onPressed: _saving || info == null ? null : _save,
          ),
        ],
      ),
      body: AbsorbPointer(
        absorbing: _saving,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_saving || (_loading && info != null))
                const LinearProgressIndicator(),
              if (_isNew)
                DropdownButtonFormField<String>(
                  value: _driver,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: S.of(context).driver),
                  items: [
                    for (final d in _drivers)
                      DropdownMenuItem(
                        value: d,
                        child: Text(
                          DriverLocalization.driverLabel(
                            languageCode: Localizations.localeOf(context)
                                .languageCode,
                            driver: d,
                          ),
                        ),
                      ),
                  ],
                  onChanged: (d) {
                    if (d != null && d != _driver) _selectDriver(d);
                  },
                )
              else
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(S.of(context).driver),
                  subtitle: Text(widget.storage!.driver),
                ),
              const SizedBox(height: 12),
              if (_loading && info == null)
                const Center(child: CircularProgressIndicator())
              else if (_error != null)
                StateMessage(
                  icon: Icons.error_outline,
                  text: errorText(_error!),
                )
              else if (info != null) ...[
                if (info.alertText.isNotEmpty) _alert(info),
                if (info.noUpload)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.upload_file_outlined),
                    title: Text(S.of(context).driverNoUpload),
                  ),
                for (final i in info.common) ...[
                  _field(i, _common),
                  const SizedBox(height: 12),
                ],
                const Divider(),
                for (final i in info.additional) ...[
                  _field(i, _addition),
                  const SizedBox(height: 12),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
