import 'package:flutter/material.dart';

import '../../core/constants/stock_universe.dart';
import '../../core/di/injection.dart';
import '../../core/services/equity_list_service.dart';
import '../../core/services/stock_quote_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/banner_ad_widget.dart';
import '../../data/models/equity_model.dart';
import '../../data/models/quote_model.dart';

/// Side-by-side comparison of any two stocks from the full NSE universe
/// (same bundled list as the "All Stocks" page): price, day change, day
/// range, 52-week range, and sector (shown when known — sector tags only
/// exist for the curated stock set, not the full universe).
class StockComparePage extends StatefulWidget {
  const StockComparePage({super.key});

  @override
  State<StockComparePage> createState() => _StockComparePageState();
}

class _StockComparePageState extends State<StockComparePage> {
  bool _loading = true;
  Equity? _equityA;
  Equity? _equityB;
  Quote? _quoteA;
  Quote? _quoteB;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final all = await sl<EquityListService>().loadAll();
    final a = all.firstWhere(
        (e) => e.tradingSymbol == StockUniverse.stocks[0].symbol,
        orElse: () => all[0]);
    final b = all.firstWhere(
        (e) => e.tradingSymbol == StockUniverse.stocks[1].symbol,
        orElse: () => all[1]);
    setState(() {
      _equityA = a;
      _equityB = b;
    });
    await _load();
  }

  Future<void> _load() async {
    final a = _equityA;
    final b = _equityB;
    if (a == null || b == null) return;
    setState(() => _loading = true);
    try {
      final quotes = await sl<StockQuoteService>()
          .fetchQuotes([a.instrumentKey, b.instrumentKey]);
      final qa = quotes[a.instrumentKey];
      final qb = quotes[b.instrumentKey];
      if (mounted) {
        setState(() {
          _quoteA = qa != null
              ? Quote.fromLiveQuote(a.tradingSymbol, a.name, qa,
                  instrumentKey: a.instrumentKey)
              : null;
          _quoteB = qb != null
              ? Quote.fromLiveQuote(b.tradingSymbol, b.name, qb,
                  instrumentKey: b.instrumentKey)
              : null;
        });
      }
    } catch (_) {
      // Leave whatever quotes we already have.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _sectorFor(String symbol) {
    for (final s in StockUniverse.stocks) {
      if (s.symbol == symbol) return s.sector;
    }
    return null;
  }

  Future<void> _pickEquity({required bool isA}) async {
    final all = await sl<EquityListService>().loadAll();
    if (!mounted) return;
    final chosen = await showModalBottomSheet<Equity>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => _EquityPickerSheet(all: all),
    );
    if (chosen == null) return;
    setState(() {
      if (isA) {
        _equityA = chosen;
      } else {
        _equityB = chosen;
      }
    });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final a = _quoteA;
    final b = _quoteB;
    return Scaffold(
      appBar: AppBar(title: const Text('Compare Stocks')),
      bottomNavigationBar: const BannerAdWidget(),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.accent,
          backgroundColor: AppColors.card,
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            children: [
              Row(
                children: [
                  Expanded(
                      child: _pickerCard(
                          _equityA, () => _pickEquity(isA: true))),
                  const SizedBox(width: 10),
                  const Text('VS',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.muted)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _pickerCard(
                          _equityB, () => _pickEquity(isA: false))),
                ],
              ),
              const SizedBox(height: 18),
              if (_loading)
                const Center(
                    child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(
                            color: AppColors.accent, strokeWidth: 2)))
              else
                GlassCard(
                  child: Column(
                    children: [
                      _metricRow(
                          'Sector',
                          _sectorFor(_equityA?.tradingSymbol ?? '') ?? '—',
                          _sectorFor(_equityB?.tradingSymbol ?? '') ?? '—'),
                      _divider(),
                      _metricRow(
                        'Price',
                        a != null ? Fmt.money(a.price) : '—',
                        b != null ? Fmt.money(b.price) : '—',
                      ),
                      _divider(),
                      _metricRow(
                        'Day Change',
                        a != null ? Fmt.pct(a.changePercent) : '—',
                        b != null ? Fmt.pct(b.changePercent) : '—',
                        colorA: a == null ? null : (a.isUp ? AppColors.up : AppColors.down),
                        colorB: b == null ? null : (b.isUp ? AppColors.up : AppColors.down),
                      ),
                      _divider(),
                      _metricRow(
                        'Day High',
                        a?.dayHigh != null ? Fmt.money(a!.dayHigh!) : '—',
                        b?.dayHigh != null ? Fmt.money(b!.dayHigh!) : '—',
                      ),
                      _divider(),
                      _metricRow(
                        'Day Low',
                        a?.dayLow != null ? Fmt.money(a!.dayLow!) : '—',
                        b?.dayLow != null ? Fmt.money(b!.dayLow!) : '—',
                      ),
                      _divider(),
                      _metricRow(
                        '52W High',
                        a?.week52High != null ? Fmt.money(a!.week52High!) : '—',
                        b?.week52High != null ? Fmt.money(b!.week52High!) : '—',
                      ),
                      _divider(),
                      _metricRow(
                        '52W Low',
                        a?.week52Low != null ? Fmt.money(a!.week52Low!) : '—',
                        b?.week52Low != null ? Fmt.money(b!.week52Low!) : '—',
                      ),
                      _divider(),
                      _metricRow(
                        'Volume',
                        a?.volume != null ? Fmt.compact(a!.volume!) : '—',
                        b?.volume != null ? Fmt.compact(b!.volume!) : '—',
                      ),
                      _divider(),
                      _metricRow(
                        'Upper Circuit',
                        a?.upperCircuitLimit != null
                            ? Fmt.money(a!.upperCircuitLimit!)
                            : '—',
                        b?.upperCircuitLimit != null
                            ? Fmt.money(b!.upperCircuitLimit!)
                            : '—',
                      ),
                      _divider(),
                      _metricRow(
                        'Lower Circuit',
                        a?.lowerCircuitLimit != null
                            ? Fmt.money(a!.lowerCircuitLimit!)
                            : '—',
                        b?.lowerCircuitLimit != null
                            ? Fmt.money(b!.lowerCircuitLimit!)
                            : '—',
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pickerCard(Equity? equity, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(equity?.tradingSymbol ?? 'Select',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700)),
                ),
                const Icon(Icons.unfold_more,
                    size: 14, color: AppColors.muted),
              ],
            ),
            const SizedBox(height: 2),
            Text(equity?.name ?? 'Tap to choose a stock',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: AppColors.muted)),
          ],
        ),
      ),
    );
  }

  Widget _divider() => const Divider(height: 18, color: AppColors.border);

  Widget _metricRow(String label, String valueA, String valueB,
      {Color? colorA, Color? colorB}) {
    return Row(
      children: [
        Expanded(
          child: Text(valueA,
              textAlign: TextAlign.left,
              style: AppTheme.mono(size: 12, color: colorA ?? AppColors.text)),
        ),
        SizedBox(
          width: 84,
          child: Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: AppColors.muted)),
        ),
        Expanded(
          child: Text(valueB,
              textAlign: TextAlign.right,
              style: AppTheme.mono(size: 12, color: colorB ?? AppColors.text)),
        ),
      ],
    );
  }
}

/// Search-as-you-type picker over the full ~2,400-stock NSE universe.
class _EquityPickerSheet extends StatefulWidget {
  final List<Equity> all;
  const _EquityPickerSheet({required this.all});

  @override
  State<_EquityPickerSheet> createState() => _EquityPickerSheetState();
}

class _EquityPickerSheetState extends State<_EquityPickerSheet> {
  late List<Equity> _results = widget.all;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      _results = q.isEmpty
          ? widget.all
          : widget.all
              .where((e) =>
                  e.tradingSymbol.toLowerCase().contains(q) ||
                  e.name.toLowerCase().contains(q))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.card2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  onChanged: _onSearchChanged,
                  style: const TextStyle(fontSize: 13, color: AppColors.text),
                  decoration: const InputDecoration(
                    hintText: 'Search by symbol or company name',
                    hintStyle: TextStyle(fontSize: 12, color: AppColors.muted),
                    prefixIcon:
                        Icon(Icons.search, size: 18, color: AppColors.muted),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                  ),
                ),
              ),
            ),
            Expanded(
              child: _results.isEmpty
                  ? const Center(
                      child: Text('No matches.',
                          style:
                              TextStyle(fontSize: 12, color: AppColors.muted)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: _results.length,
                      itemBuilder: (_, i) {
                        final e = _results[i];
                        return ListTile(
                          title: Text(e.tradingSymbol,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                          subtitle: Text(e.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.muted)),
                          onTap: () => Navigator.pop(context, e),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
