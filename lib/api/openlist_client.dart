import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import 'loopback_http.dart';

/// Error returned by the OpenList API envelope or the transport.
class ApiException implements Exception {
  ApiException(this.code, this.message);

  /// Envelope code (HTTP-like), or -1 for transport errors.
  final int code;
  final String message;

  bool get isUnauthorized => code == 401;

  /// fs/list and fs/get answer a missing or wrong folder password with this
  /// 403 message; other 403s (path escape, refresh denied) are plain errors.
  bool get isPasswordRequired =>
      code == 403 && message.toLowerCase().contains('password');

  @override
  String toString() => 'ApiException($code): $message';
}

/// Thin Dio wrapper around the OpenList `{code, message, data}` envelope.
class OpenListClient {
  OpenListClient({required String baseUrl, this.token = '', Dio? dio})
    : dio = dio ?? Dio() {
    this.dio.options
      ..baseUrl = _trimSlash(baseUrl)
      ..connectTimeout = const Duration(seconds: 10)
      ..receiveTimeout = const Duration(seconds: 60)
      ..responseType = ResponseType.json
      // Envelope codes carry the real status; let 4xx/5xx bodies through.
      ..validateStatus = (s) => s != null && s < 600;
    this.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (o, h) {
          if (token.isNotEmpty) o.headers['Authorization'] = token;
          h.next(o);
        },
      ),
    );
    if (dio == null) _allowLoopbackSelfSigned(this.dio);
  }

  final Dio dio;

  /// Raw OpenList token sent as the `Authorization` header.
  String token;

  String get baseUrl => dio.options.baseUrl;

  static String _trimSlash(String s) =>
      s.endsWith('/') ? s.substring(0, s.length - 1) : s;

  /// The embedded core may use a self-signed certificate; trust it only when
  /// talking to the loopback interface.
  static void _allowLoopbackSelfSigned(Dio dio) {
    final uri = Uri.tryParse(dio.options.baseUrl);
    if (uri == null || uri.scheme != 'https' || !isLoopbackHost(uri.host)) {
      return;
    }
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        return HttpClient()
          ..badCertificateCallback = (_, h, __) => isLoopbackHost(h);
      },
    );
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => dio.get(path, queryParameters: query));

  Future<dynamic> post(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
  }) => _send(() => dio.post(path, data: body ?? {}, queryParameters: query));

  Future<dynamic> put(
    String path, {
    required Object data,
    Map<String, dynamic>? headers,
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
  }) => _send(
    () => dio.put(
      path,
      data: data,
      options: Options(headers: headers),
      onSendProgress: onSendProgress,
      cancelToken: cancelToken,
    ),
  );

  /// Runs [req] and returns the envelope `data`, throwing [ApiException].
  Future<dynamic> _send(Future<Response> Function() req) async {
    final Response res;
    try {
      res = await req();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) rethrow;
      throw ApiException(-1, e.message ?? e.type.name);
    }
    return unwrap(res.statusCode ?? 0, res.data);
  }

  /// Decodes an OpenList envelope. Exposed for tests.
  static dynamic unwrap(int httpStatus, dynamic body) {
    if (body is Map) {
      final code = body['code'];
      if (code is num) {
        if (code.toInt() == 200) return body['data'];
        throw ApiException(code.toInt(), '${body['message'] ?? ''}');
      }
    }
    if (httpStatus >= 200 && httpStatus < 300) return body;
    throw ApiException(httpStatus, body is String ? body : 'HTTP $httpStatus');
  }

  /// Encodes each path segment for use in URLs and the `File-Path` header.
  static String encodePath(String path) =>
      path.split('/').map(Uri.encodeComponent).join('/');

  /// Joins a directory and a name into an absolute OpenList path.
  static String join(String dir, String name) {
    final d = dir.endsWith('/') ? dir.substring(0, dir.length - 1) : dir;
    return '$d/$name';
  }
}
