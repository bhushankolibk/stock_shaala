import 'package:dio/dio.dart';
import '../../data/models/blog_post_model.dart';

class BloggerService {
  final Dio _dio;
  final String blogId;
  final String apiKey;

  BloggerService({required this.blogId, required this.apiKey, Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 12),
              receiveTimeout: const Duration(seconds: 12),
            ));

  static const _base = 'https://www.googleapis.com/blogger/v3';

  Future<List<BlogPost>> fetchPosts({int maxResults = 20}) async {
    final res = await _dio.get(
      '$_base/blogs/$blogId/posts',
      queryParameters: {
        'key': apiKey,
        'maxResults': maxResults,
        'orderBy': 'published',
        'fields': 'items(id,title,url,published,content,labels)',
      },
    );
    final items = (res.data['items'] as List?) ?? [];
    return items
        .map((e) => BlogPost.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
