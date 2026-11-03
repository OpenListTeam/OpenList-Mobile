import 'package:flutter/material.dart';
import 'package:openlist_mobile/api/archive_api.dart';
import 'package:openlist_mobile/api/models.dart';
import 'package:openlist_mobile/api/openlist_client.dart';
import 'package:openlist_mobile/api/session.dart';
import 'package:openlist_mobile/generated/l10n.dart';
import 'package:openlist_mobile/pages/native/common.dart';
import 'package:openlist_mobile/utils/download_manager.dart';

/// Browses archive members exclusively through Core's authenticated API.
class ArchivePreviewView extends StatefulWidget {
  const ArchivePreviewView(
      {super.key, required this.path, required this.password});

  final String path;
  final String password;

  @override
  State<ArchivePreviewView> createState() => _ArchivePreviewViewState();
}

class _ArchivePreviewViewState extends State<ArchivePreviewView> {
  String _archivePassword = '';
  String _innerPath = '/';
  List<String> _parents = [];
  FsListResult? _result;
  ArchiveMeta? _meta;
  Object? _error;
  bool _loading = true;
  bool _requiresPassword = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _requiresPassword = false;
    });
    try {
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
    } catch (e) {
      _error = e;
      _requiresPassword = e is ApiException && e.code == 202;
      if (_requiresPassword) _meta = null;
    }
    if (mounted) setState(() => _loading = false);
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
    final path = '${_innerPath == '/' ? '' : _innerPath}${item.name}';
    final url = OpenListSession.instance.archive
        .entryUrl(_meta!, path, archivePassword: _archivePassword);
    await DownloadManager.downloadFileWithProgress(
        url: url,
        filename: item.name,
        headers: OpenListSession.instance.archive.headersFor(url));
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
