import 'models.dart';
import 'openlist_client.dart';

class MediaPage {
  const MediaPage({required this.items, required this.total});

  final List<MediaItem> items;
  final int total;
}

class MediaApi {
  MediaApi(this.client);

  final OpenListClient client;

  Future<MediaStatus> status() async {
    final data = await client.get('/api/public/media_status');
    return MediaStatus.fromJson(Map<String, dynamic>.from(data ?? {}));
  }

  Future<MediaPage> list(String mediaType, {int page = 1, int pageSize = 40}) =>
      _page('/api/fs/media/list', {
        'media_type': mediaType,
        'page': page,
        'page_size': pageSize,
        'order_by': 'created_at',
        'order_dir': 'desc',
      });

  Future<MediaPage> favorites(String mediaType,
          {int page = 1, int pageSize = 20}) =>
      _page('/api/fs/media/favorites', {
        'media_type': mediaType,
        'page': page,
        'page_size': pageSize,
      });

  Future<void> setFavorite(int itemId, bool favorite) =>
      client.post('/api/fs/media/favorite', body: {
        'item_id': itemId,
        'episode_index': 0,
        'favorite': favorite,
      });

  Future<MediaPage> _page(String path, Map<String, dynamic> query) async {
    final data = await client.get(path, query: query);
    final map = data is Map ? data : const {};
    final items = ((map['content'] as List?) ?? const [])
        .map((item) => MediaItem.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    final total = map['total'];
    return MediaPage(
      items: items,
      total: total is num ? total.toInt() : items.length,
    );
  }
}
