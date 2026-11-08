import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:openlist_mobile/api/session.dart';

import '../../generated/l10n.dart';
import 'common.dart';

const _mediaTypes = ['video', 'music', 'image', 'book'];

String _mediaTypeLabel(String type) => switch (type) {
  'video' => S.current.adminMediaTypeVideo,
  'music' => S.current.adminMediaTypeMusic,
  'image' => S.current.adminMediaTypeImage,
  'book' => S.current.adminMediaTypeBook,
  _ => type,
};

class MediaAdminPage extends StatefulWidget {
  const MediaAdminPage({super.key});

  @override
  State<MediaAdminPage> createState() => _MediaAdminPageState();
}

class _MediaAdminPageState extends State<MediaAdminPage> {
  String _currentMediaType(BuildContext context) =>
      _mediaTypes[DefaultTabController.of(context).index];

  Future<void> _export(BuildContext context, String mediaType) async {
    try {
      final data = await OpenListSession.instance.admin.exportMedia(
        mediaType: mediaType,
      );
      final bytes = Uint8List.fromList(
        utf8.encode(const JsonEncoder.withIndent('  ').convert(data)),
      );
      final path = await FilePicker.saveFile(
        fileName: 'openlist-media-$mediaType.json',
        bytes: bytes,
      );
      if (path != null && context.mounted) {
        showMessage(S.current.adminMediaExportSaved);
      }
    } catch (e) {
      if (context.mounted) showError(e);
    }
  }

  Future<void> _import(BuildContext context) async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['json'],
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map) throw const FormatException('Invalid media export');
      await OpenListSession.instance.admin.importMedia(
        Map<String, dynamic>.from(decoded),
      );
      if (context.mounted) showMessage(S.current.adminMediaImportDone);
    } catch (e) {
      if (context.mounted) showError(e);
    }
  }

  Future<void> _generateStrm(BuildContext context, String mediaType) async {
    try {
      final result = await OpenListSession.instance.admin.generateMediaStrm(
        mediaType: mediaType,
      );
      if (context.mounted) {
        showMessage(
          S.current.adminMediaStrmDone(
            '${result['written'] ?? 0}',
            '${result['path'] ?? ''}',
          ),
        );
      }
    } catch (e) {
      if (context.mounted) showError(e);
    }
  }

  Future<void> _manageAppKeys(BuildContext context) async {
    final api = OpenListSession.instance.admin;
    List<Map<String, dynamic>> keys;
    try {
      keys = await api.listMediaAppKeys();
    } catch (e) {
      if (context.mounted) showError(e);
      return;
    }
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(S.current.adminMediaAppKeys),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (keys.isEmpty) Text(S.current.adminEmpty),
                  for (final key in keys)
                    ListTile(
                      title: Text('${key['name'] ?? ''}'),
                      subtitle: Text('${key['prefix'] ?? ''}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          if (!await confirmDialog(
                            context,
                            S.current.adminMediaDeleteKeyConfirm,
                            title: S.current.delete,
                          )) {
                            return;
                          }
                          try {
                            await api.deleteMediaAppKey(
                              (key['id'] as num).toInt(),
                            );
                            setDialogState(() => keys.remove(key));
                          } catch (e) {
                            showError(e);
                          }
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(S.current.cancel),
            ),
            FilledButton.tonal(
              onPressed: () async {
                final name = await promptText(
                  context,
                  title: S.current.adminMediaNewAppKey,
                  label: S.current.adminMediaAppKeyName,
                );
                if (name == null) return;
                try {
                  final created = await api.createMediaAppKey(name);
                  if (!context.mounted) return;
                  await showDialog<void>(
                    context: context,
                    builder: (keyContext) => AlertDialog(
                      title: Text(S.current.adminMediaKeyCreated),
                      content: SelectableText(
                        '${S.current.adminMediaKeyShownOnce}\n\n${created['key'] ?? ''}',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(text: '${created['key'] ?? ''}'),
                            );
                            if (keyContext.mounted) {
                              Navigator.pop(keyContext);
                              showMessage(S.current.copiedToClipboard);
                            }
                          },
                          child: Text(S.current.copy),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(keyContext),
                          child: Text(S.current.confirm),
                        ),
                      ],
                    ),
                  );
                  keys = await api.listMediaAppKeys();
                  if (context.mounted) setDialogState(() {});
                } catch (e) {
                  if (context.mounted) showError(e);
                }
              },
              child: Text(S.current.adminMediaNewAppKey),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: _mediaTypes.length,
    child: Builder(
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: Text(S.of(context).adminMediaTitle),
          actions: [
            PopupMenuButton<String>(
              onSelected: (action) {
                final mediaType = _currentMediaType(context);
                switch (action) {
                  case 'export':
                    _export(context, mediaType);
                  case 'import':
                    _import(context);
                  case 'strm':
                    _generateStrm(context, mediaType);
                  case 'keys':
                    _manageAppKeys(context);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'export',
                  child: Text(S.current.adminMediaExport),
                ),
                PopupMenuItem(
                  value: 'import',
                  child: Text(S.current.adminMediaImport),
                ),
                PopupMenuItem(
                  value: 'strm',
                  child: Text(S.current.adminMediaGenerateStrm),
                ),
                PopupMenuItem(
                  value: 'keys',
                  child: Text(S.current.adminMediaAppKeys),
                ),
              ],
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              for (final type in _mediaTypes) Tab(text: _mediaTypeLabel(type)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            for (final type in _mediaTypes)
              _MediaTypeAdminView(key: ValueKey(type), mediaType: type),
          ],
        ),
      ),
    ),
  );
}

class _MediaTypeAdminView extends StatefulWidget {
  const _MediaTypeAdminView({super.key, required this.mediaType});

  final String mediaType;

  @override
  State<_MediaTypeAdminView> createState() => _MediaTypeAdminViewState();
}

class _MediaTypeAdminViewState extends State<_MediaTypeAdminView> {
  Map<String, dynamic> _config = const {};
  List<Map<String, dynamic>> _paths = const [];
  List<Map<String, dynamic>> _items = const [];
  Map<String, dynamic> _progress = const {};
  Object? _error;
  bool _loading = true;
  bool _busy = false;
  int _page = 1;
  int _total = 0;
  static const _pageSize = 30;

  Future<void> _load({bool quiet = false}) async {
    if (!quiet) setState(() => _loading = true);
    try {
      final api = OpenListSession.instance.admin;
      final results = await Future.wait([
        api.listMediaConfigs(),
        api.listMediaScanPaths(mediaType: widget.mediaType),
        api.listAdminMediaItems(
          mediaType: widget.mediaType,
          page: _page,
          pageSize: _pageSize,
        ),
        api.mediaScanProgress(widget.mediaType),
      ]);
      if (!mounted) return;
      _config = (results[0] as List<Map<String, dynamic>>).firstWhere(
        (item) => item['media_type'] == widget.mediaType,
        orElse: () => {'media_type': widget.mediaType, 'enabled': false},
      );
      _paths = results[1] as List<Map<String, dynamic>>;
      final itemPage = results[2] as Map<String, dynamic>;
      _items = (itemPage['content'] as List? ?? const [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      _total = (itemPage['total'] as num?)?.toInt() ?? _items.length;
      _progress = results[3] as Map<String, dynamic>;
      _error = null;
    } catch (e) {
      if (mounted && !quiet) _error = e;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _act(
    Future<void> Function() action, {
    bool confirm = false,
  }) async {
    if (_busy) return;
    if (confirm &&
        !await confirmDialog(
          context,
          S.current.adminMediaConfirmClear,
          title: S.current.adminMediaTitle,
        )) {
      return;
    }
    setState(() => _busy = true);
    try {
      await action();
      await _load(quiet: true);
    } catch (e) {
      if (mounted) showError(e);
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _setEnabled(bool value) async {
    final updated = {..._config, 'enabled': value};
    await _act(() => OpenListSession.instance.admin.saveMediaConfig(updated));
  }

  Future<void> _editPath([Map<String, dynamic>? source]) async {
    final name = TextEditingController(text: '${source?['name'] ?? ''}');
    final path = TextEditingController(text: '${source?['path'] ?? '/'}');
    final typeTag = TextEditingController(text: '${source?['type_tag'] ?? ''}');
    final contentTags = TextEditingController(
      text: '${source?['content_tags'] ?? ''}',
    );
    var pathMerge = source?['path_merge'] == true;
    var enableScrape = source?['enable_scrape'] != false;
    try {
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text(
              source == null ? S.current.adminAddPath : S.current.adminSavePath,
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _textField(name, S.current.adminMediaName),
                  _textField(path, S.current.adminMediaPath),
                  _textField(typeTag, S.current.adminMediaTypeTag),
                  _textField(contentTags, S.current.adminMediaContentTags),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(S.current.adminMediaPathMerge),
                    value: pathMerge,
                    onChanged: (value) =>
                        setDialogState(() => pathMerge = value),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(S.current.adminMediaEnableScrape),
                    value: enableScrape,
                    onChanged: (value) =>
                        setDialogState(() => enableScrape = value),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(S.current.cancel),
              ),
              FilledButton(
                onPressed: () {
                  if (path.text.trim().isEmpty) {
                    showMessage(S.current.adminMetaInvalidInput);
                    return;
                  }
                  Navigator.pop(dialogContext, {
                    if (source != null) 'id': source['id'],
                    'media_type': widget.mediaType,
                    'name': name.text.trim(),
                    'path': path.text.trim(),
                    'path_merge': pathMerge,
                    'type_tag': typeTag.text.trim(),
                    'content_tags': contentTags.text.trim(),
                    'enable_scrape': enableScrape,
                  });
                },
                child: Text(S.current.save),
              ),
            ],
          ),
        ),
      );
      if (result == null || !mounted) return;
      await _act(() async {
        final api = OpenListSession.instance.admin;
        if (source == null) {
          await api.createMediaScanPath(result);
        } else {
          await api.updateMediaScanPath(result);
        }
      });
    } finally {
      name.dispose();
      path.dispose();
      typeTag.dispose();
      contentTags.dispose();
    }
  }

  Widget _textField(
    TextEditingController controller,
    String label, {
    int minLines = 1,
    int maxLines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label),
    ),
  );

  Future<void> _editItem(Map<String, dynamic> source) async {
    final title = TextEditingController(
      text: '${source['scraped_name'] ?? ''}',
    );
    final description = TextEditingController(
      text: '${source['description'] ?? ''}',
    );
    var hidden = source['hidden'] == true;
    try {
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text(S.current.edit),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _textField(title, S.current.adminMediaName),
                  _textField(
                    description,
                    S.current.description,
                    minLines: 3,
                    maxLines: 6,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(S.current.adminMediaHidden),
                    value: hidden,
                    onChanged: (value) => setDialogState(() => hidden = value),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(S.current.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, {
                  ...source,
                  'scraped_name': title.text,
                  'description': description.text,
                  'hidden': hidden,
                }),
                child: Text(S.current.save),
              ),
            ],
          ),
        ),
      );
      if (result == null || !mounted) return;
      await _act(
        () => OpenListSession.instance.admin.updateAdminMediaItem(result),
      );
    } finally {
      title.dispose();
      description.dispose();
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _config.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _config.isEmpty) {
      return StateMessage(
        icon: Icons.error_outline,
        text: errorText(_error!),
        action: S.of(context).retry,
        onAction: _load,
      );
    }
    final enabled = _config['enabled'] == true;
    final running = _progress['running'] == true;
    final progressTotal = (_progress['total'] as num?)?.toInt() ?? 0;
    final progressDone = (_progress['done'] as num?)?.toInt() ?? 0;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          SwitchListTile(
            title: Text(S.current.adminMediaEnabled),
            subtitle: Text(_mediaTypeLabel(widget.mediaType)),
            value: enabled,
            onChanged: _busy ? null : _setEnabled,
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    S.current.adminMediaProgress,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    running
                        ? '${S.current.adminMediaRunning}: $progressDone / $progressTotal'
                        : S.current.adminMediaDone,
                  ),
                  if ((_progress['message'] as String? ?? '').isNotEmpty)
                    Text('${_progress['message']}'),
                  if ((_progress['error'] as String? ?? '').isNotEmpty)
                    Text('${_progress['error']}'),
                ],
              ),
            ),
          ),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: [
              FilledButton.tonal(
                onPressed: _busy || !enabled
                    ? null
                    : () => _act(
                        () => OpenListSession.instance.admin.startMediaScan(
                          widget.mediaType,
                        ),
                      ),
                child: Text(S.current.adminMediaScan),
              ),
              FilledButton.tonal(
                onPressed: _busy || !enabled
                    ? null
                    : () => _act(
                        () => OpenListSession.instance.admin.startMediaScrape(
                          widget.mediaType,
                        ),
                      ),
                child: Text(S.current.adminMediaScrape),
              ),
              PopupMenuButton<String>(
                enabled: !_busy,
                onSelected: (action) => switch (action) {
                  'clear' => _act(
                    () => OpenListSession.instance.admin.clearMedia(
                      widget.mediaType,
                    ),
                    confirm: true,
                  ),
                  'scrape' => _act(
                    () => OpenListSession.instance.admin.clearMediaScrape(
                      mediaType: widget.mediaType,
                    ),
                    confirm: true,
                  ),
                  _ => _act(
                    () => OpenListSession.instance.admin.deleteInvalidMedia(
                      mediaType: widget.mediaType,
                    ),
                    confirm: true,
                  ),
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'clear',
                    child: Text(S.current.adminMediaClear),
                  ),
                  PopupMenuItem(
                    value: 'scrape',
                    child: Text(S.current.adminMediaClearScrape),
                  ),
                  PopupMenuItem(
                    value: 'invalid',
                    child: Text(S.current.adminMediaDeleteInvalid),
                  ),
                ],
              ),
            ],
          ),
          ListTile(
            title: Text(S.current.adminMediaScanPaths),
            trailing: IconButton(
              onPressed: _busy ? null : () => _editPath(),
              icon: const Icon(Icons.add),
            ),
          ),
          for (final path in _paths)
            ListTile(
              title: Text('${path['name'] ?? path['path'] ?? ''}'),
              subtitle: Text('${path['path'] ?? ''}'),
              trailing: PopupMenuButton<String>(
                onSelected: (action) => switch (action) {
                  'edit' => _editPath(path),
                  'scan' => _act(
                    () => OpenListSession.instance.admin.startMediaScan(
                      widget.mediaType,
                      scanPathId: (path['id'] as num).toInt(),
                    ),
                  ),
                  'clear' => _act(
                    () => OpenListSession.instance.admin.clearMediaScanPath(
                      (path['id'] as num).toInt(),
                    ),
                    confirm: true,
                  ),
                  _ => _act(
                    () => OpenListSession.instance.admin.deleteMediaScanPath(
                      (path['id'] as num).toInt(),
                    ),
                    confirm: true,
                  ),
                },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'edit', child: Text(S.current.edit)),
                  PopupMenuItem(
                    value: 'scan',
                    child: Text(S.current.adminMediaScan),
                  ),
                  PopupMenuItem(
                    value: 'clear',
                    child: Text(S.current.adminMediaClear),
                  ),
                  PopupMenuItem(value: 'delete', child: Text(S.current.delete)),
                ],
              ),
            ),
          ListTile(
            title: Text('${S.current.files} ($_total)'),
            trailing: Wrap(
              children: [
                IconButton(
                  tooltip: S.current.adminPreviousPage,
                  onPressed: _page > 1
                      ? () {
                          setState(() => _page--);
                          _load();
                        }
                      : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                IconButton(
                  tooltip: S.current.adminNextPage,
                  onPressed: _page * _pageSize < _total
                      ? () {
                          setState(() => _page++);
                          _load();
                        }
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
          for (final item in _items)
            ListTile(
              title: Text(
                '${item['scraped_name'] ?? ''}'.isNotEmpty
                    ? '${item['scraped_name']}'
                    : '${item['file_name'] ?? ''}',
              ),
              subtitle: Text(
                '${item['folder_path'] ?? ''}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (action) async {
                  if (action == 'edit') {
                    await _editItem(item);
                  } else if (action == 'scrape') {
                    await _act(
                      () => OpenListSession.instance.admin.startMediaScrape(
                        widget.mediaType,
                        itemId: (item['id'] as num).toInt(),
                      ),
                    );
                  } else if (await confirmDialog(
                    context,
                    S.current.adminMediaConfirmClear,
                    title: S.current.delete,
                  )) {
                    await _act(
                      () => OpenListSession.instance.admin.deleteAdminMediaItem(
                        (item['id'] as num).toInt(),
                      ),
                    );
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'edit', child: Text(S.current.edit)),
                  PopupMenuItem(
                    value: 'scrape',
                    child: Text(S.current.adminMediaScrape),
                  ),
                  PopupMenuItem(value: 'delete', child: Text(S.current.delete)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
