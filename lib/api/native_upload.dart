import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:openlist_mobile/generated_api.dart';

import 'fs_api.dart';
import 'loopback_http.dart';
import 'openlist_client.dart';

/// Runs `fs/put` uploads on the platform's background transfer service
/// (Android WorkManager, iOS background URLSession) so they survive the app
/// being backgrounded.
///
/// Falls back to the Dart upload when the platform cannot carry the request:
/// - Android loopback HTTPS: the core's self-signed certificate is only
///   trusted by the Dart client, and there is no native loopback trust.
/// - iOS loopback: the in-process core is suspended with the app, so a
///   background session to it cannot progress.
/// - iOS plain HTTP: App Transport Security blocks it for URLSession.
/// - Any platform without the host API (MissingPluginException).
class NativeUploader {
  NativeUploader({UploadApi? api, TargetPlatform? platform})
      : _api = api ?? UploadApi(),
        _platform = platform ?? defaultTargetPlatform;

  static final NativeUploader instance = NativeUploader();

  final UploadApi _api;
  final TargetPlatform _platform;
  final Map<String, _Attempt> _attempts = {};

  /// Latest event per id that arrived before `enqueue` returned that id.
  final Map<String, UploadEvent> _early = {};
  static const _maxEarly = 32;

  bool _listening = false;
  bool _unavailable = false;

  /// Whether uploads to [baseUrl] can run natively on this platform.
  bool supports(String baseUrl) {
    if (_unavailable) return false;
    final uri = Uri.tryParse(baseUrl);
    if (uri == null || uri.host.isEmpty) return false;
    final loopback = isLoopbackHost(uri.host);
    switch (_platform) {
      case TargetPlatform.android:
        return uri.scheme == 'http' || (uri.scheme == 'https' && !loopback);
      case TargetPlatform.iOS:
        return uri.scheme == 'https' && !loopback;
      default:
        return false;
    }
  }

  /// Uploads [filePath] to [dstPath] like [FsApi.upload], natively when
  /// [supports] allows it, otherwise through [fallback].
  ///
  /// Completes when the server accepted the file and throws [ApiException]
  /// on failure, or the [cancelToken]'s cancel error once canceled.
  Future<void> upload(
    OpenListClient client, {
    required String filePath,
    required String dstPath,
    required String title,
    required Future<void> Function() fallback,
    String password = '',
    ProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) async {
    if (!supports(client.baseUrl)) return fallback();
    if (!_listening) {
      UploadEventApi.setUp(_EventHandler(this));
      _listening = true;
    }
    final request = UploadRequest(
      url: '${client.baseUrl}${FsApi.uploadPath}',
      method: 'PUT',
      filePath: filePath,
      headers: {
        ...FsApi.uploadHeaders(dstPath, password: password),
        // Same auth header as OpenListClient's interceptor.
        if (client.token.isNotEmpty) 'Authorization': client.token,
      },
      title: title,
    );
    final String id;
    try {
      id = await _api.enqueue(request);
    } on MissingPluginException {
      _unavailable = true;
      return fallback();
    } on PlatformException catch (e) {
      // Pigeon reports a missing host handler as `channel-error`.
      if (e.code == 'channel-error') {
        _unavailable = true;
        return fallback();
      }
      throw ApiException(-1, e.message ?? e.code);
    }

    final attempt = _Attempt(onProgress);
    _attempts[id] = attempt;
    if (cancelToken != null) {
      unawaited(cancelToken.whenCancel.then((e) {
        if (attempt.done) return;
        unawaited(_api.cancel(id).catchError((Object _) {}));
        _finish(id, error: e);
      }));
      attempt.cancelToken = cancelToken;
    }
    final early = _early.remove(id);
    if (early != null) _onEvent(early);
    return attempt.completer.future;
  }

  void _onEvent(UploadEvent e) {
    final attempt = _attempts[e.id];
    if (attempt == null) {
      // Ids of finished or foreign jobs also land here; keep only a few.
      // Progress is cumulative and results are terminal, so the latest
      // event is enough.
      _early.remove(e.id);
      if (_early.length >= _maxEarly) _early.remove(_early.keys.first);
      _early[e.id] = e;
      return;
    }
    switch (e.state) {
      case UploadEventState.enqueued:
      case UploadEventState.running:
        // A job the system stopped is re-enqueued and starts from zero.
        attempt.onProgress?.call(e.sent, e.total);
      case UploadEventState.completed:
        try {
          OpenListClient.unwrap(e.httpStatus, _decodeBody(e.body));
          _finish(e.id);
        } catch (err) {
          _finish(e.id, error: err);
        }
      case UploadEventState.failed:
        _finish(e.id, error: ApiException(-1, e.error ?? 'upload failed'));
      case UploadEventState.canceled:
        // Canceled natively (e.g. from the notification): mark the token so
        // the queue reports the job as canceled rather than failed.
        final token = attempt.cancelToken;
        if (token != null) {
          token.cancel();
        } else {
          _finish(e.id,
              error: DioException.requestCancelled(
                  requestOptions: RequestOptions(), reason: 'canceled'));
        }
    }
  }

  void _finish(String id, {Object? error}) {
    final attempt = _attempts.remove(id);
    if (attempt == null || attempt.done) return;
    attempt.done = true;
    if (error == null) {
      attempt.completer.complete();
    } else {
      attempt.completer.completeError(error);
    }
  }

  /// Decodes the response like Dio's JSON transformer; non-JSON stays text.
  static dynamic _decodeBody(String? body) {
    if (body == null || body.isEmpty) return null;
    try {
      return jsonDecode(body);
    } on FormatException {
      return body;
    }
  }
}

class _Attempt {
  _Attempt(this.onProgress);

  final ProgressCallback? onProgress;
  final Completer<void> completer = Completer<void>();
  CancelToken? cancelToken;
  bool done = false;
}

class _EventHandler extends UploadEventApi {
  _EventHandler(this._uploader);

  final NativeUploader _uploader;

  @override
  void onUploadEvent(UploadEvent event) => _uploader._onEvent(event);
}
