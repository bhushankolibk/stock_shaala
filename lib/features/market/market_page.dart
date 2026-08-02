import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/injection.dart';
import '../../core/services/market_api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/models/quote_model.dart';
import '../../core/constants/stock_universe.dart';

class MarketPage extends StatefulWidget {
  const MarketPage({super.key});

  @override
  State<MarketPage> createState() => _MarketPageState();
}

class _MarketPageState extends State<MarketPage> {
  List<Quote> _stocks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final stocks = await sl<MarketApiService>().fetchStockQuotes();
      if (mounted) {
        setState(() {
          _stocks = stocks;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, double> get _sectorAvg {
    final map = <String, List<double>>{};
    for (final q in _stocks) {
      final sector = StockUniverse.stocks
          .firstWhere((s) => s.symbol == q.symbol,
              orElse: () => (symbol: '', name: '', sector: 'Other'))
          .sector;
      map.putIfAbsent(sector, () => []).add(q.changePercent);
    }
    return map.map((k, v) =>
        MapEntry(k, v.reduce((a, b) => a + b) / v.length));
  }

  @override
  Widget build(BuildContext context) {
    final gainers = [..._stocks]
      ..sort((a, b) => b.changePercent.compareTo(a.changePercent));

    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.accent,
        backgroundColor: AppColors.card,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Market',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
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
                        style:
                            AppTheme.mono(size: 10, color: AppColors.accent)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_loading)
              const Center(
                  child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(
                          color: AppColors.accent, strokeWidth: 2)))
            else ...[
              const Text('SECTOR HEATMAP',
                  style: TextStyle(fontSize: 11, color: AppColors.muted)),
              const SizedBox(height: 10),
              _sectorGrid(),
              const SizedBox(height: 18),
              const Text('TOP GAINERS',
                  style: TextStyle(fontSize: 11, color: AppColors.muted)),
              const SizedBox(height: 10),
              ...gainers.take(6).map(_stockRow),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectorGrid() {
    final entries = _sectorAvg.entries.toList();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.6,
        crossAxisSpacing: 7,
        mainAxisSpacing: 7,
      ),
      itemCount: entries.length,
      itemBuilder: (_, i) {
        final e = entries[i];
        final up = e.value >= 0;
        return GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(e.key,
                  style:
                      const TextStyle(fontSize: 10, color: AppColors.muted)),
              const SizedBox(height: 4),
              Text('${up ? '▲' : '▼'} ${Fmt.pct(e.value)}',
                  style: AppTheme.mono(
                      size: 14,
                      weight: FontWeight.w700,
                      color: up ? AppColors.up : AppColors.down)),
            ],
          ),
        );
      },
    );
  }

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
            ],
          ),
        ),
      );
}
