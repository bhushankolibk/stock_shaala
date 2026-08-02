class BlogPost {
  final String id;
  final String title;
  final String url;
  final String published;
  final String summary;
  final String? thumbnailUrl;
  final List<String> labels;

  const BlogPost({
    required this.id,
    required this.title,
    required this.url,
    required this.published,
    required this.summary,
    this.thumbnailUrl,
    this.labels = const [],
  });

  factory BlogPost.fromJson(Map<String, dynamic> json) {
    final content = json['content'] as String? ?? '';
    final imgMatch = RegExp(
      r'src="(https://[^"]+\.(jpg|jpeg|png|webp)[^"]*)"',
      caseSensitive: false,
    ).firstMatch(content);
    final thumbnail = imgMatch?.group(1);
    final stripped = content
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final summary =
        stripped.length > 160 ? '${stripped.substring(0, 160)}…' : stripped;
    return BlogPost(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      url: json['url'] as String? ?? '',
      published: json['published'] as String? ?? '',
      summary: summary,
      thumbnailUrl: thumbnail,
      labels:
          (json['labels'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  String get formattedDate {
    try {
      final dt = DateTime.parse(published);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return '';
    }
  }
}
