import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/stock_news_model.dart';

/// Card for a single news article — thumbnail, heading, summary, time ago.
class StockNewsCard extends StatelessWidget {
  final StockNews news;
  final VoidCallback onTap;

  const StockNewsCard({super.key, required this.news, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: news.thumbnail.isEmpty
                  ? _placeholder()
                  : Image.network(
                      news.thumbnail,
                      width: 84,
                      height: 84,
                      fit: BoxFit.cover,
                      loadingBuilder: (ctx, child, progress) =>
                          progress == null ? child : _placeholder(),
                      errorBuilder: (_, __, ___) => _placeholder(),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    news.heading,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.3),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    news.summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.muted, height: 1.4),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    Fmt.timeAgo(news.publishedTime),
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 84,
        height: 84,
        color: AppColors.dim,
        alignment: Alignment.center,
        child: const Text('📰', style: TextStyle(fontSize: 22)),
      );
}
