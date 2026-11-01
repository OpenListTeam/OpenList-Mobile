import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:openlist_mobile/api/models.dart';
import 'package:openlist_mobile/api/session.dart';

import '../../generated/l10n.dart';
import 'common.dart';
import 'file_preview_page.dart';

/// Searches the server index under [parent]. Pops with a folder path when the
/// user opens a folder hit; file hits open the preview page.
class SearchPage extends StatefulWidget {
  const SearchPage({super.key, required this.parent, this.password = ''});

  final String parent;
  final String password;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  static const _perPage = 100;

  final _ctrl = TextEditingController();
  int _scope = 0;
  String _keywords = '';
  List<SearchHit> _hits = const [];
  int _total = 0;
  int _page = 1;
  bool _loading = false;
  Object? _error;

  /// Bumped per new search so late pages of an old query are dropped.
  int _generation = 0;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _search({bool more = false}) async {
    final keywords = more ? _keywords : _ctrl.text.trim();
    if (keywords.isEmpty) return;
    final gen = more ? _generation : ++_generation;
    final page = more ? _page + 1 : 1;
    setState(() {
      _loading = true;
      _error = null;
      if (!more) {
        _keywords = keywords;
        _hits = const [];
        _total = 0;
      }
    });
    try {
      final (hits, total) = await OpenListSession.instance.fs.search(
          widget.parent, keywords,
          scope: _scope, page: page, perPage: _perPage, password: widget.password);
      if (!mounted || gen != _generation) return;
      setState(() {
        _hits = more ? [..._hits, ...hits] : hits;
        _total = total;
        _page = page;
      });
    } catch (e) {
      if (!mounted || gen != _generation) return;
      _error = e;
    }
    if (mounted && gen == _generation) setState(() => _loading = false);
  }

  void _openHit(SearchHit h) {
    if (h.isDir) {
      Navigator.of(context).pop(h.path);
    } else {
      Get.to(() => FilePreviewPage(path: h.path, password: widget.password));
    }
  }

  IconData _icon(SearchHit h) {
    if (h.isDir) return Icons.folder;
    return switch (h.type) {
      ObjType.image => Icons.image_outlined,
      ObjType.video => Icons.movie_outlined,
      ObjType.audio => Icons.audiotrack_outlined,
      ObjType.text => Icons.description_outlined,
      _ => Icons.insert_drive_file_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
              hintText: S.of(context).searchHint, border: InputBorder.none),
          onSubmitted: (_) => _search(),
        ),
        actions: [
          IconButton(
              tooltip: S.of(context).search,
              icon: const Icon(Icons.search),
              onPressed: _search),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: SegmentedButton<int>(
            segments: [
              ButtonSegment(value: 0, label: Text(S.of(context).searchAll)),
              ButtonSegment(value: 1, label: Text(S.of(context).searchFolders)),
              ButtonSegment(value: 2, label: Text(S.of(context).searchFiles)),
            ],
            selected: {_scope},
            onSelectionChanged: (v) {
              setState(() => _scope = v.first);
              if (_keywords.isNotEmpty) _search();
            },
          ),
        ),
        ListTile(dense: true, title: Text(widget.parent)),
        if (_loading) const LinearProgressIndicator(),
        Expanded(child: _body(context)),
      ]),
    );
  }

  Widget _body(BuildContext context) {
    if (_error != null && _hits.isEmpty) {
      return StateMessage(
          icon: Icons.error_outline,
          text: errorText(_error!),
          action: S.of(context).retry,
          onAction: _search);
    }
    if (_hits.isEmpty) {
      return _keywords.isEmpty || _loading
          ? const SizedBox.shrink()
          : StateMessage(icon: Icons.search_off, text: S.of(context).noSearchResults);
    }
    final hasMore = _hits.length < _total;
    return ListView.builder(
      itemCount: _hits.length + (hasMore ? 1 : 0),
      itemBuilder: (context, i) {
        if (i == _hits.length) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Center(
              child: TextButton(
                onPressed: _loading ? null : () => _search(more: true),
                child: Text('${_hits.length} / $_total'),
              ),
            ),
          );
        }
        final h = _hits[i];
        return ListTile(
          leading: Icon(_icon(h)),
          title: Text(h.name, overflow: TextOverflow.ellipsis),
          subtitle: Text(
              h.isDir ? h.parent : '${h.parent} · ${formatBytes(h.size)}',
              overflow: TextOverflow.ellipsis),
          onTap: () => _openHit(h),
        );
      },
    );
  }
}
