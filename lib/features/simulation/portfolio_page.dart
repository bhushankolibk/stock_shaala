import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/di/injection.dart';
import '../../core/services/ad_service.dart';
import '../../core/services/analytics_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/banner_ad_widget.dart';
import '../../data/models/quote_model.dart';
import '../../data/models/holding_model.dart';
import 'portfolio_repository.dart';

class PortfolioPage extends StatefulWidget {
  const PortfolioPage({super.key});

  @override
  State<PortfolioPage> createState() => _PortfolioPageState();
}

class _PortfolioPageState extends State<PortfolioPage> {
  PortfolioSnapshot? _snapshot;
  List<Quote> _quotes = [];
  bool _loading = true;
  bool _livePrices = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = sl<PortfolioRepository>();
    try {
      final quotes = await repo.refreshQuotes();
      final snap = await repo.snapshot(quotes);
      if (mounted) {
        setState(() {
          _quotes = quotes;
          _snapshot = snap;
          _livePrices = quotes.isNotEmpty;
          _loading = false;
        });
      }
    } catch (_) {
      // Even if quotes fail, show snapshot with avg prices.
      final snap = await repo.snapshot(const []);
      if (mounted) {
        setState(() {
          _snapshot = snap;
          _livePrices = false;
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.accent,
        backgroundColor: AppColors.card,
        onRefresh: _load,
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                    color: AppColors.accent, strokeWidth: 2))
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Virtual Trade',
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w700)),
                      Pill('${Fmt.money(_snapshot!.cash)} cash', AppColors.up),
                    ],
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _watchAdForCash,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.ondemand_video,
                              size: 16, color: AppColors.accent),
                          const SizedBox(width: 6),
                          Text(
                            'Watch ad for +${Fmt.money(AppConstants.rewardedCashTopUp)} cash',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.accent),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _portfolioHeader(),
                  if (_snapshot!.positions.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const Text('PERFORMANCE',
                        style:
                            TextStyle(fontSize: 11, color: AppColors.muted)),
                    const SizedBox(height: 8),
                    _performanceSection(),
                  ],
                  const SizedBox(height: 14),
                  const Text('HOLDINGS',
                      style:
                          TextStyle(fontSize: 11, color: AppColors.muted)),
                  const SizedBox(height: 8),
                  if (_snapshot!.positions.isEmpty)
                    _emptyState()
                  else
                    ..._snapshot!.positions.map(_holdingRow),
                  const SizedBox(height: 14),
                  const Text('EXPLORE & BUY',
                      style:
                          TextStyle(fontSize: 11, color: AppColors.muted)),
                  const SizedBox(height: 8),
                  ..._quotes.take(4).map(_buyRow),
                  const SizedBox(height: 16),
                  const Center(child: BannerAdWidget()),
                ],
              ),
      ),
    );
  }

  void _watchAdForCash() {
    final shown = sl<AdService>().showRewarded(
      onReward: () async {
        await sl<PortfolioRepository>()
            .addFunds(AppConstants.rewardedCashTopUp);
        await sl<AnalyticsService>().logAdRewardEarned('portfolio_add_cash');
        if (mounted) await _load();
      },
    );
    if (!shown && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No ad available right now')),
      );
    }
  }

  Widget _portfolioHeader() {
    final s = _snapshot!;
    return GlassCard(
      gradient: const LinearGradient(
          colors: [Color(0xFF112230), Color(0xFF0A1628)]),
      borderColor: AppColors.up.withValues(alpha: 0.15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('PORTFOLIO VALUE',
                  style: TextStyle(fontSize: 10, color: AppColors.muted)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: (_livePrices ? AppColors.up : AppColors.muted)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _livePrices ? 'LIVE' : 'EST',
                  style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: _livePrices ? AppColors.up : AppColors.muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(Fmt.money(s.totalValue),
              style: AppTheme.mono(size: 26, weight: FontWeight.w700)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
                child: _metric('TOTAL P&L', Fmt.signedMoney(s.totalPnl),
                    s.totalPnl >= 0)),
            const SizedBox(width: 6),
            Expanded(
                child: _metric('RETURN', Fmt.pct(s.totalPnlPercent),
                    s.totalPnl >= 0)),
            const SizedBox(width: 6),
            Expanded(
                child: _metric('TRADES', '${s.tradeCount}', true,
                    neutral: true)),
          ]),
        ],
      ),
    );
  }

  Widget _metric(String label, String value, bool up, {bool neutral = false}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10)),
        child: Column(
          children: [
            Text(label,
                style: const TextStyle(fontSize: 9, color: AppColors.muted)),
            const SizedBox(height: 3),
            Text(value,
                style: AppTheme.mono(
                    size: 11,
                    weight: FontWeight.w700,
                    color: neutral
                        ? AppColors.text
                        : up
                            ? AppColors.up
                            : AppColors.down)),
          ],
        ),
      );

  static const _pieColors = [
    AppColors.accent,
    AppColors.blue,
    AppColors.up,
    AppColors.purple,
    AppColors.down,
  ];

  Widget _performanceSection() {
    final positions = _snapshot!.positions;
    final totalHoldingsValue = positions.fold<double>(
        0, (sum, p) => sum + p.holding.currentValue(p.ltp));

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ALLOCATION',
              style: TextStyle(fontSize: 9, color: AppColors.muted)),
          const SizedBox(height: 10),
          Row(
            children: [
              SizedBox(
                width: 96,
                height: 96,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 26,
                    sections: [
                      for (var i = 0; i < positions.length; i++)
                        PieChartSectionData(
                          value: totalHoldingsValue == 0
                              ? 1
                              : positions[i]
                                  .holding
                                  .currentValue(positions[i].ltp),
                          color: _pieColors[i % _pieColors.length],
                          radius: 22,
                          showTitle: false,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < positions.length; i++)
                      _allocationLegendRow(
                        positions[i].holding.symbol,
                        totalHoldingsValue == 0
                            ? 0
                            : positions[i].holding.currentValue(positions[i].ltp) /
                                totalHoldingsValue *
                                100,
                        _pieColors[i % _pieColors.length],
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('P&L BY HOLDING',
              style: TextStyle(fontSize: 9, color: AppColors.muted)),
          const SizedBox(height: 10),
          for (final p in positions) _pnlBarRow(p),
        ],
      ),
    );
  }

  Widget _allocationLegendRow(String symbol, double pct, Color color) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(symbol,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600)),
            ),
            Text('${pct.toStringAsFixed(0)}%',
                style: AppTheme.mono(size: 11, color: AppColors.muted)),
          ],
        ),
      );

  Widget _pnlBarRow(({Holding holding, double ltp}) pos) {
    final h = pos.holding;
    final pnlPct = h.pnlPercent(pos.ltp);
    final up = pnlPct >= 0;
    final fraction = (pnlPct.abs() / 20).clamp(0.0, 1.0); // 20% = full bar
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(h.symbol,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                children: [
                  Container(height: 8, color: AppColors.dim),
                  FractionallySizedBox(
                    widthFactor: fraction,
                    child: Container(
                      height: 8,
                      color: up ? AppColors.up : AppColors.down,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 56,
            child: Text(Fmt.pct(pnlPct),
                textAlign: TextAlign.right,
                style: AppTheme.mono(
                    size: 11, color: up ? AppColors.up : AppColors.down)),
          ),
        ],
      ),
    );
  }

  Widget _holdingRow(({Holding holding, double ltp}) pos) {
    final h = pos.holding;
    final ltp = pos.ltp;
    final up = h.pnl(ltp) >= 0;
    return GestureDetector(
      onTap: () => context.push('/stock',
          extra: {'symbol': h.symbol, 'name': h.name}).then((_) => _load()),
      child: Container(
        margin: const EdgeInsets.only(bottom: 7),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            TickerBadge(h.symbol, TickerBadge.colorFor(h.symbol)),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(h.symbol,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700)),
                  Text('${h.quantity} shares · avg ${Fmt.money(h.avgBuyPrice)}',
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.muted)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(Fmt.money(h.currentValue(ltp)),
                    style: AppTheme.mono(size: 12)),
                Text('${up ? '▲' : '▼'} ${Fmt.pct(h.pnlPercent(ltp))}',
                    style: AppTheme.mono(
                        size: 10,
                        color: up ? AppColors.up : AppColors.down)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buyRow(Quote q) => Container(
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
            Text(Fmt.money(q.price), style: AppTheme.mono(size: 12)),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => context.push('/stock',
                  extra: {'symbol': q.symbol, 'name': q.name}).then((_) => _load()),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.up.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(7),
                  border:
                      Border.all(color: AppColors.up.withValues(alpha: 0.25)),
                ),
                child: const Text('TRADE',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.up)),
              ),
            ),
          ],
        ),
      );

  Widget _emptyState() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: const Column(
          children: [
            Text('📭', style: TextStyle(fontSize: 28)),
            SizedBox(height: 8),
            Text('No holdings yet',
                style:
                    TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            SizedBox(height: 4),
            Text('Tap TRADE on any stock to start practising.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppColors.muted)),
          ],
        ),
      );
}
