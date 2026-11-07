import 'package:flutter/material.dart';
import 'package:openlist_mobile/api/session.dart';

import '../../generated/l10n.dart';
import 'common.dart';

/// Delete policies accepted by `/api/fs/add_offline_download`.
const _policies = [
  'delete_on_upload_succeed',
  'delete_on_upload_failed',
  'delete_never',
  'delete_always',
  'upload_download_stream',
];

String _policyLabel(String p) => switch (p) {
  'delete_on_upload_succeed' => S.current.policyDeleteOnUploadSucceed,
  'delete_on_upload_failed' => S.current.policyDeleteOnUploadFailed,
  'delete_never' => S.current.policyDeleteNever,
  'delete_always' => S.current.policyDeleteAlways,
  _ => S.current.policyUploadDownloadStream,
};

/// Asks for URLs and a tool, then queues offline downloads into [dir].
/// Returns true when tasks were added.
Future<bool> showOfflineDownloadDialog(BuildContext context, String dir) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => _OfflineDownloadDialog(dir: dir),
  );
  return ok == true;
}

class _OfflineDownloadDialog extends StatefulWidget {
  const _OfflineDownloadDialog({required this.dir});

  final String dir;

  @override
  State<_OfflineDownloadDialog> createState() => _OfflineDownloadDialogState();
}

class _OfflineDownloadDialogState extends State<_OfflineDownloadDialog> {
  final _urls = TextEditingController();
  List<String>? _tools;
  String? _tool;
  String _policy = _policies.first;
  Object? _error;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadTools();
  }

  @override
  void dispose() {
    _urls.dispose();
    super.dispose();
  }

  Future<void> _loadTools() async {
    try {
      final tools = await OpenListSession.instance.fs.offlineTools(
        path: widget.dir,
      );
      if (!mounted) return;
      setState(() {
        _tools = tools;
        _tool = tools.isEmpty ? null : tools.first;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _submit() async {
    final urls = _urls.text
        .split(RegExp(r'\s+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final tool = _tool;
    if (urls.isEmpty || tool == null) return;
    setState(() => _submitting = true);
    try {
      await OpenListSession.instance.fs.addOfflineDownload(
        urls,
        widget.dir,
        tool,
        deletePolicy: _policy,
      );
      if (mounted) Navigator.of(context).pop(true);
      showMessage(S.current.offlineAdded);
      return;
    } catch (e) {
      showError(e);
    }
    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final tools = _tools;
    Widget content;
    if (_error != null) {
      content = Text(errorText(_error!));
    } else if (tools == null) {
      content = const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (tools.isEmpty) {
      content = Text(S.of(context).noOfflineTools);
    } else {
      content = SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.dir, style: Theme.of(context).textTheme.bodySmall),
            TextField(
              controller: _urls,
              autofocus: true,
              minLines: 3,
              maxLines: 8,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(labelText: S.of(context).offlineUrls),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _tool,
              isExpanded: true,
              decoration: InputDecoration(labelText: S.of(context).offlineTool),
              items: [
                for (final t in tools)
                  DropdownMenuItem(value: t, child: Text(t)),
              ],
              onChanged: (v) => setState(() => _tool = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _policy,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: S.of(context).deletePolicy,
              ),
              items: [
                for (final p in _policies)
                  DropdownMenuItem(value: p, child: Text(_policyLabel(p))),
              ],
              onChanged: (v) => setState(() => _policy = v ?? _policy),
            ),
          ],
        ),
      );
    }
    return AlertDialog(
      title: Text(S.of(context).offlineDownload),
      content: content,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(S.of(context).cancel),
        ),
        if (tools != null && tools.isNotEmpty)
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: Text(S.of(context).confirm),
          ),
      ],
    );
  }
}
