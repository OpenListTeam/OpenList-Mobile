import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smooth_markdown/flutter_smooth_markdown.dart';
import 'package:openlist_mobile/api/models.dart';
import 'package:openlist_mobile/api/session.dart';
import 'package:openlist_mobile/utils/download_manager.dart';

import '../../generated/l10n.dart';
import 'common.dart';

/// Previews images, text and markdown; other types can be downloaded.
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
  Object? _error;
  bool _loading = true;

  String get _name => widget.path.split('/').last;

  bool get _isMarkdown => _name.toLowerCase().endsWith('.md');

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
      final obj = await OpenListSession.instance.fs.get(widget.path, password: widget.password);
      _obj = obj;
      if (obj.type == ObjType.text && obj.size <= _maxTextBytes) {
        // Plain Dio on purpose: never forward the OpenList token to raw_url.
        final res = await Dio().get<String>(_url,
            options: Options(responseType: ResponseType.plain));
        _text = res.data ?? '';
      }
    } catch (e) {
      _error = e;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _download() async {
    await DownloadManager.downloadFileWithProgress(url: _url, filename: _name);
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
          onAction: _load);
    }
    final obj = _obj!;
    if (obj.type == ObjType.image) {
      return InteractiveViewer(
        maxScale: 8,
        child: Center(
          child: Image.network(_url,
              errorBuilder: (_, e, __) =>
                  StateMessage(icon: Icons.broken_image, text: '$e')),
        ),
      );
    }
    final text = _text;
    if (text != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: _isMarkdown
            ? SmoothMarkdown(data: text)
            : SelectableText(text,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
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
