import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/di/injection.dart';
import '../../core/services/blogger_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/native_ad_card.dart';
import '../../data/models/blog_post_model.dart';

/// One native ad after every this many articles.
const _adInterval = 6;

class ReadSection extends StatefulWidget {
  const ReadSection({super.key});

  @override
  State<ReadSection> createState() => _ReadSectionState();
}

class _ReadSectionState extends State<ReadSection>
    with AutomaticKeepAliveClientMixin {
  List<BlogPost> _posts = [];
  bool _loading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final posts = await sl<BloggerService>().fetchPosts();
      if (mounted)
        setState(() {
          _posts = posts;
          _loading = false;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _error = 'Could not load articles';
          _loading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(
              color: AppColors.accent, strokeWidth: 2));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, color: AppColors.muted, size: 32),
            const SizedBox(height: 10),
            Text(_error!,
                style: const TextStyle(color: AppColors.muted, fontSize: 13)),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () {
                setState(() {
                  _loading = true;
                  _error = null;
                });
                _load();
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.3)),
                ),
                child: const Text('Retry',
                    style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      );
    }
    if (_posts.isEmpty) {
      return const Center(
          child: Text('No articles yet',
              style: TextStyle(color: AppColors.muted)));
    }
    // One NativeAdCard slotted in after every _adInterval articles.
    final adSlots = (_posts.length - 1) ~/ _adInterval;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      itemCount: _posts.length + adSlots,
      itemBuilder: (_, i) {
        final adsBefore = (i + 1) ~/ (_adInterval + 1);
        final isAdSlot =
            (i + 1) % (_adInterval + 1) == 0 && adsBefore <= adSlots;
        if (isAdSlot) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: NativeAdCard(),
          );
        }
        return _postCard(_posts[i - adsBefore]);
      },
    );
  }

  Widget _postCard(BlogPost post) {
    return GestureDetector(
      onTap: () => _open(post.url),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (post.thumbnailUrl != null)
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(13)),
                child: Image.network(
                  post.thumbnailUrl!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (post.labels.isNotEmpty)
                    Wrap(
                      spacing: 5,
                      children: post.labels
                          .take(3)
                          .map((l) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.blue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                      color: AppColors.blue
                                          .withValues(alpha: 0.2)),
                                ),
                                child: Text(l,
                                    style: const TextStyle(
                                        fontSize: 9,
                                        color: AppColors.blue,
                                        fontWeight: FontWeight.w600)),
                              ))
                          .toList(),
                    ),
                  if (post.labels.isNotEmpty) const SizedBox(height: 8),
                  Text(post.title,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 1.4)),
                  const SizedBox(height: 6),
                  if (post.formattedDate.isNotEmpty)
                    Text(post.formattedDate,
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.muted)),
                  const SizedBox(height: 8),
                  Text(post.summary,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, height: 1.6, color: Color(0xFF8A9DC0))),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppColors.blue.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppColors.blue.withValues(alpha: 0.25)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Read Article',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.blue)),
                            SizedBox(width: 4),
                            Icon(Icons.open_in_new,
                                size: 12, color: AppColors.blue),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    }
  }
}
