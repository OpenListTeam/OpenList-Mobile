import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:openlist_mobile/api/models.dart';
import 'package:openlist_mobile/api/native_upload.dart';
import 'package:openlist_mobile/api/openlist_client.dart';
import 'package:openlist_mobile/api/session.dart';
import 'package:openlist_mobile/api/upload_queue.dart';
import 'package:openlist_mobile/utils/download_manager.dart';
import 'package:openlist_mobile/utils/service_manager.dart';

import '../../generated/l10n.dart';
import 'common.dart';
import 'connect_page.dart';
import 'file_preview_page.dart';
import 'folder_picker_page.dart';
import 'offline_download_dialog.dart';
import 'search_page.dart';
import 'settings_admin_page.dart';
import 'storages_page.dart';
import 'tasks_page.dart';
import 'uploads_page.dart';
import 'users_page.dart';

/// Native file browser backed by the OpenList HTTP API.
class FilesPage extends StatefulWidget {
  const FilesPage({super.key});

  @override
  State<FilesPage> createState() => _FilesPageState();
}

class _FilesPageState extends State<FilesPage> {
  final _session = OpenListSession.instance;
  StreamSubscription<bool>? _statusSub;

  String _path = '/';
  FsListResult? _result;
  Object? _error;
  bool _loading = true;
  bool _connecting = false;

  /// Folder passwords entered in this session, keyed by path.
  final Map<String, String> _passwords = {};

  StreamSubscription<UploadJob>? _uploadSub;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _session.addListener(_onSession);
    // Reconnect to the local core when it comes up after the page opened.
    _statusSub = ServiceManager.instance.serviceStatusStream.listen((running) {
      if (running &&
          !_session.isConnected &&
          _session.kind == ConnectionKind.local) {
        _connect();
      }
    });
    _uploadSub = UploadQueue.instance.finished.listen(_onUploadFinished);
    _connect(restore: true);
  }

  void _onUploadFinished(UploadJob j) {
    if (!mounted) return;
    if (j.state == UploadState.failed) {
      showError(j.error ?? S.current.uploadFailed,
          title: '${S.current.uploadFailed}: ${j.name}');
    }
    if (j.state != UploadState.succeeded ||
        j.dir != _path ||
        !_session.isConnected) return;
    // Batch refreshes when many small files finish close together.
    _refreshTimer?.cancel();
    _refreshTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted && _path == j.dir) _open(_path);
    });
  }

  @override
  void dispose() {
    _session.removeListener(_onSession);
    _statusSub?.cancel();
    _uploadSub?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _onSession() {
    if (!mounted) return;
    if (_session.isConnected) {
      _open('/');
    } else {
      setState(() => _result = null);
    }
  }

  Future<void> _connect({bool restore = false}) async {
    if (_connecting) return;
    setState(() {
      _connecting = true;
      _loading = true;
      _error = null;
    });
    try {
      // Session listeners trigger the first listing.
      restore ? await _session.restore() : await _session.connectLocal();
    } catch (e) {
      _error = e;
    }
    if (mounted) {
      setState(() {
        _connecting = false;
        _loading = false;
      });
    }
  }

  String _passwordFor(String path) {
    // The nearest ancestor with a known password applies to sub folders.
    var p = path;
    while (true) {
      final v = _passwords[p];
      if (v != null) return v;
      if (p == '/' || p.isEmpty) return '';
      final i = p.lastIndexOf('/');
      p = i <= 0 ? '/' : p.substring(0, i);
    }
  }

  Future<void> _open(String path, {bool refresh = false}) async {
    setState(() {
      _path = path;
      _loading = true;
      _error = null;
    });
    try {
      final res = await _session.fs
          .list(path, password: _passwordFor(path), refresh: refresh);
      if (!mounted || _path != path) return;
      setState(() => _result = res);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.isPasswordRequired && await _askPassword(path)) return;
      _error = e;
    } catch (e) {
      _error = e;
    }
    if (mounted && _path == path) setState(() => _loading = false);
  }

  /// Prompts for a folder password and retries; true when a retry started.
  Future<bool> _askPassword(String path) async {
    final pwd = await promptText(context,
        title: S.current.folderPassword, label: path, obscure: true);
    if (pwd == null) return false;
    _passwords[path] = pwd;
    unawaited(_open(path));
    return true;
  }

  String get _parent {
    final i = _path.lastIndexOf('/');
    return i <= 0 ? '/' : _path.substring(0, i);
  }

  String _child(String name) => OpenListClient.join(_path, name);

  /// Runs a write operation, reports the outcome and refreshes the listing.
  Future<void> _act(Future<void> Function() fn) async {
    try {
      await fn();
      showMessage(S.current.operationDone);
    } catch (e) {
      showError(e);
    }
    if (mounted) unawaited(_open(_path));
  }

  Future<void> _mkdir() async {
    final name = await promptText(context,
        title: S.current.newFolder, label: S.current.folderName);
    if (name == null) return;
    await _act(() => _session.fs.mkdir(_child(name)));
  }

  Future<void> _rename(FsObject o) async {
    final name = await promptText(context,
        title: S.current.rename, label: S.current.newName, initial: o.name);
    if (name == null || name == o.name) return;
    await _act(() => _session.fs.rename(_child(o.name), name));
  }

  Future<void> _transfer(FsObject o, {required bool copy}) async {
    final dst = await Get.to<String>(() => FolderPickerPage(
        title: copy ? S.current.copyTo : S.current.moveTo, initial: _path));
    if (dst == null || dst == _path) return;
    await _act(() => copy
        ? _session.fs.copy(_path, dst, [o.name])
        : _session.fs.move(_path, dst, [o.name]));
  }

  Future<void> _delete(FsObject o) async {
    if (!await confirmDialog(context, S.current.confirmDeleteItems(o.name)))
      return;
    await _act(() => _session.fs.remove(_path, [o.name]));
  }

  Future<String> _fileUrl(FsObject o) async {
    final path = _child(o.name);
    // fs/get returns raw_url and a fresh sign; list entries may lack both.
    final full = await _session.fs.get(path, password: _passwordFor(_path));
    return full.rawUrl.isNotEmpty
        ? full.rawUrl
        : _session.fs.downloadUrl(path, sign: full.sign);
  }

  Future<void> _download(FsObject o) async {
    try {
      await DownloadManager.downloadFileWithProgress(
          url: await _fileUrl(o), filename: o.name);
    } catch (e) {
      showError(e);
    }
  }

  Future<void> _copyLink(FsObject o) async {
    try {
      await Clipboard.setData(ClipboardData(text: await _fileUrl(o)));
      showMessage(S.current.copiedToClipboard);
    } catch (e) {
      showError(e);
    }
  }

  Future<void> _upload() async {
    final picked = await FilePicker.pickFiles();
    if (picked.isEmpty) return;
    final dir = _path;
    final fs = _session.fs;
    final password = _passwordFor(dir);
    final jobs = <UploadJob>[];
    for (final f in picked) {
      final path = f.path;
      if (path == null) continue;
      final size = await f.length() ?? 0;
      jobs.add(
        UploadJob(
          name: f.name,
          dir: dir,
          size: size,
          // Each attempt is a new native job, or reopens the file on the
          // Dart path, so retries work.
          run: (token, onProgress) {
            final dstPath = OpenListClient.join(dir, f.name);
            return NativeUploader.instance.upload(
              fs.client,
              filePath: path,
              dstPath: dstPath,
              title: f.name,
              dir: dir,
              size: size,
              password: password,
              onProgress: onProgress,
              cancelToken: token,
              fallback: () async {
                final file = File(path);
                await fs.upload(
                  dstPath,
                  file.openRead(),
                  await file.length(),
                  password: password,
                  onProgress: onProgress,
                  cancelToken: token,
                );
              },
            );
          },
        ),
      );
    }
    UploadQueue.instance.addAll(jobs);
  }

  void _showActions(FsObject o) {
    final canWrite = _result?.write ?? false;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        Widget item(IconData icon, String label, VoidCallback fn) => ListTile(
              leading: Icon(icon),
              title: Text(label),
              onTap: () {
                Navigator.pop(ctx);
                fn();
              },
            );
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  o.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!o.isDir) ...[
                item(Icons.download, S.current.download, () => _download(o)),
                item(Icons.link, S.current.copyLink, () => _copyLink(o)),
              ],
              if (canWrite) ...[
                item(
                  Icons.drive_file_rename_outline,
                  S.current.rename,
                  () => _rename(o),
                ),
                item(
                  Icons.drive_file_move_outline,
                  S.current.moveTo,
                  () => _transfer(o, copy: false),
                ),
                item(
                  Icons.copy,
                  S.current.copyTo,
                  () => _transfer(o, copy: true),
                ),
                item(Icons.delete_outline, S.current.delete, () => _delete(o)),
              ],
            ],
          ),
        );
      },
    );
  }

  void _menu(String value) {
    switch (value) {
      case 'tasks':
        Get.to(() => const TasksPage());
      case 'uploads':
        Get.to(() => const UploadsPage());
      case 'offline':
        showOfflineDownloadDialog(context, _path).then((ok) {
          if (ok) Get.to(() => const TasksPage());
        });
      case 'storages':
        Get.to(() => const StoragesPage())?.then((_) => _open(_path));
      case 'users':
        Get.to(() => const UsersPage());
      case 'site_settings':
        Get.to(() => const SettingsAdminPage());
      case 'connection':
        Get.to(() => const ConnectPage());
    }
  }

  /// Offline downloads need the permission bit unless the user is admin.
  bool get _canOffline {
    final u = _session.user;
    if (u == null) return false;
    return u.isAdmin || (u.permission >> UserPerm.offlineDownload) & 1 == 1;
  }

  Future<void> _search() async {
    final dir = await Get.to<String>(
        () => SearchPage(parent: _path, password: _passwordFor(_path)));
    if (dir != null && mounted) unawaited(_open(dir));
  }

  /// Thumbnail when the core provides one, otherwise the type icon. The
  /// OpenList token is never sent with the image request.
  Widget _leading(FsObject o) {
    final icon = Icon(_icon(o));
    if (o.isDir || o.thumb.isEmpty) return icon;
    final base = _session.client?.baseUrl ?? '';
    final url = o.thumb.startsWith('/') ? '$base${o.thumb}' : o.thumb;
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.network(
        url,
        width: 40,
        height: 40,
        cacheWidth: 120,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => icon,
      ),
    );
  }

  IconData _icon(FsObject o) {
    if (o.isDir) return Icons.folder;
    return switch (o.type) {
      ObjType.image => Icons.image_outlined,
      ObjType.video => Icons.movie_outlined,
      ObjType.audio => Icons.audiotrack_outlined,
      ObjType.text => Icons.description_outlined,
      _ => Icons.insert_drive_file_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final connected = _session.isConnected;
    final canWrite = connected && (_result?.write ?? false);
    return PopScope(
      canPop: _path == '/' || !connected,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _open(_parent);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(connected ? _path : S.of(context).nativeFiles,
              overflow: TextOverflow.ellipsis),
          leading: connected && _path != '/'
              ? IconButton(
                  icon: const Icon(Icons.arrow_upward),
                  onPressed: () => _open(_parent))
              : null,
          actions: [
            if (connected)
              IconButton(
                tooltip: S.of(context).search,
                icon: const Icon(Icons.search),
                onPressed: _search,
              ),
            if (connected)
              IconButton(
                tooltip: S.of(context).refresh,
                icon: const Icon(Icons.refresh),
                onPressed: () => _open(_path, refresh: true),
              ),
            if (canWrite)
              IconButton(
                tooltip: S.of(context).upload,
                icon: const Icon(Icons.upload),
                onPressed: _upload,
              ),
            PopupMenuButton<String>(
              onSelected: _menu,
              itemBuilder: (_) => [
                if (connected)
                  PopupMenuItem(value: 'tasks', child: Text(S.current.tasks)),
                PopupMenuItem(value: 'uploads', child: Text(S.current.uploads)),
                if (canWrite && _canOffline)
                  PopupMenuItem(
                      value: 'offline', child: Text(S.current.offlineDownload)),
                if (connected && (_session.user?.isAdmin ?? false))
                  PopupMenuItem(
                      value: 'storages', child: Text(S.current.storages)),
                if (connected && (_session.user?.isAdmin ?? false))
                  PopupMenuItem(value: 'users', child: Text(S.current.users)),
                if (connected && (_session.user?.isAdmin ?? false))
                  PopupMenuItem(
                      value: 'site_settings',
                      child: Text(S.current.siteSettings)),
                PopupMenuItem(
                    value: 'connection', child: Text(S.current.connection)),
              ],
            ),
          ],
        ),
        floatingActionButton: canWrite
            ? FloatingActionButton(
                tooltip: S.of(context).newFolder,
                onPressed: _mkdir,
                child: const Icon(Icons.create_new_folder_outlined),
              )
            : null,
        body: Column(children: [
          ListenableBuilder(
            listenable: UploadQueue.instance,
            builder: (context, _) {
              final n = UploadQueue.instance.activeCount;
              if (n == 0) return const SizedBox.shrink();
              return ListTile(
                dense: true,
                leading: const Icon(Icons.cloud_upload_outlined),
                title: Text(S.of(context).uploadsActive(n)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Get.to(() => const UploadsPage()),
              );
            },
          ),
          if (_loading && _result != null) const LinearProgressIndicator(),
          Expanded(child: _body(context)),
        ]),
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (!_session.isConnected) {
      if (_loading) return const Center(child: CircularProgressIndicator());
      final notRunning = !ServiceManager.instance.isServiceRunning;
      return StateMessage(
        icon: Icons.cloud_off,
        text: notRunning && _session.kind == ConnectionKind.local
            ? S.of(context).serverNotRunning
            : (_error == null
                ? S.of(context).connectFailed
                : errorText(_error!)),
        action: notRunning ? S.of(context).startServer : S.of(context).retry,
        onAction: () async {
          if (notRunning) await ServiceManager.instance.startService();
          await _connect();
        },
      );
    }
    final res = _result;
    if (res == null || (_error != null && !_loading)) {
      if (_error == null)
        return const Center(child: CircularProgressIndicator());
      return StateMessage(
          icon: Icons.error_outline,
          text: errorText(_error!),
          action: S.of(context).retry,
          onAction: () => _open(_path));
    }
    if (res.content.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _open(_path, refresh: true),
        child: ListView(children: [
          const SizedBox(height: 120),
          StateMessage(icon: Icons.folder_off, text: S.of(context).emptyFolder),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _open(_path, refresh: true),
      child: ListView.builder(
        itemCount: res.content.length,
        itemBuilder: (_, i) {
          final o = res.content[i];
          final info = [
            if (!o.isDir) formatBytes(o.size),
            formatTime(o.modified),
          ].where((e) => e.isNotEmpty).join('  ');
          return ListTile(
            leading: _leading(o),
            title: Text(o.name, maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: info.isEmpty ? null : Text(info),
            onTap: () => o.isDir
                ? _open(_child(o.name))
                : Get.to(() => FilePreviewPage(
                    path: _child(o.name), password: _passwordFor(_path))),
            onLongPress: () => _showActions(o),
            trailing: IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () => _showActions(o)),
          );
        },
      ),
    );
  }
}
