import 'models.dart';
import 'openlist_client.dart';

/// Authentication and current-user endpoints.
class AuthApi {
  AuthApi(this.client);

  final OpenListClient client;

  /// Returns a token; the core hashes the password server side.
  Future<String> login(
    String username,
    String password, {
    String otpCode = '',
  }) async {
    final data = await client.post(
      '/api/auth/login',
      body: {'username': username, 'password': password, 'otp_code': otpCode},
    );
    final token = data is Map ? data['token'] : null;
    if (token is! String || token.isEmpty) {
      throw ApiException(500, 'empty token');
    }
    return token;
  }

  Future<UserInfo> me() async {
    final data = await client.get('/api/me');
    return UserInfo.fromJson(Map<String, dynamic>.from(data ?? {}));
  }

  Future<void> logout() => client.get('/api/auth/logout');

  /// Public site settings (title, version, ...), no auth needed.
  Future<Map<String, dynamic>> publicSettings() async {
    final data = await client.get('/api/public/settings');
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }
}
