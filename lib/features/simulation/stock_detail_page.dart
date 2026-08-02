import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/stock_universe.dart';
import '../../core/di/injection.dart';
import '../../core/services/ad_service.dart';
import '../../core/services/equity_list_service.dart';
import '../../core/services/market_api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/banner_ad_widget.dart';
import '../../data/models/quote_model.dart';
import '../watchlist/widgets/watchlist_star_button.dart';
import 'portfolio_repository.dart';

class StockDetailPage extends StatefulWidget {
  final String symbol;
  final String name;
  const StockDetailPage({super.key, required this.symbol, required this.name});

  @override
  State<StockDetailPage> createState() => _StockDetailPageState();
}

class _StockDetailPageState extends State<StockDetailPage> {
  Quote? _quote;
  List<double> _history = [];
  bool _loading = true;
  String _range = '1mo';
  String? _instrumentKey;

  @override
  void initState() {
    super.initState();
    _load();
    _resolveInstrumentKey();
  }

  Future<void> _load() async {
    final api = sl<MarketApiService>();
    final ySym = StockUniverse.yahooSymbol(widget.symbol);
    try {
      final quote = await api.fetchQuote(ySym, widget.name);
      final history = await api.fetchHistory(ySym, range: _range);
      if (mounted) {
        setState(() {
          _quote = quote;
          _history = history;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Curated stocks resolve instantly; anything found via the full search
  /// screen is looked up from the cached equity list instead.
  Future<void> _resolveInstrumentKey() async {
    final curated = StockUniverse.instrumentKeyFor(widget.symbol);
    if (curated != null) {
      if (mounted) setState(() => _instrumentKey = curated);
      return;
    }
    try {
      final all = await sl<EquityListService>().loadAll();
      final match = all.where((e) => e.tradingSymbol == widget.symbol);
      if (mounted && match.isNotEmpty) {
        setState(() => _instrumentKey = match.first.instrumentKey);
      }
    } catch (_) {
      // News/watchlist actions just stay hidden if this fails.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.symbol,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700)),
            Text(widget.name,
                style:
                    const TextStyle(fontSize: 11, color: AppColors.muted)),
          ],
        ),
        actions: [
          if (_instrumentKey != null)
            Center(
              child: WatchlistStarButton(
                symbol: widget.symbol,
                name: widget.name,
                instrumentKey: _instrumentKey!,
                size: 20,
              ),
            ),
          if (_instrumentKey != null)
            IconButton(
              icon: const Icon(Icons.article_outlined),
              tooltip: 'News',
              onPressed: _openNews,
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppColors.accent, strokeWidth: 2))
          : _quote == null
              ? _errorState()
              : SafeArea(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                    children: [
                      _priceHeader(),
                      const SizedBox(height: 14),
                      _chart(),
                      const SizedBox(height: 14),
                      _educationalNote(),
                      const SizedBox(height: 14),
                      const Center(child: BannerAdWidget()),
                      const SizedBox(height: 14),
                      _tradeButtons(),
                    ],
                  ),
                ),
    );
  }

  void _openNews() {
    if (_instrumentKey == null) return;
    context.push('/news', extra: {
      'instrumentKeys': [_instrumentKey!],
      'title': '${widget.symbol} News',
    });
  }

  Widget _priceHeader() {
    final q = _quote!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(Fmt.money2(q.price),
                  style: AppTheme.mono(size: 24, weight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(
                  '${q.isUp ? '▲' : '▼'} ${Fmt.signedMoney(q.change)} (${Fmt.pct(q.changePercent)})',
                  style: AppTheme.mono(
                      size: 11,
                      color: q.isUp ? AppColors.up : AppColors.down)),
            ],
          ),
          if (q.week52High != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('52W High',
                    style:
                        TextStyle(fontSize: 10, color: AppColors.muted)),
                Text(Fmt.money(q.week52High!),
                    style: AppTheme.mono(size: 11)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _chart() {
    if (_history.length < 2) {
      return const SizedBox(
        height: 120,
        child: Center(
            child: Text('Chart data unavailable',
                style: TextStyle(fontSize: 11, color: AppColors.muted))),
      );
    }
    final spots = [
      for (var i = 0; i < _history.length; i++)
        FlSpot(i.toDouble(), _history[i])
    ];
    final up = _history.last >= _history.first;
    final color = up ? AppColors.up : AppColors.down;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 130,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: color,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withValues(alpha: 0.12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final r in const ['5d', '1mo', '3mo', '6mo', '1y'])
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _range = r);
                      _load();
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      decoration: BoxDecoration(
                        color: _range == r
                            ? AppColors.accent.withValues(alpha: 0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(r.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _range == r
                                  ? AppColors.accent
                                  : AppColors.muted)),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _educationalNote() => Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: AppColors.blue.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.blue.withValues(alpha: 0.2)),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📖', style: TextStyle(fontSize: 14)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Prices shown are delayed and for educational simulation only. '
                'This is not buy/sell advice.',
                style: TextStyle(
                    fontSize: 11, height: 1.5, color: AppColors.muted),
              ),
            ),
          ],
        ),
      );

  Widget _tradeButtons() => Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _showTradeSheet(isBuy: true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF00C896), Color(0xFF00A878)]),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Text('BUY (Virtual)',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.black)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => _showTradeSheet(isBuy: false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: AppColors.down.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(13),
                  border:
                      Border.all(color: AppColors.down.withValues(alpha: 0.25)),
                ),
                child: const Text('SELL',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.down)),
              ),
            ),
          ),
        ],
      );

  void _showTradeSheet({required bool isBuy}) {
    int qty = 1;
    final price = _quote!.price;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card2,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.dim2,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text('${isBuy ? 'Buy' : 'Sell'} ${widget.symbol} (Virtual)',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Price: ${Fmt.money2(price)}',
                  style: AppTheme.mono(size: 12, color: AppColors.muted)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Quantity',
                      style: TextStyle(fontSize: 13)),
                  Row(
                    children: [
                      _qtyBtn(Icons.remove, () {
                        if (qty > 1) setSheet(() => qty--);
                      }),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('$qty',
                            style: AppTheme.mono(
                                size: 18, weight: FontWeight.w700)),
                      ),
                      _qtyBtn(Icons.add, () => setSheet(() => qty++)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: AppColors.dim,
                    borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total',
                        style:
                            TextStyle(fontSize: 13, color: AppColors.muted)),
                    Text(Fmt.money2(price * qty),
                        style: AppTheme.mono(
                            size: 16, weight: FontWeight.w700)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => _confirmTrade(ctx, isBuy, qty, price),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: isBuy ? AppColors.up : AppColors.down,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                      'Confirm ${isBuy ? 'Buy' : 'Sell'} (Virtual)',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.black)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: AppColors.dim,
              borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, size: 18, color: AppColors.text),
        ),
      );

  void _confirmTrade(
      BuildContext sheetCtx, bool isBuy, int qty, double price) {
    final shown = sl<AdService>().showRewarded(
      onReward: () {},
      onAdClosed: () => _executeTrade(sheetCtx, isBuy, qty, price),
    );
    if (!shown) {
      _executeTrade(sheetCtx, isBuy, qty, price);
    }
  }

  Future<void> _executeTrade(
      BuildContext sheetCtx, bool isBuy, int qty, double price) async {
    final repo = sl<PortfolioRepository>();
    final result = isBuy
        ? await repo.buy(
            symbol: widget.symbol,
            name: widget.name,
            quantity: qty,
            price: price)
        : await repo.sell(
            symbol: widget.symbol,
            name: widget.name,
            quantity: qty,
            price: price);

    if (!sheetCtx.mounted) return;
    Navigator.pop(sheetCtx);

    result.match(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(failure.message),
              backgroundColor: AppColors.down),
        );
      },
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${isBuy ? 'Bought' : 'Sold'} $qty ${widget.symbol} (virtual)'),
            backgroundColor: AppColors.up,
          ),
        );
      },
    );
  }

  Widget _errorState() => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('📡', style: TextStyle(fontSize: 32)),
              SizedBox(height: 12),
              Text('Could not load this stock',
                  style:
                      TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              SizedBox(height: 4),
              Text('Check your connection and try again.',
                  style: TextStyle(fontSize: 11, color: AppColors.muted)),
            ],
          ),
        ),
      );
}
