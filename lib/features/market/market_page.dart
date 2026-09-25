import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/injection.dart';
import '../../core/services/market_overview_service.dart';
import '../../core/services/watchlist_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/banner_ad_widget.dart';
import '../../data/models/quote_model.dart';
import '../../core/constants/stock_universe.dart';
import '../news/widgets/stock_news_view.dart';
import '../watchlist/watchlist_view.dart';
import '../watchlist/widgets/watchlist_star_button.dart';

class MarketPage extends StatefulWidget {
  const MarketPage({super.key});

  @override
  State<MarketPage> createState() => _MarketPageState();
}

class _MarketPageState extends State<MarketPage>
    with SingleTickerProviderStateMixin {
  List<Quote> _stocks = [];
  List<Quote> _gainers = [];
  bool _loading = true;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final overview = sl<MarketOverviewService>();
    try {
      final results = await Future.wait([
        overview.fetchStockQuotes(),
        overview.fetchTopGainers(),
      ]);
      if (mounted) {
        setState(() {
          _stocks = results[0];
          _gainers = results[1];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Market',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                Row(
                  children: [
                    _headerIconButton(
                      icon: Icons.compare_arrows,
                      onTap: () => context.push('/compare'),
                    ),
                    const SizedBox(width: 8),
                    _headerIconButton(
                      icon: Icons.filter_alt_outlined,
                      onTap: () => context.push('/screener'),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _load,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                              color: AppColors.accent.withValues(alpha: 0.2)),
                        ),
                        child: Text('↻ Refresh',
                            style: AppTheme.mono(
                                size: 10, color: AppColors.accent)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          TabBar(
            controller: _tabController,
            labelColor: AppColors.accent,
            unselectedLabelColor: AppColors.muted,
            indicatorColor: AppColors.accent,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            unselectedLabelStyle:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            tabs: const [
              Tab(text: 'Explore'),
              Tab(text: 'News'),
              Tab(text: 'Watchlist'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _exploreTab(),
                const _NewsTab(),
                const WatchlistView(),
              ],
            ),
          ),
          const BannerAdWidget(),
        ],
      ),
    );
  }

  Widget _exploreTab() {
    return RefreshIndicator(
      color: AppColors.accent,
      backgroundColor: AppColors.card,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          _searchBarButton(),
          const SizedBox(height: 18),
          if (_loading)
            const Center(
                child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(
                        color: AppColors.accent, strokeWidth: 2)))
          else ...[
            const Text('TOP GAINERS',
                style: TextStyle(fontSize: 11, color: AppColors.muted)),
            const SizedBox(height: 10),
            _topGainersRow(_gainers),
            const SizedBox(height: 18),
            const Text('TOP STOCKS',
                style: TextStyle(fontSize: 11, color: AppColors.muted)),
            const SizedBox(height: 10),
            ..._stocks.map(_stockRow),
          ],
        ],
      ),
    );
  }

  Widget _searchBarButton() => GestureDetector(
        onTap: () => context.push('/stock-list'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: const Row(
            children: [
              Icon(Icons.search, size: 18, color: AppColors.muted),
              SizedBox(width: 8),
              Text('Search any stock…',
                  style: TextStyle(fontSize: 12, color: AppColors.muted)),
            ],
          ),
        ),
      );

  Widget _topGainersRow(List<Quote> gainers) {
    if (gainers.isEmpty) {
      return const Text('No data available.',
          style: TextStyle(fontSize: 11, color: AppColors.muted));
    }
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: gainers.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => _gainerCard(gainers[i]),
      ),
    );
  }

  Widget _gainerCard(Quote q) => GestureDetector(
        onTap: () => context
            .push('/stock', extra: {'symbol': q.symbol, 'name': q.name}),
        child: Container(
          width: 118,
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TickerBadge(q.symbol, TickerBadge.colorFor(q.symbol)),
                  WatchlistStarButton(
                    symbol: q.symbol,
                    name: q.name,
                    instrumentKey: q.instrumentKey ?? '',
                    size: 15,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(q.symbol,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(Fmt.money(q.price), style: AppTheme.mono(size: 11)),
              Text('${q.isUp ? '▲' : '▼'} ${Fmt.pct(q.changePercent)}',
                  style: AppTheme.mono(
                      size: 10, color: q.isUp ? AppColors.up : AppColors.down)),
            ],
          ),
        ),
      );

  Widget _stockRow(Quote q) => GestureDetector(
        onTap: () => context.push('/stock',
            extra: {'symbol': q.symbol, 'name': q.name}),
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
              TickerBadge(q.symbol, TickerBadge.colorFor(q.symbol)),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(q.symbol,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                    Text(q.name,
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.muted),
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(Fmt.money(q.price), style: AppTheme.mono(size: 12)),
                  Text('${q.isUp ? '▲' : '▼'} ${Fmt.pct(q.changePercent)}',
                      style: AppTheme.mono(
                          size: 10,
                          color: q.isUp ? AppColors.up : AppColors.down)),
                ],
              ),
              const SizedBox(width: 6),
              WatchlistStarButton(
                symbol: q.symbol,
                name: q.name,
                instrumentKey: q.instrumentKey ?? '',
                size: 18,
              ),
            ],
          ),
        ),
      );

  Widget _headerIconButton(
          {required IconData icon, required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, size: 15, color: AppColors.muted),
        ),
      );
}

/// News sub-tab with an "All Stocks" / "My Watchlist" toggle, so the feed
/// can be personalized to symbols the user actually cares about.
class _NewsTab extends StatefulWidget {
  const _NewsTab();

  @override
  State<_NewsTab> createState() => _NewsTabState();
}

class _NewsTabState extends State<_NewsTab> {
  bool _watchlistOnly = false;

  @override
  Widget build(BuildContext context) {
    final watchlist = sl<WatchlistService>().items;
    final watchlistKeys = watchlist.map((i) => i.instrumentKey).toList();
    final universeKeys =
        StockUniverse.stocks.map((s) => s.instrumentKey).toList();
    final showWatchlist = _watchlistOnly && watchlistKeys.isNotEmpty;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: _toggleChip('All Stocks', !_watchlistOnly,
                    () => setState(() => _watchlistOnly = false)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _toggleChip('My Watchlist', _watchlistOnly,
                    () => setState(() => _watchlistOnly = true)),
              ),
            ],
          ),
        ),
        if (_watchlistOnly && watchlistKeys.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Text(
              'Your watchlist is empty — star a stock to personalize this feed.',
              style: TextStyle(fontSize: 11, color: AppColors.muted),
            ),
          ),
        Expanded(
          child: StockNewsView(
            instrumentKeys: showWatchlist ? watchlistKeys : universeKeys,
          ),
        ),
      ],
    );
  }

  Widget _toggleChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.15)
              : AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppColors.accent : AppColors.border),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.accent : AppColors.muted)),
      ),
    );
  }
}
