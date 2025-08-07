import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../generated_api.dart';
import 'dart:developer';

class AuthManager extends GetxController {
  static AuthManager get instance => Get.find<AuthManager>();
  
  final Dio _dio = Dio();
  final RxBool isLoggedIn = false.obs;
  final RxString username = ''.obs;
  
  String? _token;
  String? _baseUrl;
  
  static const String _keyToken = 'auth_token';
  static const String _keyUsername = 'auth_username';
  static const String _keyPassword = 'auth_password';
  static const String _keyRememberMe = 'auth_remember_me';

  @override
  void onInit() {
    super.onInit();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString(_keyToken);
    final savedUsername = prefs.getString(_keyUsername);
    final rememberMe = prefs.getBool(_keyRememberMe) ?? false;
    
    if (savedToken != null && savedUsername != null && rememberMe) {
      _token = savedToken;
      username.value = savedUsername;
      isLoggedIn.value = true;
      
      // 验证 token 是否仍然有效
      final isValid = await _validateToken();
      if (!isValid) {
        await logout();
      }
    }
  }

  Future<bool> _validateToken() async {
    if (_token == null) return false;
    
    try {
      await _initializeBaseUrl();
      final response = await _dio.get(
        '$_baseUrl/api/me',
        options: Options(
          headers: {'Authorization': _token},
        ),
      );
      
      return response.statusCode == 200 && response.data['code'] == 200;
    } catch (e) {
      log('Token validation failed: $e');
      return false;
    }
  }

  Future<void> _initializeBaseUrl() async {
    if (_baseUrl == null) {
      // 这里需要导入 Android 类
      try {
        final port = await Android().getOpenListHttpPort();
        _baseUrl = 'http://localhost:$port';
      } catch (e) {
        _baseUrl = 'http://localhost:5244'; // 默认端口
      }
    }
  }

  Future<LoginResult> login(String inputUsername, String inputPassword, bool rememberMe) async {
    try {
      await _initializeBaseUrl();
      
      final response = await _dio.post(
        '$_baseUrl/api/auth/login',
        data: {
          'username': inputUsername,
          'password': inputPassword,
        },
      );

      if (response.statusCode == 200 && response.data['code'] == 200) {
        _token = response.data['data']['token'];
        username.value = inputUsername;
        isLoggedIn.value = true;
        
        // 保存凭据
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyToken, _token!);
        await prefs.setString(_keyUsername, inputUsername);
        await prefs.setBool(_keyRememberMe, rememberMe);
        
        if (rememberMe) {
          await prefs.setString(_keyPassword, inputPassword);
        } else {
          await prefs.remove(_keyPassword);
        }
        
        return LoginResult.success();
      } else {
        return LoginResult.failure(response.data['message'] ?? '登录失败');
      }
    } catch (e) {
      log('Login failed: $e');
      if (e is DioException) {
        if (e.response?.statusCode == 401) {
          return LoginResult.failure('用户名或密码错误');
        } else if (e.response?.statusCode == 403) {
          return LoginResult.failure('账户被禁用');
        } else {
          return LoginResult.failure('网络连接失败，请检查服务是否启动');
        }
      }
      return LoginResult.failure('登录失败：${e.toString()}');
    }
  }

  Future<void> logout() async {
    _token = null;
    username.value = '';
    isLoggedIn.value = false;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUsername);
    await prefs.remove(_keyPassword);
    await prefs.setBool(_keyRememberMe, false);
  }

  String? get token => _token;
  String? get baseUrl => _baseUrl;

  Future<Map<String, String>> getAuthHeaders() async {
    await _initializeBaseUrl();
    return {
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': _token!,
    };
  }

  Future<Options> getAuthOptions() async {
    final headers = await getAuthHeaders();
    return Options(headers: headers);
  }

  Future<bool> hasStoredCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUsername) != null && 
           prefs.getString(_keyPassword) != null &&
           (prefs.getBool(_keyRememberMe) ?? false);
  }

  Future<Map<String, String>?> getStoredCredentials() async {
    if (!await hasStoredCredentials()) return null;
    
    final prefs = await SharedPreferences.getInstance();
    return {
      'username': prefs.getString(_keyUsername) ?? '',
      'password': prefs.getString(_keyPassword) ?? '',
    };
  }
}

class LoginResult {
  final bool success;
  final String? message;

  LoginResult._(this.success, this.message);

  factory LoginResult.success() => LoginResult._(true, null);
  factory LoginResult.failure(String message) => LoginResult._(false, message);
}
