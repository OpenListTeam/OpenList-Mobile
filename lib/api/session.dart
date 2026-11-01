import 'package:flutter/foundation.dart';
import 'package:openlist_mobile/generated_api.dart';
import 'package:openlist_mobile/utils/service_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'admin_api.dart';
import 'auth_api.dart';
import 'fs_api.dart';
import 'models.dart';
import 'openlist_client.dart';
import 'task_api.dart';

/// Where the native UI talks to: the embedded core or a remote server.
enum ConnectionKind { local, remote }

/// Holds the active API client and the signed-in user.
class OpenListSession extends ChangeNotifier {
  OpenListSession._();

  static final OpenListSession instance = OpenListSession._();

  static const _kKind = 'session_kind';
  static const _kUrl = 'session_remote_url';
  static const _kToken = 'session_remote_token';

  OpenListClient? _client;
  UserInfo? _user;
  ConnectionKind _kind = ConnectionKind.local;

  OpenListClient? get client => _client;
  UserInfo? get user => _user;
  ConnectionKind get kind => _kind;
  bool get isConnected => _client != null && _user != null;

  FsApi get fs => FsApi(_require());
  TaskApi get tasks => TaskApi(_require());
  AdminApi get admin => AdminApi(_require());
  AuthApi get auth => AuthApi(_require());

  OpenListClient _require() {
    final c = _client;
    if (c == null) throw ApiException(-1, 'not connected');
    return c;
  }

  /// Loopback URL of the embedded core. Plain HTTP is preferred unless the
  /// core forces HTTPS.
  static String localBaseUrl(ServerStatus s) {
    final https = s.httpsPort > 0 && (s.forceHttps || s.httpPort <= 0);
    return https
        ? 'https://127.0.0.1:${s.httpsPort}'
        : 'http://127.0.0.1:${s.httpPort}';
  }

  /// Restores the last connection kind; remote reuses the saved token.
  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_kKind) == ConnectionKind.remote.name) {
      final url = prefs.getString(_kUrl) ?? '';
      final token = prefs.getString(_kToken) ?? '';
      if (url.isNotEmpty && token.isNotEmpty) {
        try {
          await _activate(ConnectionKind.remote, url, token);
          return;
        } catch (e) {
          debugPrint('Remote session restore failed: $e');
        }
      }
    }
    await connectLocal();
  }

  /// Connects to the embedded core using its admin token.
  Future<void> connectLocal() async {
    final sm = ServiceManager.instance;
    await sm.checkServiceStatus();
    final s = sm.status;
    if (s == null || !s.running) {
      _reset(ConnectionKind.local);
      throw ApiException(-1, 'server not running');
    }
    final token = await sm.getLocalToken();
    await _activate(ConnectionKind.local, localBaseUrl(s), token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kKind, ConnectionKind.local.name);
  }

  /// Signs in to a remote OpenList server.
  Future<void> connectRemote(String url, String username, String password,
      {String otpCode = ''}) async {
    final client = OpenListClient(baseUrl: url.trim());
    final token =
        await AuthApi(client).login(username, password, otpCode: otpCode);
    await _activate(ConnectionKind.remote, client.baseUrl, token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kKind, ConnectionKind.remote.name);
    await prefs.setString(_kUrl, client.baseUrl);
    await prefs.setString(_kToken, token);
  }

  Future<void> logout() async {
    if (_kind == ConnectionKind.remote) {
      try {
        await _client?.get('/api/auth/logout');
      } catch (_) {}
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kToken);
      await prefs.setString(_kKind, ConnectionKind.local.name);
    }
    _reset(ConnectionKind.local);
  }

  Future<void> _activate(ConnectionKind kind, String url, String token) async {
    final client = OpenListClient(baseUrl: url, token: token);
    final user = await AuthApi(client).me();
    _client = client;
    _user = user;
    _kind = kind;
    notifyListeners();
  }

  void _reset(ConnectionKind kind) {
    _client = null;
    _user = null;
    _kind = kind;
    notifyListeners();
  }
}
