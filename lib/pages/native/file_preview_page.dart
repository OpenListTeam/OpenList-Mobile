import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smooth_markdown/flutter_smooth_markdown.dart';
import 'package:openlist_mobile/api/models.dart';
import 'package:openlist_mobile/api/session.dart';
import 'package:openlist_mobile/utils/download_manager.dart';
import 'package:openlist_mobile/utils/recent_files.dart';

import '../../generated/l10n.dart';
import 'archive_preview_view.dart';
import 'common.dart';
import 'media_preview_view.dart';
import 'pdf_preview_view.dart';

/// Native preview dispatcher for Core file objects and supported archives.
class FilePreviewPage extends StatefulWidget {
  const FilePreviewPage({super.key, required this.path, this.password = ''});

  final String path;
  final String password;

  @override
  State<FilePreviewPage> createState() => _FilePreviewPageState();
}

class _FilePreviewPageState extends State<FilePreviewPage> {
  static const _maxTextBytes = 2 * 1024 * 1024;

  FsObject? _obj;
  String? _text;
  bool _isArchive = false;
  Object? _error;
  bool _loading = true;
  Map<String, String> _previewHeaders = const {};

  String get _name => widget.path.split('/').last;

  bool get _isMarkdown => _name.toLowerCase().endsWith('.md');

  bool get _isPdf => _name.toLowerCase().endsWith('.pdf');

  /// raw_url may point to a third-party host, so fall back to the core's own
  /// signed /d link only when it is empty.
  String get _url {
    final o = _obj!;
    if (o.rawUrl.isNotEmpty) return o.rawUrl;
    return OpenListSession.instance.fs.downloadUrl(widget.path, sign: o.sign);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final session = OpenListSession.instance;
      final obj = await session.fs.get(widget.path, password: widget.password);
      _obj = obj;
      if (widget.password.isEmpty) {
        try {
          await RecentFiles.record(widget.path, _name, obj.size, obj.type);
        } catch (_) {}
      }
      _previewHeaders = session.archive.headersFor(_url);
      if (obj.type == ObjType.text && obj.size <= _maxTextBytes) {
        final headers = _previewHeaders;
        final res = await Dio().get<String>(
          _url,
          options: Options(responseType: ResponseType.plain, headers: headers),
        );
        _text = res.data ?? '';
      } else if (obj.type == ObjType.unknown) {
        try {
          final extensions = await session.archive.extensions();
          _isArchive = extensions.any(
            (extension) => _name.toLowerCase().endsWith('.$extension'),
          );
        } catch (_) {
          _isArchive = false;
        }
      }
    } catch (e) {
      _error = e;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _download() async {
    final url = _url;
    await DownloadManager.downloadFileWithProgress(
      url: url,
      filename: _name,
      headers: _previewHeaders,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_name, overflow: TextOverflow.ellipsis),
        actions: [
          if (_obj != null) ...[
            IconButton(
              tooltip: S.of(context).copyLink,
              icon: const Icon(Icons.link),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _url));
                showMessage(S.current.copiedToClipboard);
              },
            ),
            IconButton(
              tooltip: S.of(context).download,
              icon: const Icon(Icons.download),
              onPressed: _download,
            ),
          ],
        ],
      ),
      body: _body(context),
    );
  }

  Widget _body(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return StateMessage(
        icon: Icons.error_outline,
        text: errorText(_error!),
        action: S.of(context).retry,
        onAction: _load,
      );
    }
    final obj = _obj!;
    if (_isArchive) {
      final obj = _obj!;
      return ArchivePreviewView(
        path: widget.path,
        password: widget.password,
        url: _url,
        headers: _previewHeaders,
        size: obj.size,
      );
    }
    if (_isPdf) {
      return PdfPreviewView(url: _url, headers: _previewHeaders);
    }
    if (obj.type == ObjType.image) {
      return InteractiveViewer(
        maxScale: 8,
        child: Center(
          child: Image.network(
            _url,
            headers: _previewHeaders,
            errorBuilder: (_, e, __) =>
                StateMessage(icon: Icons.broken_image, text: '$e'),
          ),
        ),
      );
    }
    if (obj.type == ObjType.video || obj.type == ObjType.audio) {
      return MediaPreviewView(
        url: _url,
        headers: _previewHeaders,
        isVideo: obj.type == ObjType.video,
      );
    }
    final text = _text;
    if (text != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: _isMarkdown
            ? SmoothMarkdown(data: text)
            : SelectableText(
                text,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              ),
      );
    }
    return StateMessage(
      icon: Icons.insert_drive_file_outlined,
      text: '${S.of(context).previewNotSupported}\n${formatBytes(obj.size)}',
      action: S.of(context).download,
      onAction: _download,
    );
  }
}
