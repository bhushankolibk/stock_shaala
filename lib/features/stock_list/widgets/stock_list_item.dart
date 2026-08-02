import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../data/models/equity_model.dart';
import '../../watchlist/widgets/watchlist_star_button.dart';

/// A single row in the "All Stocks" list — symbol, name, live last price
/// (or a loading placeholder), and day change % with an up/down arrow.
class StockListItem extends StatelessWidget {
  final Equity equity;
  final VoidCallback? onTap;

  const StockListItem({super.key, required this.equity, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
            TickerBadge(equity.tradingSymbol,
                TickerBadge.colorFor(equity.tradingSymbol)),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(equity.tradingSymbol,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                  Text(equity.name,
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.muted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            _priceColumn(),
            WatchlistStarButton(
              symbol: equity.tradingSymbol,
              name: equity.name,
              instrumentKey: equity.instrumentKey,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _priceColumn() {
    if (equity.lastPrice == null) {
      return _PricePlaceholder(loading: equity.priceLoading);
    }
    final up = equity.isUp;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(Fmt.money2(equity.lastPrice!), style: AppTheme.mono(size: 12)),
        Text(
          '${up ? '▲' : '▼'} ${Fmt.pct(equity.dayChangePercent ?? 0)}',
          style: AppTheme.mono(
              size: 10, color: up ? AppColors.up : AppColors.down),
        ),
      ],
    );
  }
}

/// Lightweight pulsing placeholder shown while a row's price hasn't
/// loaded yet (no shimmer package in this app — a plain fading box).
class _PricePlaceholder extends StatefulWidget {
  final bool loading;
  const _PricePlaceholder({required this.loading});

  @override
  State<_PricePlaceholder> createState() => _PricePlaceholderState();
}

class _PricePlaceholderState extends State<_PricePlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.3, end: 0.7).animate(_controller),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
              width: 52,
              height: 12,
              decoration: BoxDecoration(
                  color: AppColors.dim2,
                  borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 5),
          Container(
              width: 36,
              height: 10,
              decoration: BoxDecoration(
                  color: AppColors.dim2,
                  borderRadius: BorderRadius.circular(4))),
        ],
      ),
    );
  }
}
