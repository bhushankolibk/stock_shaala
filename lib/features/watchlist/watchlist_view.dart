import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/injection.dart';
import '../../core/services/stock_quote_service.dart';
import '../../core/services/watchlist_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/models/live_quote_model.dart';
import '../../data/models/watchlist_item_model.dart';
import 'widgets/watchlist_star_button.dart';

/// The Watchlist tab — which stocks are saved is entirely local
/// (WatchlistService/SharedPreferences); live prices for the saved
/// stocks are still fetched from Upstox so the numbers stay current.
class WatchlistView extends StatefulWidget {
  const WatchlistView({super.key});

  @override
  State<WatchlistView> createState() => _WatchlistViewState();
}

class _WatchlistViewState extends State<WatchlistView>
    with AutomaticKeepAliveClientMixin<WatchlistView> {
  final _watchlist = sl<WatchlistService>();
  Map<String, LiveQuote> _quotes = {};
  bool _loadingPrices = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _watchlist.addListener(_onWatchlistChanged);
    _refreshPrices();
  }

  @override
  void dispose() {
    _watchlist.removeListener(_onWatchlistChanged);
    super.dispose();
  }

  void _onWatchlistChanged() {
    if (mounted) setState(() {});
    _refreshPrices();
  }

  Future<void> _refreshPrices() async {
    final keys = _watchlist.items.map((i) => i.instrumentKey).toList();
    if (keys.isEmpty) {
      if (mounted) setState(() => _quotes = {});
      return;
    }
    if (mounted) setState(() => _loadingPrices = true);
    try {
      final quotes = await sl<StockQuoteService>().fetchQuotes(keys);
      if (mounted) setState(() => _quotes = quotes);
    } catch (e) {
      if (kDebugMode) debugPrint('[WatchlistView] price fetch failed: $e');
    } finally {
      if (mounted) setState(() => _loadingPrices = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final items = _watchlist.items;

    return RefreshIndicator(
      color: AppColors.accent,
      backgroundColor: AppColors.card,
      onRefresh: _refreshPrices,
      child: items.isEmpty
          ? _emptyState()
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              itemCount: items.length,
              itemBuilder: (_, i) => _watchlistRow(items[i]),
            ),
    );
  }

  Widget _watchlistRow(WatchlistItem item) {
    final q = _quotes[item.instrumentKey];
    final up = (q?.change ?? 0) >= 0;
    return GestureDetector(
      onTap: () => context
          .push('/stock', extra: {'symbol': item.symbol, 'name': item.name}),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            TickerBadge(item.symbol, TickerBadge.colorFor(item.symbol)),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.symbol,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                  Text(item.name,
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.muted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (q == null)
              _loadingPrices
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          color: AppColors.accent, strokeWidth: 2))
                  : const Text('—',
                      style: TextStyle(fontSize: 12, color: AppColors.muted))
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(Fmt.money2(q.lastPrice), style: AppTheme.mono(size: 12)),
                  Text(
                      '${up ? '▲' : '▼'} ${Fmt.pct(q.changePercent)}',
                      style: AppTheme.mono(
                          size: 10,
                          color: up ? AppColors.up : AppColors.down)),
                ],
              ),
            const SizedBox(width: 6),
            WatchlistStarButton(
              symbol: item.symbol,
              name: item.name,
              instrumentKey: item.instrumentKey,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() => ListView(
        children: const [
          SizedBox(height: 80),
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('⭐', style: TextStyle(fontSize: 32)),
                  SizedBox(height: 12),
                  Text('Your watchlist is empty',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  SizedBox(height: 4),
                  Text(
                    'Tap the ★ on any stock to save it here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: AppColors.muted),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
}
