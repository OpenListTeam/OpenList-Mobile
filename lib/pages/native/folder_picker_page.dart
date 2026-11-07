import 'dart:async';

import 'package:flutter/material.dart';
import 'package:openlist_mobile/api/models.dart';
import 'package:openlist_mobile/api/openlist_client.dart';
import 'package:openlist_mobile/api/session.dart';

import '../../generated/l10n.dart';
import 'common.dart';

/// Picks a destination folder; pops with the selected path.
class FolderPickerPage extends StatefulWidget {
  const FolderPickerPage({
    super.key,
    required this.title,
    this.initial = '/',
    this.password = '',
  });

  final String title;
  final String initial;
  final String password;

  @override
  State<FolderPickerPage> createState() => _FolderPickerPageState();
}

class _FolderPickerPageState extends State<FolderPickerPage> {
  late String _path = widget.initial;
  List<FsObject> _dirs = const [];
  Object? _error;
  bool _loading = true;
  final _passwords = <String, String>{};
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _passwords[widget.initial] = widget.password;
    _load();
  }

  Future<void> _load() async {
    final path = _path;
    final request = ++_request;
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final res = await OpenListSession.instance.fs.list(
        path,
        password: _passwordFor(path),
      );
      if (!mounted || request != _request || _path != path) return;
      setState(() => _dirs = res.content.where((e) => e.isDir).toList());
    } on ApiException catch (e) {
      if (!mounted || request != _request || _path != path) return;
      if (e.isPasswordRequired) {
        final password = await promptText(
          context,
          title: S.current.folderPassword,
          label: path,
          obscure: true,
        );
        if (password != null &&
            mounted &&
            request == _request &&
            _path == path) {
          _passwords[path] = password;
          unawaited(_load());
          return;
        }
      }
      _error = e;
    } catch (e) {
      if (!mounted || request != _request || _path != path) return;
      _error = e;
    }
    if (mounted && request == _request && _path == path) {
      setState(() => _loading = false);
    }
  }

  void _open(String path) {
    _path = path;
    _load();
  }

  String _passwordFor(String path) {
    var current = path;
    while (true) {
      final password = _passwords[current];
      if (password != null) return password;
      if (current == '/' || current.isEmpty) return '';
      final separator = current.lastIndexOf('/');
      current = separator <= 0 ? '/' : current.substring(0, separator);
    }
  }

  String get _parent {
    final i = _path.lastIndexOf('/');
    return i <= 0 ? '/' : _path.substring(0, i);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _path == '/',
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _open(_parent);
      },
      child: Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.folder_open),
              title: Text(_path),
              trailing: _path == '/'
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.arrow_upward),
                      onPressed: () => _open(_parent),
                    ),
            ),
            const Divider(height: 1),
            Expanded(child: _list()),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(_path),
              child: Text(S.of(context).selectThisFolder),
            ),
          ),
        ),
      ),
    );
  }

  Widget _list() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return StateMessage(
        icon: Icons.error_outline,
        text: errorText(_error!),
        action: S.current.retry,
        onAction: _load,
      );
    }
    if (_dirs.isEmpty) {
      return StateMessage(icon: Icons.folder_off, text: S.current.emptyFolder);
    }
    return ListView.builder(
      itemCount: _dirs.length,
      itemBuilder: (_, i) => ListTile(
        leading: const Icon(Icons.folder),
        title: Text(_dirs[i].name),
        onTap: () => _open(OpenListClient.join(_path, _dirs[i].name)),
      ),
    );
  }
}
