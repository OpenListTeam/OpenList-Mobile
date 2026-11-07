import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:openlist_mobile/generated_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fs_api.dart';
import 'loopback_http.dart';
import 'openlist_client.dart';
import 'session.dart';
import 'upload_queue.dart';

/// Runs `fs/put` uploads on the platform's background transfer service
/// (Android WorkManager, iOS background URLSession) so they survive the app
/// being backgrounded.
///
/// Falls back to the Dart upload when the platform cannot carry the request:
/// - iOS loopback: the in-process core is suspended with the app, so a
///   background session to it cannot progress.
/// - iOS plain HTTP: App Transport Security blocks it for URLSession.
/// - Any platform without the host API (MissingPluginException).
///
/// Android loopback HTTPS runs natively; the worker pins the core's own
/// certificate from `config.json`.
///
/// Each native job is recorded in SharedPreferences until Dart handles its
/// result, so [restore] can show it again after the app process restarts.
class NativeUploader {
  NativeUploader({
    UploadApi? api,
    TargetPlatform? platform,
    OpenListClient? Function()? currentClient,
  })  : _api = api ?? UploadApi(),
        _platform = platform ?? defaultTargetPlatform,
        _currentClient =
            currentClient ?? (() => OpenListSession.instance.client);

  static final NativeUploader instance = NativeUploader();

  /// SharedPreferences key prefix of the per-job records.
  @visibleForTesting
  static const recordPrefix = 'native_upload_job.';

  /// SharedPreferences key prefix for finished job results.
  static const _resultPrefix = 'native_upload_result.';

  /// Secure storage key prefix for folder passwords.
  static const _passwordPrefix = 'native_upload_pwd.';

  final UploadApi _api;
  final TargetPlatform _platform;
  final OpenListClient? Function() _currentClient;
  final Map<String, _Attempt> _attempts = {};
  final Map<String, _Record> _recordCache = {};

  /// Serializes record writes so a removal never overtakes its save.
  Future<void> _records = Future.value();
  Future<void>? _restoring;

  /// Latest event per id that arrived before `enqueue` returned that id.
  final Map<String, UploadEvent> _early = {};
  static const _maxEarly = 256;

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(migrateWithBackup: true),
  );

  bool _listening = false;
  bool _unavailable = false;

  /// Whether uploads to [baseUrl] can run natively on this platform.
  bool supports(String baseUrl) {
    if (_unavailable) return false;
    final uri = Uri.tryParse(baseUrl);
    if (uri == null || uri.host.isEmpty) return false;
    switch (_platform) {
      case TargetPlatform.android:
        return uri.scheme == 'http' || uri.scheme == 'https';
      case TargetPlatform.iOS:
        return uri.scheme == 'https' && !isLoopbackHost(uri.host);
      default:
        return false;
    }
  }

  /// Uploads [filePath] to [dstPath] like [FsApi.upload], natively when
  /// [supports] allows it, otherwise through [fallback].
  ///
  /// [dir] and [size] are stored with the native job so [restore] can list
  /// it again; [title] is its name.
  ///
  /// Completes when the server accepted the file and throws [ApiException]
  /// on failure, or the [cancelToken]'s cancel error once canceled.
  Future<void> upload(
    OpenListClient client, {
    required String filePath,
    required String dstPath,
    required String title,
    required Future<void> Function() fallback,
    String? dir,
    int size = 0,
    String password = '',
    ProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) async {
    if (!supports(client.baseUrl)) return fallback();
    _listen();
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

    final record = _Record(
      id: id,
      name: title,
      dir: dir ?? _parentOf(dstPath),
      dstPath: dstPath,
      filePath: filePath,
      size: size,
      baseUrl: client.baseUrl,
    );
    _recordCache[id] = record;
    _save(record);

    // Encrypt and save the folder password for retry.
    if (password.isNotEmpty) {
      unawaited(_savePassword(id, password));
    }

    final attempt = _track(id, onProgress, cancelToken);
    final early = _early.remove(id);
    if (early != null) _onEvent(early);
    return attempt.completer.future;
  }

  /// Puts native jobs from an earlier app process back into [queue].
  ///
  /// Unfinished jobs show as running and keep reporting progress; finished
  /// ones get their final state. Cancel cancels the native job. Retry starts
  /// a new upload of the same file with the current session client, only if
  /// it still points at the job's base URL. Folder passwords are encrypted
  /// and stored in secure storage; retries read them back.
  ///
  /// Safe to call more than once; later calls return the first result.
  Future<void> restore({UploadQueue? queue}) =>
      _restoring ??= _restore(queue ?? UploadQueue.instance);

  Future<void> _restore(UploadQueue queue) async {
    if (_platform != TargetPlatform.android &&
        _platform != TargetPlatform.iOS) {
      return;
    }
    // Before any await, so events of restored jobs are buffered.
    _listen();
    final List<_Record> records;
    final List<UploadEvent> events;
    final Map<String, Map<String, dynamic>> savedResults;
    try {
      records = await _loadRecords();
      savedResults = await _loadResults();
      // Also called with no records: iOS drops stored results it no longer
      // needs to keep.
      events = await _api.restore([for (final r in records) r.id]);
    } on MissingPluginException {
      return;
    } on PlatformException catch (e) {
      // Records stay for the next launch.
      debugPrint('Native upload restore failed: ${e.message ?? e.code}');
      return;
    }
    final byId = {for (final e in events) e.id: e};
    final recordsById = {for (final r in records) r.id: r};
    _recordCache.addAll(recordsById);

    for (final entry in savedResults.entries) {
      final id = entry.key;
      final result = entry.value;
      final record = recordsById[id];
      final name = record?.name ?? result['name'] as String?;
      final dir = record?.dir ?? result['dir'] as String?;
      final size = record?.size ?? result['size'] as int?;
      if (name == null || dir == null || size == null) continue;

      final job = UploadJob(
        name: name,
        dir: dir,
        size: size,
        historyId: id,
        onRemove: () => _forget(id),
        run: (token, onProgress) async {
          _forget(id);
          if (record == null) {
            throw ApiException(
                -1, 'The original upload can no longer be retried');
          }
          await _retry(record, token, onProgress);
        },
      );
      if (result['success'] == true) {
        job
          ..state = UploadState.succeeded
          ..sent = size;
      } else {
        job
          ..state = UploadState.failed
          ..error = 'Upload failed';
      }
      queue.addHistory(job);
    }

    for (final r in records) {
      if (_attempts.containsKey(r.id) || savedResults.containsKey(r.id)) {
        continue;
      }
      final job = UploadJob(
        name: r.name,
        dir: r.dir,
        size: r.size,
        historyId: r.id,
        onRemove: () => _forget(r.id),
        run: (token, onProgress) => _retry(r, token, onProgress),
      );
      final initial = byId[r.id];
      queue.adopt(job,
          (token, onProgress) => _resume(r.id, initial, token, onProgress));
    }
  }

  /// Follows a restored job until its result; [initial] is its state from
  /// [UploadApi.restore], null when the platform no longer knows it.
  Future<void> _resume(String id, UploadEvent? initial, CancelToken token,
      ProgressCallback onProgress) {
    final early = _early.remove(id);
    if (initial == null && early == null) {
      _forget(id);
      return Future.error(
          ApiException(-1, 'upload no longer tracked by the system'));
    }
    final attempt = _track(id, onProgress, token);
    if (initial != null) _onEvent(initial);
    // A newer event may have arrived before the restore reply.
    if (early != null) _onEvent(early);
    return attempt.completer.future;
  }

  /// Retries a restored job as a new upload of the recorded file.
  Future<void> _retry(
      _Record r, CancelToken token, ProgressCallback onProgress) async {
    final client = _currentClient();
    if (client == null || client.baseUrl != r.baseUrl) {
      throw ApiException(
          -1, 'not connected to ${r.baseUrl}; reconnect to it to retry');
    }

    // Read the encrypted folder password for retry.
    final password = await _loadPassword(r.id);

    await upload(
      client,
      filePath: r.filePath,
      dstPath: r.dstPath,
      title: r.name,
      dir: r.dir,
      size: r.size,
      password: password,
      onProgress: onProgress,
      cancelToken: token,
      fallback: () async {
        final file = File(r.filePath);
        await FsApi(client).upload(
          r.dstPath,
          file.openRead(),
          await file.length(),
          password: password,
          onProgress: onProgress,
          cancelToken: token,
        );
      },
    );
  }

  void _listen() {
    if (_listening) return;
    UploadEventApi.setUp(_EventHandler(this));
    _listening = true;
  }

  _Attempt _track(
      String id, ProgressCallback? onProgress, CancelToken? cancelToken) {
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
    return attempt;
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

    // Persist terminal metadata without storing request URLs or credentials.
    _saveResult(id, error: error, record: _recordCache[id]);
    if (error == null) {
      _forget(id, clearResult: false);
      _recordCache.remove(id);
    }

    if (error == null) {
      attempt.completer.complete();
    } else {
      attempt.completer.completeError(error);
    }
  }

  void _save(_Record r) => _writeRecords((prefs) =>
      prefs.setString('$recordPrefix${r.id}', jsonEncode(r.toJson())));

  void _forget(String id, {bool clearResult = true}) {
    _recordCache.remove(id);
    _writeRecords((prefs) => prefs.remove('$recordPrefix$id'));
    if (clearResult) _clearResult(id);
    _clearPassword(id);
  }

  /// Saves the upload result (success or error) so it survives process death.
  void _saveResult(String id, {Object? error, _Record? record}) {
    _writeRecords((prefs) async {
      final result = <String, dynamic>{
        'id': id,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        if (record != null) ...{
          'name': record.name,
          'dir': record.dir,
          'size': record.size,
        },
      };
      if (error != null) {
        result['error'] = {'message': 'Upload failed'};
      } else {
        result['success'] = true;
      }
      await prefs.setString('$_resultPrefix$id', jsonEncode(result));
    });
  }

  void _clearResult(String id) {
    _writeRecords((prefs) => prefs.remove('$_resultPrefix$id'));
  }

  /// Encrypts and stores the folder password for this upload.
  Future<void> _savePassword(String id, String password) async {
    if (password.isEmpty) return;
    try {
      await _secureStorage.write(key: '$_passwordPrefix$id', value: password);
    } catch (e) {
      debugPrint('Failed to save upload password: $e');
    }
  }

  /// Reads the encrypted folder password for retry.
  Future<String> _loadPassword(String id) async {
    try {
      return await _secureStorage.read(key: '$_passwordPrefix$id') ?? '';
    } catch (e) {
      debugPrint('Failed to read upload password: $e');
      return '';
    }
  }

  void _clearPassword(String id) {
    _secureStorage.delete(key: '$_passwordPrefix$id').catchError((e) {
      debugPrint('Failed to delete upload password: $e');
    });
  }

  void _writeRecords(Future<void> Function(SharedPreferences prefs) write) {
    _records = _records.then((_) async {
      try {
        await write(await SharedPreferences.getInstance());
      } catch (e) {
        // Losing a record only means the job is not listed after a relaunch.
        debugPrint('Native upload record write failed: $e');
      }
    });
  }

  Future<List<_Record>> _loadRecords() async {
    await _records;
    final SharedPreferences prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } on MissingPluginException {
      return const [];
    }
    final out = <_Record>[];
    for (final key in prefs.getKeys()) {
      if (!key.startsWith(recordPrefix)) continue;
      final r = _Record.tryParse(prefs.getString(key));
      if (r == null) {
        await prefs.remove(key);
      } else {
        out.add(r);
      }
    }
    return out;
  }

  /// Loads saved upload results (success or error) that survived process death.
  Future<Map<String, Map<String, dynamic>>> _loadResults() async {
    await _records;
    final SharedPreferences prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } on MissingPluginException {
      return {};
    }
    final out = <String, Map<String, dynamic>>{};
    for (final key in prefs.getKeys()) {
      if (!key.startsWith(_resultPrefix)) continue;
      try {
        final data = jsonDecode(prefs.getString(key)!) as Map<String, dynamic>;
        final id = data['id'] as String;
        out[id] = data;
      } catch (e) {
        await prefs.remove(key);
      }
    }
    return out;
  }

  static String _parentOf(String path) {
    final i = path.lastIndexOf('/');
    return i <= 0 ? '/' : path.substring(0, i);
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

/// What [NativeUploader.restore] needs to list and retry a native job.
/// Credentials (token, folder password) are never stored.
class _Record {
  _Record({
    required this.id,
    required this.name,
    required this.dir,
    required this.dstPath,
    required this.filePath,
    required this.size,
    required this.baseUrl,
  });

  final String id;
  final String name;
  final String dir;
  final String dstPath;
  final String filePath;
  final int size;
  final String baseUrl;

  Map<String, Object> toJson() => {
        'id': id,
        'name': name,
        'dir': dir,
        'dstPath': dstPath,
        'filePath': filePath,
        'size': size,
        'baseUrl': baseUrl,
      };

  static _Record? tryParse(String? text) {
    if (text == null) return null;
    try {
      final m = jsonDecode(text) as Map<String, dynamic>;
      return _Record(
        id: m['id'] as String,
        name: m['name'] as String,
        dir: m['dir'] as String,
        dstPath: m['dstPath'] as String,
        filePath: m['filePath'] as String,
        size: m['size'] as int,
        baseUrl: m['baseUrl'] as String,
      );
    } catch (_) {
      return null;
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
  Future<void> onUploadEvent(UploadEvent event) async {
    _uploader._onEvent(event);
  }
}
