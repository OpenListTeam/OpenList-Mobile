import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:openlist_mobile/generated_api.dart';
import 'package:openlist_mobile/utils/service_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'admin_api.dart';
import 'archive_api.dart';
import 'auth_api.dart';
import 'fs_api.dart';
import 'media_api.dart';
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

  /// Remote tokens live in the Keystore/Keychain. A token that can no longer
  /// be decrypted (e.g. restored from backup) is dropped; the user signs in
  /// again instead of the app failing.
  static const _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(resetOnError: true),
    iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device),
  );

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
  ArchiveApi get archive => ArchiveApi(_require());
  AuthApi get auth => AuthApi(_require());
  MediaApi get media => MediaApi(_require());

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
      final token = await _readToken(prefs);
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
    await _secure.write(key: _kToken, value: token);
    await prefs.remove(_kToken);
  }

  /// Reads the remote token, moving a legacy plaintext copy from
  /// SharedPreferences into secure storage on first use.
  Future<String> _readToken(SharedPreferences prefs) async {
    String? token;
    try {
      token = await _secure.read(key: _kToken);
    } catch (e) {
      debugPrint('Secure token read failed: $e');
    }
    final legacy = prefs.getString(_kToken);
    if (legacy != null) {
      if (token == null || token.isEmpty) {
        token = legacy;
        try {
          await _secure.write(key: _kToken, value: legacy);
        } catch (e) {
          debugPrint('Secure token migration failed: $e');
        }
      }
      await prefs.remove(_kToken);
    }
    return token ?? '';
  }

  Future<void> logout() async {
    if (_kind == ConnectionKind.remote) {
      try {
        await _client?.get('/api/auth/logout');
      } catch (_) {}
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kToken);
      try {
        await _secure.delete(key: _kToken);
      } catch (e) {
        debugPrint('Secure token delete failed: $e');
      }
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
