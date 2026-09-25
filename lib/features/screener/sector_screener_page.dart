import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/stock_universe.dart';
import '../../core/di/injection.dart';
import '../../core/services/market_overview_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/banner_ad_widget.dart';
import '../../data/models/quote_model.dart';
import '../stock_list/stock_list_controller.dart';
import '../stock_list/widgets/stock_list_item.dart';
import '../watchlist/widgets/watchlist_star_button.dart';

/// Lets the user filter stocks by sector/theme (Banking, IT, Pharma, ...),
/// backed by a ~50-stock sector-tagged blue-chip pool
/// ([StockUniverse.sectorTags]) rather than just the 12-stock curated
/// list. The "All" chip instead searches the full ~2,400-stock NSE
/// universe (same data/lazy-price pattern as the "All Stocks" list page),
/// since sector tags aren't available for the full list.
class SectorScreenerPage extends StatefulWidget {
  const SectorScreenerPage({super.key});

  @override
  State<SectorScreenerPage> createState() => _SectorScreenerPageState();
}

class _SectorScreenerPageState extends State<SectorScreenerPage> {
  static const _all = 'All';

  late final List<String> _sectors;
  late final StockListController _allStocksController;
  final _searchController = TextEditingController();
  String _selected = _all;
  List<Quote> _quotes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _sectors = [
      _all,
      ...{for (final t in StockUniverse.sectorTags) t.sector},
    ];
    _allStocksController = StockListController()..load();
    _load();
  }

  @override
  void dispose() {
    _allStocksController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final quotes = await sl<MarketOverviewService>().fetchSectorPoolQuotes();
      if (mounted) setState(() => _quotes = quotes);
    } catch (_) {
      // Keep whatever we had; row list will just show cached/empty data.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _sectorFor(String symbol) {
    for (final t in StockUniverse.sectorTags) {
      if (t.symbol == symbol) return t.sector;
    }
    return null;
  }

  List<Quote> get _filtered =>
      _quotes.where((q) => _sectorFor(q.symbol) == _selected).toList();

  @override
  Widget build(BuildContext context) {
    final showAllUniverse = _selected == _all;
    return Scaffold(
      appBar: AppBar(title: const Text('Sector Screener')),
      bottomNavigationBar: const BannerAdWidget(),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _sectors.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => _sectorChip(_sectors[i]),
              ),
            ),
            if (showAllUniverse) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: _searchField(),
              ),
              Expanded(child: _allStocksList()),
            ] else
              Expanded(child: _sectorList()),
          ],
        ),
      ),
    );
  }

  Widget _searchField() => Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _allStocksController.onSearchChanged,
          style: const TextStyle(fontSize: 13, color: AppColors.text),
          decoration: const InputDecoration(
            hintText: 'Search the full NSE universe…',
            hintStyle: TextStyle(fontSize: 12, color: AppColors.muted),
            prefixIcon: Icon(Icons.search, size: 18, color: AppColors.muted),
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          ),
        ),
      );

  Widget _allStocksList() => AnimatedBuilder(
        animation: _allStocksController,
        builder: (_, __) {
          if (_allStocksController.loading) {
            return const Center(
                child: CircularProgressIndicator(
                    color: AppColors.accent, strokeWidth: 2));
          }
          if (_allStocksController.error != null) {
            return Center(
              child: Text(_allStocksController.error!,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            );
          }
          final results = _allStocksController.filtered;
          if (results.isEmpty) {
            return const Center(
                child: Text('No matches.',
                    style: TextStyle(fontSize: 12, color: AppColors.muted)));
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            itemCount: results.length,
            itemBuilder: (context, i) {
              final equity = results[i];
              _allStocksController.markVisible(equity);
              return StockListItem(
                equity: equity,
                onTap: () => context.push('/stock', extra: {
                  'symbol': equity.tradingSymbol,
                  'name': equity.name,
                }),
              );
            },
          );
        },
      );

  Widget _sectorList() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(
              color: AppColors.accent, strokeWidth: 2));
    }
    if (_filtered.isEmpty) {
      return const Center(
          child: Text('No stocks in this sector.',
              style: TextStyle(fontSize: 12, color: AppColors.muted)));
    }
    return RefreshIndicator(
      color: AppColors.accent,
      backgroundColor: AppColors.card,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: _filtered.map(_stockRow).toList(),
      ),
    );
  }

  Widget _sectorChip(String sector) {
    final selected = sector == _selected;
    return GestureDetector(
      onTap: () => setState(() => _selected = sector),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.15)
              : AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppColors.accent : AppColors.border),
        ),
        child: Text(sector,
            style: TextStyle(
                fontSize: 12,
                height: 1,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.accent : AppColors.muted)),
      ),
    );
  }

  Widget _stockRow(Quote q) => GestureDetector(
        onTap: () =>
            context.push('/stock', extra: {'symbol': q.symbol, 'name': q.name}),
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
                    Text(_sectorFor(q.symbol) ?? q.name,
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
}
