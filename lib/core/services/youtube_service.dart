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

  Future<List<YTPlaylist>> fetchPlaylists() async {
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
    return items
        .map((e) => YTPlaylist.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<YTVideo>> fetchPlaylistVideos(String playlistId,
      {int maxResults = 50}) async {
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
    return items
        .map((e) => YTVideo.fromPlaylistItemJson(e as Map<String, dynamic>))
        .where((v) => v.videoId.isNotEmpty)
        .toList();
  }
}
