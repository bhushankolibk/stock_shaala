import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../stock_list_controller.dart';
import 'stock_list_item.dart';

/// Search field sliver — kept separate from the results so callers can
/// place it wherever they like (e.g. above other sections) while still
/// sharing one CustomScrollView with the results list below.
List<Widget> buildStockListSearchSlivers({
  required StockListController controller,
  required TextEditingController searchController,
}) {
  return [
    SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        child: _SearchField(
          controller: searchController,
          onChanged: controller.onSearchChanged,
        ),
      ),
    ),
  ];
}

/// "All stocks" results slivers — a single CustomScrollView is required
/// (alongside whatever sliver contains [buildStockListSearchSlivers]) so
/// only visible rows get built, and thus only visible instrument keys get
/// queued for a live-price fetch.
List<Widget> buildStockListResultsSlivers({
  required StockListController controller,
}) {
  return [
    const SliverPadding(
      padding: EdgeInsets.fromLTRB(16, 18, 16, 10),
      sliver: SliverToBoxAdapter(
        child: Text('ALL STOCKS',
            style: TextStyle(fontSize: 11, color: AppColors.muted)),
      ),
    ),
    SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      sliver: AnimatedBuilder(
        animation: controller,
        builder: (_, __) {
          if (controller.loading) {
            return const SliverToBoxAdapter(child: _CenteredSpinner());
          }
          if (controller.error != null) {
            return SliverToBoxAdapter(
              child: _MessageState(
                emoji: '📡',
                title: 'Could not load stocks',
                subtitle: controller.error!,
                onRetry: controller.load,
              ),
            );
          }
          if (controller.filtered.isEmpty) {
            return const SliverToBoxAdapter(
              child: _MessageState(
                emoji: '🔍',
                title: 'No matches',
                subtitle: 'Try a different symbol or company name.',
              ),
            );
          }
          return SliverList.builder(
            itemCount: controller.filtered.length,
            itemBuilder: (context, i) {
              final equity = controller.filtered[i];
              controller.markVisible(equity);
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
      ),
    ),
  ];
}

/// Convenience combination of the two sliver groups above, in their
/// original (search directly above results) order.
List<Widget> buildStockListSlivers({
  required StockListController controller,
  required TextEditingController searchController,
}) {
  return [
    ...buildStockListSearchSlivers(
        controller: controller, searchController: searchController),
    ...buildStockListResultsSlivers(controller: controller),
  ];
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SearchField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 13, color: AppColors.text),
        decoration: const InputDecoration(
          hintText: 'Search by symbol or company name',
          hintStyle: TextStyle(fontSize: 12, color: AppColors.muted),
          prefixIcon: Icon(Icons.search, size: 18, color: AppColors.muted),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        ),
      ),
    );
  }
}

class _CenteredSpinner extends StatelessWidget {
  const _CenteredSpinner();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(40),
        child: Center(
            child: CircularProgressIndicator(
                color: AppColors.accent, strokeWidth: 2)),
      );
}

class _MessageState extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final VoidCallback? onRetry;

  const _MessageState({
    required this.emoji,
    required this.title,
    required this.subtitle,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 10),
            Text(title,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: AppColors.muted)),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: onRetry,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
    );
  }
}
