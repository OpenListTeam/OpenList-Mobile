import 'dart:async';

import 'package:flutter/material.dart';
import 'package:openlist_mobile/api/archive_api.dart';
import 'package:openlist_mobile/api/models.dart';
import 'package:openlist_mobile/api/openlist_client.dart';
import 'package:openlist_mobile/api/session.dart';
import 'package:openlist_mobile/generated/l10n.dart';
import 'package:openlist_mobile/pages/native/common.dart';
import 'package:openlist_mobile/utils/download_manager.dart';
import 'package:openlist_mobile/utils/local_zip_archive.dart';

/// Browses archive members through Core, with a local ZIP fallback for Range
/// callback admission failures.
class ArchivePreviewView extends StatefulWidget {
  const ArchivePreviewView({
    super.key,
    required this.path,
    required this.password,
    required this.url,
    required this.headers,
    required this.size,
  });

  final String path;
  final String password;
  final String url;
  final Map<String, String> headers;
  final int size;

  @override
  State<ArchivePreviewView> createState() => _ArchivePreviewViewState();
}

class _ArchivePreviewViewState extends State<ArchivePreviewView> {
  String _archivePassword = '';
  String _localArchivePassword = '';
  String _innerPath = '/';
  List<String> _parents = [];
  List<LocalZipEntry> _localEntries = [];
  FsListResult? _result;
  ArchiveMeta? _meta;
  LocalZipArchive? _localArchive;
  Object? _error;
  bool _loading = true;
  bool _requiresPassword = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    final archive = _localArchive;
    if (archive != null) unawaited(archive.dispose());
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _requiresPassword = false;
    });
    try {
      if (_localArchive != null) {
        await _loadLocalArchive();
      } else {
        final session = OpenListSession.instance;
        final meta = _meta ??= await session.archive.meta(widget.path,
            password: widget.password, archivePassword: _archivePassword);
        _meta = meta;
        if (meta.encrypted && _archivePassword.isEmpty) {
          _requiresPassword = true;
        } else if (meta.rawUrl.isEmpty) {
          _error = StateError(S.current.archiveExtractionUnavailable);
        } else {
          _result = await session.archive.list(widget.path,
              password: widget.password,
              archivePassword: _archivePassword,
              innerPath: _innerPath);
        }
      }
    } catch (error) {
      if (_isCallbackAdmissionError(error) &&
          widget.path.toLowerCase().endsWith('.zip')) {
        try {
          await _loadLocalArchive();
        } catch (fallbackError) {
          _error = fallbackError;
        }
      } else {
        _error = error;
        _requiresPassword = error is ApiException && error.code == 202;
        if (_requiresPassword) _meta = null;
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  bool _isCallbackAdmissionError(Object error) {
    final message =
        (error is ApiException ? error.message : '$error').toLowerCase();
    return message.contains('temporary capacity unavailable') ||
        message.contains('timed out waiting for callback admission');
  }

  Future<void> _loadLocalArchive() async {
    final archive = _localArchive ??= await LocalZipArchive.download(
      url: widget.url,
      headers: widget.headers,
      expectedSize: widget.size,
      password: _archivePassword,
    );
    if (_localArchivePassword != _archivePassword) {
      await archive.setPassword(_archivePassword);
      _localArchivePassword = _archivePassword;
    }
    _result = null;
    if (archive.encrypted && _archivePassword.isEmpty) {
      _requiresPassword = true;
      _localEntries = [];
      return;
    }
    _localEntries = archive.list(_innerPath);
  }

  Future<void> _enterPassword() async {
    final value = await promptText(context,
        title: S.of(context).password,
        label: S.of(context).password,
        obscure: true);
    if (value == null || !mounted) return;
    setState(() {
      _archivePassword = value;
      _meta = null;
      _innerPath = '/';
      _parents.clear();
    });
    await _load();
  }

  Future<void> _openDirectory(String name) async {
    final parent =
        _innerPath == '/' ? '' : _innerPath.replaceAll(RegExp(r'/+$'), '');
    _parents = [..._parents, _innerPath];
    _innerPath = '$parent/$name/';
    await _load();
  }

  Future<void> _up() async {
    if (_parents.isEmpty) return;
    _innerPath = _parents.removeLast();
    await _load();
  }

  Future<void> _download(FsObject item) async {
    if (_localArchive != null) {
      final path = '${_innerPath == '/' ? '' : _innerPath}${item.name}';
      await _saveLocalZipEntry(
        _localArchive!,
        path,
        item.name,
        url: widget.url,
        headers: widget.headers,
        archivePassword: _archivePassword,
        archiveSize: widget.size,
      );
      return;
    }
    final path = '${_innerPath == '/' ? '' : _innerPath}${item.name}';
    final url = OpenListSession.instance.archive
        .entryUrl(_meta!, path, archivePassword: _archivePassword);
    await DownloadManager.downloadFileWithProgress(
        url: url,
        filename: item.name,
        headers: OpenListSession.instance.archive.headersFor(url));
  }

  static Future<void> _saveLocalZipEntry(
    LocalZipArchive archive,
    String entryPath,
    String filename, {
    required String url,
    required Map<String, String> headers,
    required String archivePassword,
    required int archiveSize,
  }) async {
    final entry = archive.findFile(entryPath);
    if (entry == null) return;
    final extracted = await archive.extract(entry);
    try {
      final size = await extracted.file.length();
      await DownloadManager.saveFileInBackground(
        source: '',
        filename: filename,
        totalBytes: size,
        readChunk: (offset) async {
          final input = await extracted.file.open();
          try {
            await input.setPosition(offset);
            return input.read(1024 * 1024);
          } finally {
            await input.close();
          }
        },
        retry: () async {
          final retryArchive = await LocalZipArchive.download(
            url: url,
            headers: headers,
            expectedSize: archiveSize,
            password: archivePassword,
          );
          try {
            await _saveLocalZipEntry(
              retryArchive,
              entryPath,
              filename,
              url: url,
              headers: headers,
              archivePassword: archivePassword,
              archiveSize: archiveSize,
            );
          } finally {
            await retryArchive.dispose();
          }
        },
      );
    } finally {
      await extracted.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      if (_innerPath != '/')
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _loading ? null : _up,
            icon: const Icon(Icons.arrow_upward),
            label: Text(_innerPath),
          ),
        ),
      Expanded(child: _body()),
    ]);
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null && !_requiresPassword) {
      return StateMessage(
          icon: Icons.error_outline,
          text: errorText(_error!),
          action: S.of(context).retry,
          onAction: _load);
    }
    if (_requiresPassword) {
      return StateMessage(
          icon: Icons.lock_outline,
          text: S.of(context).password,
          action: S.of(context).password,
          onAction: _enterPassword);
    }
    if (_localArchive != null) {
      if (_localEntries.isEmpty) {
        return StateMessage(
            icon: Icons.folder_open, text: S.of(context).noFilesHere);
      }
      return ListView.builder(
        itemCount: _localEntries.length,
        itemBuilder: (context, index) {
          final entry = _localEntries[index];
          return ListTile(
            leading: Icon(entry.isDirectory
                ? Icons.folder
                : Icons.insert_drive_file_outlined),
            title:
                Text(entry.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: entry.isDirectory ? null : Text(formatBytes(entry.size)),
            onTap: entry.isDirectory
                ? () => _openDirectory(entry.name)
                : () => _download(FsObject(
                      name: entry.name,
                      size: entry.size,
                      isDir: false,
                    )),
            trailing: entry.isDirectory
                ? const Icon(Icons.chevron_right)
                : const Icon(Icons.download),
          );
        },
      );
    }
    final content = _result?.content ?? const <FsObject>[];
    if (content.isEmpty) {
      return StateMessage(
          icon: Icons.folder_open, text: S.of(context).noFilesHere);
    }
    return ListView.builder(
      itemCount: content.length,
      itemBuilder: (context, index) {
        final item = content[index];
        return ListTile(
          leading: Icon(
              item.isDir ? Icons.folder : Icons.insert_drive_file_outlined),
          title: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: item.isDir ? null : Text(formatBytes(item.size)),
          onTap: item.isDir
              ? () => _openDirectory(item.name)
              : () => _download(item),
          trailing: item.isDir
              ? const Icon(Icons.chevron_right)
              : const Icon(Icons.download),
        );
      },
    );
  }
}
