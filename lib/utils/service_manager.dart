import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:openlist_mobile/generated_api.dart';

/// Service Manager - client of the native server runtime.
///
/// On Android the server lives in a separate `:server` process; on iOS it runs
/// in-process. Both are reached through the Pigeon [ServerApi], and status and
/// logs are pushed back through the [Event] Flutter API.
class ServiceManager {
  static ServiceManager? _instance;
  static ServiceManager get instance => _instance ??= ServiceManager._();

  ServiceManager._();

  final ServerApi _server = ServerApi();
  final BackgroundApi _background = BackgroundApi();

  final StreamController<bool> _serviceStatusController =
      StreamController<bool>.broadcast();
  final StreamController<ServerStatus> _serverStatusController =
      StreamController<ServerStatus>.broadcast();
  final StreamController<LogEntry> _logController =
      StreamController<LogEntry>.broadcast();

  /// Running state stream (deduplicated).
  Stream<bool> get serviceStatusStream => _serviceStatusController.stream;

  /// Full server status stream (mode, ports, addresses, last error).
  Stream<ServerStatus> get serverStatusStream => _serverStatusController.stream;

  /// Live server log stream.
  Stream<LogEntry> get logStream => _logController.stream;

  bool _isServiceRunning = false;
  ServerStatus? _status;
  Timer? _statusCheckTimer;
  bool _initialized = false;

  bool get isServiceRunning => _isServiceRunning;
  ServerStatus? get status => _status;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    Event.setUp(_ServerEvents(this));
    // Status is pushed by native; polling is only a fallback.
    _statusCheckTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => checkServiceStatus(),
    );
    await checkServiceStatus();
  }

  Future<bool> startService() => _call('start', _server.start);

  Future<void> ensureServiceRunning() async {
    await checkServiceStatus();
    if (_status?.running != true) await startService();
  }

  Future<bool> stopService() async {
    final ok = await _call('stop', _server.stop);
    if (ok && Platform.isIOS) unawaited(checkServiceStatus());
    return ok;
  }

  Future<bool> restartService() => _call('restart', _server.restart);

  Future<bool> restartServiceAndWait({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (await checkServiceStatus()) {
      if (!await stopService() ||
          !await _waitForServiceStatus(false, timeout)) {
        return false;
      }
    }
    if (!await startService()) return false;
    return _waitForServiceStatus(true, timeout);
  }

  Future<bool> _waitForServiceStatus(bool running, Duration timeout) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (await checkServiceStatus() == running) return true;
      await Future.delayed(const Duration(milliseconds: 200));
    }
    return false;
  }

  Future<bool> _call(String name, Future<void> Function() fn) async {
    try {
      await fn();
      return true;
    } catch (e) {
      debugPrint('ServiceManager.$name failed: $e');
      return false;
    }
  }

  Future<bool> checkServiceStatus() async {
    try {
      _onStatus(await _server.getStatus());
    } catch (e) {
      debugPrint('Failed to check service status: $e');
    }
    return _isServiceRunning;
  }

  Future<String> getMode() => _server.getMode();

  Future<void> setMode(String mode) => _server.setMode(mode);

  Future<void> setAdminPassword(String pwd) => _server.setAdminPassword(pwd);

  /// Admin JWT for the in-app native client; only available while running.
  Future<String> getLocalToken() => _server.getLocalToken();

  Future<String> getRuntimeStatus() => _server.getRuntimeStatus();

  Future<String> getSecurityReport(String mode) =>
      _server.getSecurityReport(mode);

  Future<List<LogEntry>> getRecentLogs() async {
    try {
      return await _server.getRecentLogs();
    } catch (e) {
      debugPrint('Failed to get recent logs: $e');
      return const [];
    }
  }

  /// Primary URL of the running server, or '' when stopped.
  Future<String> getServiceAddress() async {
    final s = _status ?? await _server.getStatus().catchError((_) => _stopped);
    if (!s.running) return '';
    final host = s.addresses.isNotEmpty ? s.addresses.first : '127.0.0.1';
    final https = s.httpsPort > 0 && (s.forceHttps || s.httpPort <= 0);
    return https
        ? 'https://$host:${s.httpsPort}'
        : 'http://$host:${s.httpPort}';
  }

  // ---- Background running (Android only) ----

  Future<BackgroundDiagnostics?> getBackgroundDiagnostics() async {
    if (!Platform.isAndroid) return null;
    try {
      return await _background.getDiagnostics();
    } catch (e) {
      debugPrint('Failed to get background diagnostics: $e');
      return null;
    }
  }

  Future<bool> isBatteryOptimizationIgnored() async {
    if (!Platform.isAndroid) return true;
    return (await getBackgroundDiagnostics())?.ignoringBatteryOptimizations ??
        false;
  }

  Future<bool> requestIgnoreBatteryOptimization() =>
      _android(_background.requestIgnoreBatteryOptimizations, true);

  Future<bool> openBatteryOptimizationSettings() =>
      _android(_background.openBatteryOptimizationSettings, false);

  Future<bool> openAutoStartSettings() =>
      _android(_background.openAutoStartSettings, false);

  Future<bool> openAppDetailsSettings() =>
      _android(_background.openAppDetailsSettings, false);

  Future<bool> _android(Future<bool> Function() fn, bool otherwise) async {
    if (!Platform.isAndroid) return otherwise;
    try {
      return await fn();
    } catch (e) {
      debugPrint('Background API call failed: $e');
      return false;
    }
  }

  static final ServerStatus _stopped = ServerStatus(
    running: false,
    mode: 'local',
    httpPort: 5244,
    httpsPort: -1,
    forceHttps: false,
    addresses: const [],
    manuallyStopped: false,
  );

  void _onStatus(ServerStatus s) {
    _status = s;
    if (!_serverStatusController.isClosed) _serverStatusController.add(s);
    _updateServiceStatus(s.running);
  }

  void _updateServiceStatus(bool isRunning) {
    if (_isServiceRunning != isRunning) {
      _isServiceRunning = isRunning;
      if (!_serviceStatusController.isClosed) {
        _serviceStatusController.add(isRunning);
      }
    }
  }

  void dispose() {
    _statusCheckTimer?.cancel();
    _statusCheckTimer = null;
    _serviceStatusController.close();
    _serverStatusController.close();
    _logController.close();
  }
}

class _ServerEvents extends Event {
  _ServerEvents(this._m);

  final ServiceManager _m;

  @override
  Future<void> onServiceStatusChanged(bool isRunning) async {
    // iOS only sends the boolean; refresh the full status there.
    _m._updateServiceStatus(isRunning);
    if (Platform.isIOS) unawaited(_m.checkServiceStatus());
  }

  @override
  Future<void> onServerStatus(ServerStatus status) async {
    _m._onStatus(status);
  }

  @override
  Future<void> onServerLog(int level, String time, String log) async {
    if (!_m._logController.isClosed) {
      _m._logController.add(LogEntry(level: level, time: time, message: log));
    }
  }
}
