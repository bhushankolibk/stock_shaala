import 'package:dio/dio.dart';
import '../../data/models/youtube_models.dart';

class YouTubeService {
  final Dio _dio;
  final String channelId;
  final String apiKey;

  YouTubeService({required this.channelId, required this.apiKey, Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 12),
              receiveTimeout: const Duration(seconds: 12),
            ));

  static const _base = 'https://www.googleapis.com/youtube/v3';

  // Playlists and their videos barely change, and the YouTube Data API has
  // a strict daily quota, so cache both for the app session — avoids
  // re-fetching every time the user re-opens the same playlist.
  List<YTPlaylist>? _playlistsCache;
  final _videosCache = <String, List<YTVideo>>{};

  Future<List<YTPlaylist>> fetchPlaylists({bool forceRefresh = false}) async {
    if (!forceRefresh && _playlistsCache != null) return _playlistsCache!;
    final res = await _dio.get(
      '$_base/playlists',
      queryParameters: {
        'part': 'snippet,contentDetails',
        'channelId': channelId,
        'key': apiKey,
        'maxResults': 20,
        'fields':
            'items(id,snippet(title,description,thumbnails),contentDetails/itemCount)',
      },
    );
    final items = (res.data['items'] as List?) ?? [];
    final playlists =
        items.map((e) => YTPlaylist.fromJson(e as Map<String, dynamic>)).toList();
    _playlistsCache = playlists;
    return playlists;
  }

  Future<List<YTVideo>> fetchPlaylistVideos(
    String playlistId, {
    int maxResults = 50,
    bool forceRefresh = false,
  }) async {
    final cached = _videosCache[playlistId];
    if (!forceRefresh && cached != null) return cached;
    final res = await _dio.get(
      '$_base/playlistItems',
      queryParameters: {
        'part': 'snippet',
        'playlistId': playlistId,
        'key': apiKey,
        'maxResults': maxResults,
        'fields':
            'items(snippet(title,description,thumbnails,resourceId/videoId))',
      },
    );
    final items = (res.data['items'] as List?) ?? [];
    final videos = items
        .map((e) => YTVideo.fromPlaylistItemJson(e as Map<String, dynamic>))
        .where((v) => v.videoId.isNotEmpty)
        .toList();
    _videosCache[playlistId] = videos;
    return videos;
  }
}
