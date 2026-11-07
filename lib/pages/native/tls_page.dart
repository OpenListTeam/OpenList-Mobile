import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:openlist_mobile/utils/service_manager.dart';

import '../../contant/native_bridge.dart';
import '../../generated/l10n.dart';
import 'common.dart';

/// True when [text] holds a PEM block of the wanted kind.
bool isPem(String text, {required bool key}) {
  final m = RegExp(r'-----BEGIN ([A-Z0-9 ]+)-----').firstMatch(text);
  if (m == null || !text.contains('-----END ${m.group(1)}-----')) return false;
  final label = m.group(1)!;
  return key ? label.endsWith('PRIVATE KEY') : label == 'CERTIFICATE';
}

/// Configures the core's HTTPS port, certificate and key in `config.json`.
///
/// Picked files are copied into `<data>/cert/` so the core can read them after
/// the picker's cache is cleared. Only `scheme` fields are touched; every other
/// key in the file round-trips unchanged.
class TlsPage extends StatefulWidget {
  const TlsPage({super.key});

  @override
  State<TlsPage> createState() => _TlsPageState();
}

class _TlsPageState extends State<TlsPage> {
  final _formKey = GlobalKey<FormState>();
  final _port = TextEditingController();
  String _dataDir = '';
  Map<String, dynamic>? _config;
  String _certFile = '';
  String _keyFile = '';
  bool _forceHttps = false;
  Object? _error;
  bool _saving = false;

  File get _configFile => File('$_dataDir/config.json');

  Map<String, dynamic> get _scheme =>
      Map<String, dynamic>.from((_config?['scheme'] as Map?) ?? const {});

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _port.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      _dataDir = await NativeBridge.appConfig.getDataDir();
      // The core creates config.json on its first start.
      final config = Map<String, dynamic>.from(
        jsonDecode(await _configFile.readAsString()) as Map,
      );
      final scheme = Map<String, dynamic>.from(
        (config['scheme'] as Map?) ?? const {},
      );
      _config = config;
      _port.text = '${scheme['https_port'] ?? -1}';
      _certFile = '${scheme['cert_file'] ?? ''}';
      _keyFile = '${scheme['key_file'] ?? ''}';
      _forceHttps = scheme['force_https'] == true;
    } catch (e) {
      _error = e;
    }
    if (mounted) setState(() {});
  }

  /// Copies a picked PEM file into the data dir and remembers its path.
  Future<void> _pick({required bool key}) async {
    final picked = await FilePicker.pickFile();
    final path = picked?.path;
    if (path == null) return;
    try {
      final text = await File(path).readAsString();
      if (!isPem(text, key: key)) {
        showMessage(S.current.invalidPem, seconds: 3);
        return;
      }
      final dir = Directory('$_dataDir/cert');
      await dir.create(recursive: true);
      final dst = File('${dir.path}/${key ? 'key.pem' : 'cert.pem'}');
      await dst.writeAsString(text, flush: true);
      setState(() => key ? _keyFile = dst.path : _certFile = dst.path);
    } catch (e) {
      showError(e);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final port = int.parse(_port.text.trim());
    if (port > 0 && (_certFile.isEmpty || _keyFile.isEmpty)) {
      showMessage(S.current.tlsNeedsCert, seconds: 3);
      return;
    }
    setState(() => _saving = true);
    try {
      final config = Map<String, dynamic>.from(_config!);
      config['scheme'] = _scheme
        ..['https_port'] = port
        ..['cert_file'] = _certFile
        ..['key_file'] = _keyFile
        ..['force_https'] = port > 0 && _forceHttps;
      final text = const JsonEncoder.withIndent('  ').convert(config);
      if (await _configFile.exists()) {
        await _configFile.copy('$_dataDir/config.json.backup');
      }
      await _configFile.writeAsString(text, flush: true);
      _config = config;
      if (!mounted) return;
      setState(() => _saving = false);
      await _offerRestart();
    } catch (e) {
      showMessage(S.current.saveFailed(errorText(e)), seconds: 3);
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _offerRestart() async {
    final sm = ServiceManager.instance;
    if (!sm.isServiceRunning) {
      showMessage(S.current.saved);
      return;
    }
    final restart = await confirmDialog(
      context,
      S.current.configSavedRestartRequired,
      title: S.current.saveAndRestart,
    );
    if (!restart) return;
    showMessage(
      await sm.restartService()
          ? S.current.serviceRestartSuccess
          : S.current.serviceRestartFailed,
    );
  }

  Widget _fileTile(String title, String path, {required bool key}) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(title),
    subtitle: Text(path.isEmpty ? S.of(context).notConfigured : path),
    trailing: TextButton(
      onPressed: _saving ? null : () => _pick(key: key),
      child: Text(S.of(context).chooseFile),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).tlsCertificate),
        actions: [
          IconButton(
            tooltip: S.of(context).save,
            icon: const Icon(Icons.check),
            onPressed: _saving || _config == null ? null : _save,
          ),
        ],
      ),
      body: _body(context),
    );
  }

  Widget _body(BuildContext context) {
    if (_error != null) {
      return StateMessage(icon: Icons.error_outline, text: errorText(_error!));
    }
    if (_config == null)
      return const Center(child: CircularProgressIndicator());
    return AbsorbPointer(
      absorbing: _saving,
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_saving) const LinearProgressIndicator(),
            TextFormField(
              controller: _port,
              keyboardType: const TextInputType.numberWithOptions(signed: true),
              decoration: InputDecoration(labelText: S.of(context).httpsPort),
              validator: (v) {
                final p = int.tryParse((v ?? '').trim());
                if (p == null || (p != -1 && (p < 1 || p > 65535))) {
                  return S.current.invalidPort;
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            _fileTile(S.of(context).certFile, _certFile, key: false),
            _fileTile(S.of(context).keyFile, _keyFile, key: true),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(S.of(context).forceHttps),
              value: _forceHttps,
              onChanged: (v) => setState(() => _forceHttps = v),
            ),
          ],
        ),
      ),
    );
  }
}
