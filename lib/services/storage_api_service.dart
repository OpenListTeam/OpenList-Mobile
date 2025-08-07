import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../models/storage.dart';
import 'auth_manager.dart';
import '../pages/auth/login_page.dart';

class StorageApiService {
  static final Dio _dio = Dio();

  static Future<bool> _ensureAuthenticated() async {
    final authManager = AuthManager.instance;
    if (!authManager.isLoggedIn.value) {
      // 需要登录
      await Get.to(() => const LoginPage());
      return authManager.isLoggedIn.value;
    }
    return true;
  }

  static Future<Options> _getOptions() async {
    if (!await _ensureAuthenticated()) {
      throw Exception('用户未登录');
    }
    return await AuthManager.instance.getAuthOptions();
  }

  static String get _baseUrl => AuthManager.instance.baseUrl ?? 'http://localhost:5244';

  static Future<ApiResponse<PageResponse<Storage>>> getStorages({
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      final options = await _getOptions();
      final response = await _dio.post(
        '$_baseUrl/api/admin/storage/list',
        data: {
          'page': page,
          'per_page': perPage,
        },
        options: options,
      );

      if (response.data['code'] == 200) {
        final pageResponse = PageResponse<Storage>.fromJson(
          response.data['data'],
          (json) => Storage.fromJson(json),
        );
        return ApiResponse(
          code: response.data['code'],
          message: response.data['message'],
          data: pageResponse,
        );
      } else {
        return ApiResponse(
          code: response.data['code'],
          message: response.data['message'],
        );
      }
    } catch (e) {
      log('Failed to get storages: $e');
      return ApiResponse(
        code: -1,
        message: e.toString(),
      );
    }
  }

  static Future<ApiResponse<Map<String, dynamic>>> createStorage(Storage storage) async {
    try {
      final options = await _getOptions();
      final response = await _dio.post(
        '$_baseUrl/api/admin/storage/create',
        data: storage.toJson(),
        options: options,
      );

      return ApiResponse(
        code: response.data['code'],
        message: response.data['message'],
        data: response.data['data'] as Map<String, dynamic>?,
      );
    } catch (e) {
      log('Failed to create storage: $e');
      return ApiResponse(
        code: -1,
        message: e.toString(),
      );
    }
  }

  static Future<ApiResponse<void>> updateStorage(Storage storage) async {
    try {
      final options = await _getOptions();
      final response = await _dio.post(
        '$_baseUrl/api/admin/storage/update',
        data: storage.toJson(),
        options: options,
      );

      return ApiResponse(
        code: response.data['code'],
        message: response.data['message'],
      );
    } catch (e) {
      log('Failed to update storage: $e');
      return ApiResponse(
        code: -1,
        message: e.toString(),
      );
    }
  }

  static Future<ApiResponse<void>> deleteStorage(int id) async {
    try {
      final options = await _getOptions();
      final response = await _dio.post(
        '$_baseUrl/api/admin/storage/delete?id=$id',
        options: options,
      );

      return ApiResponse(
        code: response.data['code'],
        message: response.data['message'],
      );
    } catch (e) {
      log('Failed to delete storage: $e');
      return ApiResponse(
        code: -1,
        message: e.toString(),
      );
    }
  }

  static Future<ApiResponse<void>> enableStorage(int id) async {
    try {
      final options = await _getOptions();
      final response = await _dio.post(
        '$_baseUrl/api/admin/storage/enable?id=$id',
        options: options,
      );

      return ApiResponse(
        code: response.data['code'],
        message: response.data['message'],
      );
    } catch (e) {
      log('Failed to enable storage: $e');
      return ApiResponse(
        code: -1,
        message: e.toString(),
      );
    }
  }

  static Future<ApiResponse<void>> disableStorage(int id) async {
    try {
      final options = await _getOptions();
      final response = await _dio.post(
        '$_baseUrl/api/admin/storage/disable?id=$id',
        options: options,
      );

      return ApiResponse(
        code: response.data['code'],
        message: response.data['message'],
      );
    } catch (e) {
      log('Failed to disable storage: $e');
      return ApiResponse(
        code: -1,
        message: e.toString(),
      );
    }
  }

  static Future<ApiResponse<Storage>> getStorage(int id) async {
    try {
      final options = await _getOptions();
      final response = await _dio.get(
        '$_baseUrl/api/admin/storage/get?id=$id',
        options: options,
      );

      if (response.data['code'] == 200) {
        return ApiResponse(
          code: response.data['code'],
          message: response.data['message'],
          data: Storage.fromJson(response.data['data']),
        );
      } else {
        return ApiResponse(
          code: response.data['code'],
          message: response.data['message'],
        );
      }
    } catch (e) {
      log('Failed to get storage: $e');
      return ApiResponse(
        code: -1,
        message: e.toString(),
      );
    }
  }

  static Future<ApiResponse<void>> loadAllStorages() async {
    try {
      final options = await _getOptions();
      final response = await _dio.post(
        '$_baseUrl/api/admin/storage/load_all',
        options: options,
      );

      return ApiResponse(
        code: response.data['code'],
        message: response.data['message'],
      );
    } catch (e) {
      log('Failed to load all storages: $e');
      return ApiResponse(
        code: -1,
        message: e.toString(),
      );
    }
  }
}
