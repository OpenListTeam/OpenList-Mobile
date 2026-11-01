import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:openlist_mobile/api/models.dart';
import 'package:openlist_mobile/api/openlist_client.dart';
import 'package:openlist_mobile/api/session.dart';
import 'package:openlist_mobile/utils/download_manager.dart';
import 'package:openlist_mobile/utils/service_manager.dart';

import '../../generated/l10n.dart';
import '../web/web.dart';
import 'common.dart';
import 'connect_page.dart';
import 'file_preview_page.dart';
import 'folder_picker_page.dart';
import 'storages_page.dart';
import 'tasks_page.dart';

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

  /// Upload progress in [0, 1], or null when idle.
  double? _uploadProgress;
  String _uploadName = '';

  @override
  void initState() {
    super.initState();
    _session.addListener(_onSession);
    // Reconnect to the local core when it comes up after the page opened.
    _statusSub = ServiceManager.instance.serviceStatusStream.listen((running) {
      if (running && !_session.isConnected && _session.kind == ConnectionKind.local) {
        _connect();
      }
    });
    _connect(restore: true);
  }

  @override
  void dispose() {
    _session.removeListener(_onSession);
    _statusSub?.cancel();
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
      final res = await _session.fs.list(path, password: _passwordFor(path), refresh: refresh);
      if (!mounted || _path != path) return;
      setState(() => _result = res);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.code == 403 && await _askPassword(path)) return;
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
    if (!await confirmDialog(context, S.current.confirmDeleteItems(o.name))) return;
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
    final picked = await FilePicker.platform
        .pickFiles(allowMultiple: true, withReadStream: true);
    if (picked == null) return;
    final dir = _path;
    var failed = false;
    for (final f in picked.files) {
      final stream = f.readStream;
      if (stream == null) continue;
      setState(() {
        _uploadName = f.name;
        _uploadProgress = 0;
      });
      try {
        await _session.fs.upload(
          OpenListClient.join(dir, f.name),
          stream,
          f.size,
          password: _passwordFor(dir),
          onProgress: (sent, total) {
            final t = total > 0 ? total : f.size;
            if (mounted && t > 0) setState(() => _uploadProgress = sent / t);
          },
        );
      } catch (e) {
        showError(e, title: S.current.uploadFailed);
        failed = true;
        break;
      }
    }
    if (!mounted) return;
    setState(() => _uploadProgress = null);
    if (!failed) showMessage(S.current.uploadDone);
    if (_path == dir) unawaited(_open(dir));
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
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(title: Text(o.name, maxLines: 2, overflow: TextOverflow.ellipsis)),
            if (!o.isDir) ...[
              item(Icons.download, S.current.download, () => _download(o)),
              item(Icons.link, S.current.copyLink, () => _copyLink(o)),
            ],
            if (canWrite) ...[
              item(Icons.drive_file_rename_outline, S.current.rename, () => _rename(o)),
              item(Icons.drive_file_move_outline, S.current.moveTo,
                  () => _transfer(o, copy: false)),
              item(Icons.copy, S.current.copyTo, () => _transfer(o, copy: true)),
              item(Icons.delete_outline, S.current.delete, () => _delete(o)),
            ],
          ]),
        );
      },
    );
  }

  void _menu(String value) {
    switch (value) {
      case 'tasks':
        Get.to(() => const TasksPage());
      case 'storages':
        Get.to(() => const StoragesPage())?.then((_) => _open(_path));
      case 'connection':
        Get.to(() => const ConnectPage());
      case 'web':
        Get.to(() => WebScreen(key: webGlobalKey));
    }
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
                  icon: const Icon(Icons.arrow_upward), onPressed: () => _open(_parent))
              : null,
          actions: [
            if (connected)
              IconButton(
                tooltip: S.of(context).refresh,
                icon: const Icon(Icons.refresh),
                onPressed: () => _open(_path, refresh: true),
              ),
            if (canWrite && _uploadProgress == null)
              IconButton(
                tooltip: S.of(context).upload,
                icon: const Icon(Icons.upload),
                onPressed: _upload,
              ),
            PopupMenuButton<String>(
              onSelected: _menu,
              itemBuilder: (_) => [
                if (connected) PopupMenuItem(value: 'tasks', child: Text(S.current.tasks)),
                if (connected && (_session.user?.isAdmin ?? false))
                  PopupMenuItem(value: 'storages', child: Text(S.current.storages)),
                PopupMenuItem(value: 'connection', child: Text(S.current.connection)),
                PopupMenuItem(value: 'web', child: Text(S.current.openWebInterface)),
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
          if (_uploadProgress != null)
            ListTile(
              dense: true,
              title: Text(S.of(context).uploadingFile(_uploadName),
                  overflow: TextOverflow.ellipsis),
              subtitle: LinearProgressIndicator(value: _uploadProgress),
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
            : (_error == null ? S.of(context).connectFailed : errorText(_error!)),
        action: notRunning ? S.of(context).startServer : S.of(context).retry,
        onAction: () async {
          if (notRunning) await ServiceManager.instance.startService();
          await _connect();
        },
      );
    }
    final res = _result;
    if (res == null || (_error != null && !_loading)) {
      if (_error == null) return const Center(child: CircularProgressIndicator());
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
            leading: Icon(_icon(o)),
            title: Text(o.name, maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: info.isEmpty ? null : Text(info),
            onTap: () => o.isDir
                ? _open(_child(o.name))
                : Get.to(() => FilePreviewPage(
                    path: _child(o.name), password: _passwordFor(_path))),
            onLongPress: () => _showActions(o),
            trailing: IconButton(
                icon: const Icon(Icons.more_vert), onPressed: () => _showActions(o)),
          );
        },
      ),
    );
  }
}
