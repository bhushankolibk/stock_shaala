import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/di/injection.dart';
import '../../../core/services/stock_news_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/native_ad_card.dart';
import '../../../data/models/stock_news_model.dart';
import 'stock_news_card.dart';

/// One native ad after every this many articles.
const _adInterval = 6;

/// Embeddable news list — used both standalone (StockNewsPage) and inside
/// the Market tab's "News" sub-tab.
class StockNewsView extends StatefulWidget {
  final List<String> instrumentKeys;

  const StockNewsView({super.key, required this.instrumentKeys});

  @override
  State<StockNewsView> createState() => _StockNewsViewState();
}

class _StockNewsViewState extends State<StockNewsView>
    with AutomaticKeepAliveClientMixin<StockNewsView> {
  List<StockNews> _news = [];
  bool _loading = true;
  String? _error;

  // Keeps this widget's state alive when it's an offscreen TabBarView page,
  // so switching tabs doesn't dispose it and re-trigger a fetch.
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant StockNewsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.instrumentKeys != widget.instrumentKeys) _load();
  }

  Future<void> _load({bool forceRefresh = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final byKey = await sl<StockNewsService>()
          .fetchNews(widget.instrumentKeys, forceRefresh: forceRefresh);
      final seenLinks = <String>{};
      final flattened = byKey.values
          .expand((list) => list)
          .where((n) => seenLinks.add(n.articleLink))
          .toList()
        ..sort((a, b) => b.publishedTime.compareTo(a.publishedTime));
      if (kDebugMode) {
        debugPrint('[StockNewsView] loaded ${flattened.length} article(s) '
            'across ${byKey.length} instrument key(s).');
      }
      if (mounted) {
        setState(() {
          _news = flattened;
          _loading = false;
        });
      }
    } on StockNewsException catch (e) {
      if (kDebugMode) debugPrint('[StockNewsView] error: ${e.message}');
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[StockNewsView] unexpected error: $e');
      if (mounted) {
        setState(() {
          _error = 'Could not load news right now.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _openArticle(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // required by AutomaticKeepAliveClientMixin
    return RefreshIndicator(
      color: AppColors.accent,
      backgroundColor: AppColors.card,
      onRefresh: () => _load(forceRefresh: true),
      child: _body(),
    );
  }

  Widget _body() {
    if (widget.instrumentKeys.isEmpty) {
      return _messageState(
        emoji: '📰',
        title: 'No stock selected',
        subtitle: 'Pick a stock to see its latest news.',
      );
    }
    if (_loading) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          Center(
              child: CircularProgressIndicator(
                  color: AppColors.accent, strokeWidth: 2)),
        ],
      );
    }
    if (_error != null) {
      return _messageState(
        emoji: '📡',
        title: 'Could not load news',
        subtitle: _error!,
        showRetry: true,
      );
    }
    if (_news.isEmpty) {
      return _messageState(
        emoji: '📰',
        title: 'No recent news',
        subtitle: 'There is no news for this stock in the last 7 days.',
      );
    }
    // One NativeAdCard slotted in after every _adInterval articles.
    final adSlots = (_news.length - 1) ~/ _adInterval;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      itemCount: _news.length + adSlots,
      itemBuilder: (_, i) {
        final adsBefore = (i + 1) ~/ (_adInterval + 1);
        final isAdSlot =
            (i + 1) % (_adInterval + 1) == 0 && adsBefore <= adSlots;
        if (isAdSlot) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: NativeAdCard(),
          );
        }
        final newsIndex = i - adsBefore;
        return StockNewsCard(
          news: _news[newsIndex],
          onTap: () => _openArticle(_news[newsIndex].articleLink),
        );
      },
    );
  }

  Widget _messageState({
    required String emoji,
    required String title,
    required String subtitle,
    bool showRetry = false,
  }) {
    return ListView(
      children: [
        const SizedBox(height: 80),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 32)),
                const SizedBox(height: 12),
                Text(title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
                if (showRetry) ...[
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () => _load(forceRefresh: true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.3)),
                      ),
                      child: const Text('Retry',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
