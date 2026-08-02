class YTPlaylist {
  final String id;
  final String title;
  final String description;
  final String? thumbnailUrl;
  final int videoCount;

  const YTPlaylist({
    required this.id,
    required this.title,
    required this.description,
    this.thumbnailUrl,
    required this.videoCount,
  });

  factory YTPlaylist.fromJson(Map<String, dynamic> json) {
    final snippet = json['snippet'] as Map<String, dynamic>? ?? {};
    final contentDetails =
        json['contentDetails'] as Map<String, dynamic>? ?? {};
    final thumbnails = snippet['thumbnails'] as Map<String, dynamic>? ?? {};
    final high = thumbnails['high'] as Map<String, dynamic>?;
    final medium = thumbnails['medium'] as Map<String, dynamic>?;
    return YTPlaylist(
      id: json['id'] as String? ?? '',
      title: snippet['title'] as String? ?? '',
      description: snippet['description'] as String? ?? '',
      thumbnailUrl: (high ?? medium)?['url'] as String?,
      videoCount: (contentDetails['itemCount'] as int?) ?? 0,
    );
  }
}

class YTVideo {
  final String videoId;
  final String title;
  final String? thumbnailUrl;
  final String description;

  const YTVideo({
    required this.videoId,
    required this.title,
    this.thumbnailUrl,
    required this.description,
  });

  String get youtubeUrl => 'https://youtu.be/$videoId';

  factory YTVideo.fromPlaylistItemJson(Map<String, dynamic> json) {
    final snippet = json['snippet'] as Map<String, dynamic>? ?? {};
    final resourceId = snippet['resourceId'] as Map<String, dynamic>? ?? {};
    final thumbnails = snippet['thumbnails'] as Map<String, dynamic>? ?? {};
    final high = thumbnails['high'] as Map<String, dynamic>?;
    final medium = thumbnails['medium'] as Map<String, dynamic>?;
    return YTVideo(
      videoId: resourceId['videoId'] as String? ?? '',
      title: snippet['title'] as String? ?? '',
      thumbnailUrl: (high ?? medium)?['url'] as String?,
      description: snippet['description'] as String? ?? '',
    );
  }
}
