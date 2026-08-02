import 'package:equatable/equatable.dart';

/// A single news article returned by Upstox's News API.
class StockNews extends Equatable {
  final String heading;
  final String summary;
  final String thumbnail;
  final String articleLink;
  final DateTime publishedTime;

  const StockNews({
    required this.heading,
    required this.summary,
    required this.thumbnail,
    required this.articleLink,
    required this.publishedTime,
  });

  factory StockNews.fromJson(Map<String, dynamic> json) {
    final publishedMs = (json['published_time'] as num?)?.toInt() ?? 0;
    return StockNews(
      heading: json['heading']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      thumbnail: json['thumbnail']?.toString() ?? '',
      articleLink: json['article_link']?.toString() ?? '',
      publishedTime: DateTime.fromMillisecondsSinceEpoch(publishedMs),
    );
  }

  @override
  List<Object?> get props => [heading, articleLink, publishedTime];
}
