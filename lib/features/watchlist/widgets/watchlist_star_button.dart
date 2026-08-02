import 'package:flutter/material.dart';
import '../../../core/di/injection.dart';
import '../../../core/services/watchlist_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/watchlist_item_model.dart';

/// Tap-to-toggle star shown on any stock row/card so a stock can be
/// added to (or removed from) the watchlist from anywhere in the app.
class WatchlistStarButton extends StatelessWidget {
  final String symbol;
  final String name;
  final String instrumentKey;
  final double size;

  const WatchlistStarButton({
    super.key,
    required this.symbol,
    required this.name,
    required this.instrumentKey,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    if (instrumentKey.isEmpty) return const SizedBox.shrink();
    final service = sl<WatchlistService>();
    return AnimatedBuilder(
      animation: service,
      builder: (_, __) {
        final watched = service.isWatched(instrumentKey);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => service.toggle(WatchlistItem(
              symbol: symbol, name: name, instrumentKey: instrumentKey)),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(
              watched ? Icons.star_rounded : Icons.star_border_rounded,
              size: size,
              color: watched ? AppColors.accent : AppColors.muted,
            ),
          ),
        );
      },
    );
  }
}
