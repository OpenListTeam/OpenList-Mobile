import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:openlist_mobile/generated_api.dart';
import 'package:openlist_mobile/utils/service_manager.dart';

import '../../generated/l10n.dart';
import 'common.dart';
import 'tls_page.dart';

const _modes = ['local', 'lan', 'public'];

String _modeLabel(String m) => switch (m) {
  'lan' => S.current.modeLan,
  'public' => S.current.modePublic,
  _ => S.current.modeLocal,
};

String _modeDesc(String m) => switch (m) {
  'lan' => S.current.modeLanDesc,
  'public' => S.current.modePublicDesc,
  _ => S.current.modeLocalDesc,
};

String _checkLabel(String id) => switch (id) {
  'tls' => S.current.checkTls,
  'force_https' => S.current.checkForceHttps,
  'guest_disabled' => S.current.checkGuestDisabled,
  's3_tls' => S.current.checkS3Tls,
  'ftp_plaintext' => S.current.checkFtpPlaintext,
  'admin_2fa' => S.current.checkAdmin2fa,
  'not_initialized' => S.current.checkNotInitialized,
  _ => id,
};

/// Server runtime: exposure mode, security checks, status and diagnostics.
class ServerPage extends StatefulWidget {
  const ServerPage({super.key});

  @override
  State<ServerPage> createState() => _ServerPageState();
}

class _ServerPageState extends State<ServerPage> {
  final _sm = ServiceManager.instance;
  StreamSubscription<ServerStatus>? _sub;
  Timer? _timer;

  String _mode = 'local';
  ServerStatus? _status;
  Map<String, dynamic> _report = const {};
  Map<String, dynamic> _runtime = const {};
  BackgroundDiagnostics? _diag;

  @override
  void initState() {
    super.initState();
    _status = _sm.status;
    _sub = _sm.serverStatusStream.listen((s) {
      if (mounted) setState(() => _status = s);
    });
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _loadRuntime());
    _load();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  static Map<String, dynamic> _json(String s) {
    try {
      final v = jsonDecode(s);
      return v is Map ? Map<String, dynamic>.from(v) : {};
    } catch (_) {
      return {};
    }
  }

  Future<void> _load() async {
    try {
      _mode = await _sm.getMode();
      _report = _json(await _sm.getSecurityReport(_mode));
      _diag = await _sm.getBackgroundDiagnostics();
    } catch (e) {
      showError(e);
    }
    await _loadRuntime();
  }

  Future<void> _loadRuntime() async {
    try {
      final r = _json(await _sm.getRuntimeStatus());
      if (mounted) setState(() => _runtime = r);
    } catch (_) {}
  }

  Future<void> _selectMode(String mode) async {
    if (mode == _mode) return;
    final report = _json(await _sm.getSecurityReport(mode));
    if (!mounted) return;
    // Do not persist a mode the core would refuse to start with.
    if (report['blocked'] == true) {
      setState(() => _report = report);
      showMessage(S.current.publicBlocked, seconds: 4);
      return;
    }
    if (mode == 'public' &&
        !await confirmDialog(
          context,
          S.current.publicModeWarning,
          title: S.current.modePublic,
        )) {
      return;
    }
    try {
      await _sm.setMode(mode);
      setState(() {
        _mode = mode;
        _report = report;
      });
      if (_status?.running ?? false) {
        showMessage(S.current.modeChangeRestart, seconds: 3);
      }
    } catch (e) {
      showError(e);
    }
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
    child: Text(
      title,
      style: Theme.of(context).textTheme.titleSmall
          ?.copyWith(color: Theme.of(context).colorScheme.primary),
    ),
  );

  List<String> _urls(ServerStatus s) {
    final https = s.httpsPort > 0 && (s.forceHttps || s.httpPort <= 0);
    final port = https ? s.httpsPort : s.httpPort;
    final hosts = s.addresses.isEmpty ? ['127.0.0.1'] : s.addresses;
    return [for (final h in hosts) '${https ? 'https' : 'http'}://$h:$port'];
  }

  Widget _check(Map c) {
    final level = '${c['level']}';
    final scheme = Theme.of(context).colorScheme;
    final (icon, color) = switch (level) {
      'ok' => (Icons.check_circle, scheme.primary),
      'block' => (Icons.block, scheme.error),
      _ => (Icons.warning_amber, Colors.orange),
    };
    final detail = '${c['detail'] ?? ''}';
    return ListTile(
      dense: true,
      leading: Icon(icon, color: color),
      title: Text(_checkLabel('${c['id']}')),
      subtitle: detail.isEmpty ? null : Text(detail),
    );
  }

  List<Widget> _runtimeTiles() {
    final r = _runtime;
    int n(String k) => (r[k] is num) ? (r[k] as num).toInt() : 0;
    Widget row(String k, String v) =>
        ListTile(dense: true, title: Text(k), trailing: Text(v));
    return [
      if (r['uptime_sec'] != null)
        row(S.current.uptime, formatDuration(n('uptime_sec'))),
      if (r['goroutines'] != null)
        row(S.current.goroutines, '${n('goroutines')}'),
      if (r['heap_alloc'] != null)
        row(
          S.current.memory,
          '${formatBytes(n('heap_alloc'))} / ${formatBytes(n('sys'))}',
        ),
      if (r['pss_kb'] != null)
        row(S.current.processMemory, formatBytes(n('pss_kb') * 1024)),
      if (r['cpu_time_ms'] != null)
        row(S.current.cpuTime, formatDuration(n('cpu_time_ms') ~/ 1000)),
    ];
  }

  List<Widget> _backgroundTiles() {
    final d = _diag;
    if (Platform.isIOS) {
      return [ListTile(dense: true, title: Text(S.current.iosBackgroundNote))];
    }
    if (d == null) return const [];
    return [
      ListTile(
        leading: const Icon(Icons.battery_saver),
        title: Text(S.current.batteryOptimization),
        subtitle: Text(
          d.ignoringBatteryOptimizations
              ? S.current.batteryOptimizationIgnored
              : S.current.batteryOptimizationActive,
        ),
        trailing: d.ignoringBatteryOptimizations
            ? null
            : TextButton(
                onPressed: () async {
                  await _sm.requestIgnoreBatteryOptimization();
                  _diag = await _sm.getBackgroundDiagnostics();
                  if (mounted) setState(() {});
                },
                child: Text(S.current.requestIgnoreBattery),
              ),
      ),
      if (d.backgroundRestricted)
        ListTile(
          leading: const Icon(Icons.warning_amber, color: Colors.orange),
          title: Text(S.current.backgroundRestricted),
          onTap: _sm.openAppDetailsSettings,
        ),
      if (!d.notificationsEnabled)
        ListTile(
          leading: const Icon(Icons.notifications_off),
          title: Text(S.current.notificationsDisabled),
          onTap: _sm.openAppDetailsSettings,
        ),
      if (d.autoStartSettingsAvailable)
        ListTile(
          leading: const Icon(Icons.rocket_launch_outlined),
          title: Text(S.current.autoStartSettings),
          subtitle: Text(S.current.autoStartSettingsDesc),
          onTap: _sm.openAutoStartSettings,
        ),
      ListTile(
        dense: true,
        title: Text('${d.manufacturer} / ${d.brand} · SDK ${d.sdkInt}'),
        subtitle: d.standbyBucket >= 0
            ? Text('${S.current.standbyBucket}: ${d.standbyBucket}')
            : null,
        trailing: TextButton(
          onPressed: _sm.openAppDetailsSettings,
          child: Text(S.current.appDetails),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final s = _status;
    final running = s?.running ?? false;
    final checks = (_report['checks'] as List?) ?? const [];
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).serverRuntime)),
      body: RefreshIndicator(
        onRefresh: () async {
          await _sm.checkServiceStatus();
          await _load();
        },
        child: ListView(
          children: [
            ListTile(
              leading: Icon(
                running ? Icons.cloud_done : Icons.cloud_off,
                color: running ? Theme.of(context).colorScheme.primary : null,
              ),
              title: Text(
                running ? S.of(context).running : S.of(context).stopped,
              ),
              subtitle: Text(_modeLabel(s?.mode ?? _mode)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                children: [
                  if (!running)
                    FilledButton(
                      onPressed: _sm.startService,
                      child: Text(S.of(context).startServer),
                    ),
                  if (running) ...[
                    OutlinedButton(
                      onPressed: _sm.stopService,
                      child: Text(S.of(context).stopServer),
                    ),
                    OutlinedButton(
                      onPressed: _sm.restartService,
                      child: Text(S.of(context).restartServer),
                    ),
                  ],
                ],
              ),
            ),
            if ((s?.lastError ?? '').isNotEmpty)
              ListTile(
                leading: Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(S.of(context).lastError),
                subtitle: Text(s!.lastError!),
              ),
            if (running && s != null) ...[
              _section(S.of(context).addresses),
              for (final u in _urls(s))
                ListTile(
                  dense: true,
                  title: SelectableText(u),
                  trailing: IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: u));
                      showMessage(S.current.copiedToClipboard);
                    },
                  ),
                ),
            ],
            _section(S.of(context).exposureMode),
            ListTile(
              leading: const Icon(Icons.https_outlined),
              title: Text(S.of(context).tlsCertificate),
              trailing: const Icon(Icons.chevron_right),
              onTap: () =>
                  Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => const TlsPage()))
                      .then((_) => _load()),
            ),
            RadioGroupFallback(
              value: _mode,
              options: _modes,
              label: _modeLabel,
              description: _modeDesc,
              onChanged: _selectMode,
            ),
            if (checks.isNotEmpty) ...[
              _section(S.of(context).securityChecks),
              if (_report['blocked'] == true)
                ListTile(
                  dense: true,
                  leading: Icon(
                    Icons.block,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(S.of(context).publicBlocked),
                ),
              for (final c in checks)
                if (c is Map) _check(c),
            ],
            if (running && _runtime.isNotEmpty) ...[
              _section(S.of(context).runtimeStatus),
              ..._runtimeTiles(),
            ],
            _section(S.of(context).backgroundRunning),
            ..._backgroundTiles(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// Radio list built from plain tiles, avoiding the Radio API churn across
/// Flutter versions.
class RadioGroupFallback extends StatelessWidget {
  const RadioGroupFallback({
    super.key,
    required this.value,
    required this.options,
    required this.label,
    required this.description,
    required this.onChanged,
  });

  final String value;
  final List<String> options;
  final String Function(String) label;
  final String Function(String) description;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final o in options)
          ListTile(
            leading: Icon(
              o == value
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: o == value ? Theme.of(context).colorScheme.primary : null,
            ),
            title: Text(label(o)),
            subtitle: Text(description(o)),
            onTap: () => onChanged(o),
          ),
      ],
    );
  }
}
