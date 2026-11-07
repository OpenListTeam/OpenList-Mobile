import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:openlist_mobile/api/models.dart';
import 'package:openlist_mobile/api/session.dart';
import 'package:openlist_mobile/generated/l10n.dart';
import 'package:openlist_mobile/pages/native/common.dart';
import 'package:openlist_mobile/pages/native/file_preview_page.dart';

class MediaLibraryPage extends StatefulWidget {
  const MediaLibraryPage({super.key, required this.favorites, this.mediaType});

  final bool favorites;
  final String? mediaType;

  @override
  State<MediaLibraryPage> createState() => _MediaLibraryPageState();
}

class _MediaLibraryPageState extends State<MediaLibraryPage> {
  final _scrollController = ScrollController();
  final List<MediaItem> _items = [];
  MediaStatus? _status;
  Object? _error;
  int _page = 1;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _generation = 0;

  int get _pageSize => widget.favorites ? 20 : 40;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadMoreWhenNeeded);
    _load(reset: true);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_loadMoreWhenNeeded)
      ..dispose();
    super.dispose();
  }

  void _loadMoreWhenNeeded() {
    if (_scrollController.hasClients &&
        _scrollController.position.extentAfter < 500) {
      _loadMore();
    }
  }

  Future<void> _load({bool reset = false, int? page}) async {
    if (reset) {
      _generation++;
      setState(() {
        _loading = true;
        _loadingMore = false;
        _error = null;
        _page = 1;
        _hasMore = true;
        _items.clear();
      });
    }
    final generation = _generation;
    final requestedPage = reset ? 1 : page ?? _page;
    try {
      final api = OpenListSession.instance.media;
      final status = reset || _status == null ? await api.status() : _status!;
      if (!mounted || generation != _generation) return;
      _status = status;
      final type = widget.mediaType;
      if (!status.enabled || (type != null && !status.types.contains(type))) {
        setState(() {
          _loading = false;
          _loadingMore = false;
          _hasMore = false;
        });
        return;
      }
      final result = widget.favorites
          ? await api.favorites(type ?? '', page: requestedPage)
          : await api.list(type!, page: requestedPage);
      if (!mounted || generation != _generation) return;
      setState(() {
        _items.addAll(result.items);
        _page = requestedPage;
        _hasMore = requestedPage * _pageSize < result.total;
        _error = null;
        _loading = false;
        _loadingMore = false;
      });
    } catch (error) {
      if (mounted && generation == _generation) {
        setState(() {
          _error = error;
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || !_hasMore || _status == null) return;
    setState(() {
      _loadingMore = true;
      _error = null;
    });
    await _load(page: _page + 1);
  }

  Future<void> _toggleFavorite(MediaItem item) async {
    if (OpenListSession.instance.user?.isGuest ?? true) return;
    try {
      await OpenListSession.instance.media
          .setFavorite(item.id, !widget.favorites);
      if (widget.favorites) {
        setState(() => _items.remove(item));
      } else {
        showMessage(S.current.mediaFavoriteAdded);
      }
    } catch (error) {
      showError(error);
    }
  }

  Future<void> _openMedia(MediaItem item) async {
    if (!item.isFolder) {
      await Get.to(() => FilePreviewPage(path: item.path));
      return;
    }
    final episodes = item.episodes;
    if (episodes.isEmpty || !mounted) return;
    final selected = await showModalBottomSheet<MediaEpisode>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final episode in episodes)
              ListTile(
                title: Text(episode.title),
                subtitle: Text(episode.fileName),
                onTap: () => Navigator.pop(context, episode),
              ),
          ],
        ),
      ),
    );
    if (selected != null && mounted) {
      await Get.to(() => FilePreviewPage(path: item.episodePath(selected)));
    }
  }

  Widget _coverImage(String cover) {
    final fallback = const Center(
      child: Icon(Icons.broken_image_outlined, size: 48),
    );
    if (cover.startsWith('data:image/') && cover.contains(',')) {
      try {
        return Image.memory(
          base64Decode(cover.substring(cover.indexOf(',') + 1)),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback,
        );
      } on FormatException {
        return fallback;
      }
    }
    return Image.network(
      cover,
      headers: OpenListSession.instance.archive.headersFor(cover),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallback,
    );
  }

  String get _title {
    if (widget.favorites) return S.current.favorites;
    return widget.mediaType == 'image' ? S.current.photos : S.current.videos;
  }

  String _coverUrl(MediaItem item) {
    final session = OpenListSession.instance;
    final client = session.client;
    final cover = item.cover;
    if (cover.isEmpty) {
      return widget.mediaType == 'image' && !item.isFolder && client != null
          ? session.fs.downloadUrl(item.path)
          : '';
    }
    if (cover.startsWith('data:') || cover.startsWith('blob:')) return cover;
    if (client == null) return '';
    if (cover.startsWith('thumb:')) {
      return '${client.baseUrl}/api/public/media/thumb?path=${Uri.encodeQueryComponent(cover.substring(6))}';
    }
    if (cover.startsWith('http://') || cover.startsWith('https://')) {
      if (_status?.proxyCover == true) {
        return '${client.baseUrl}/api/public/media/proxy?url=${Uri.encodeQueryComponent(cover)}';
      }
      return cover;
    }
    return cover.startsWith('/') ? '${client.baseUrl}$cover' : cover;
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.mediaType;
    final unavailable = _status != null &&
        (!_status!.enabled || (type != null && !_status!.types.contains(type)));
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : unavailable
              ? StateMessage(
                  icon: Icons.photo_library_outlined,
                  text: S.current.mediaLibraryUnavailable,
                )
              : _error != null && _items.isEmpty
                  ? StateMessage(
                      icon: Icons.error_outline,
                      text: errorText(_error!),
                      action: S.current.retry,
                      onAction: () => _load(reset: true),
                    )
                  : _items.isEmpty
                      ? StateMessage(
                          icon: Icons.photo_library_outlined,
                          text: S.current.noMediaItems,
                        )
                      : RefreshIndicator(
                          onRefresh: () => _load(reset: true),
                          child: GridView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(12),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.78,
                            ),
                            itemCount: _items.length +
                                (_loadingMore ||
                                        (_error != null && _items.isNotEmpty)
                                    ? 1
                                    : 0),
                            itemBuilder: (context, index) {
                              if (index >= _items.length) {
                                if (_error != null) {
                                  return Center(
                                    child: TextButton.icon(
                                      onPressed: _loadMore,
                                      icon: const Icon(Icons.refresh),
                                      label: Text(S.current.retry),
                                    ),
                                  );
                                }
                                return const Center(
                                    child: CircularProgressIndicator());
                              }
                              final item = _items[index];
                              final cover = _coverUrl(item);
                              return Card(
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: () => _openMedia(item),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(
                                        child: cover.isEmpty
                                            ? const Center(
                                                child: Icon(
                                                  Icons.perm_media_outlined,
                                                  size: 56,
                                                ),
                                              )
                                            : _coverImage(cover),
                                      ),
                                      ListTile(
                                        dense: true,
                                        title: Text(
                                          item.displayName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        subtitle: item.isFolder
                                            ? null
                                            : Text(formatBytes(item.fileSize)),
                                        trailing: (OpenListSession
                                                    .instance.user?.isGuest ??
                                                true)
                                            ? null
                                            : IconButton(
                                                tooltip: widget.favorites
                                                    ? S.current
                                                        .removeMediaFavorite
                                                    : S.current
                                                        .addMediaFavorite,
                                                onPressed: () =>
                                                    _toggleFavorite(item),
                                                icon: Icon(widget.favorites
                                                    ? Icons.star
                                                    : Icons.star_border),
                                              ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
    );
  }
}
