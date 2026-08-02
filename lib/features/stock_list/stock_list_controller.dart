import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../core/di/injection.dart';
import '../../core/services/equity_list_service.dart';
import '../../core/services/stock_quote_service.dart';
import '../../data/models/equity_model.dart';

/// Drives the "All Stocks" list: loads the bundled equity list once,
/// filters it locally on search, and fetches live prices only for rows
/// that actually get built (i.e. are visible / about to be visible),
/// batching short bursts of scroll-triggered requests together.
class StockListController extends ChangeNotifier {
  final EquityListService _equityService;
  final StockQuoteService _quoteService;

  StockListController({EquityListService? equityService, StockQuoteService? quoteService})
      : _equityService = equityService ?? sl<EquityListService>(),
        _quoteService = quoteService ?? sl<StockQuoteService>();

  List<Equity> all = [];
  List<Equity> filtered = [];
  bool loading = true;
  String? error;

  Timer? _searchDebounce;
  Timer? _fetchDebounce;
  final Set<String> _pendingKeys = {};

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      all = await _equityService.loadAll();
      filtered = all;
    } catch (_) {
      error = 'Could not load the stock list.';
    }
    loading = false;
    notifyListeners();
  }

  /// Debounces 300ms before applying the filter, per the search-input
  /// debounce requirement.
  void onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      filtered = _equityService.search(query);
      notifyListeners();
    });
  }

  /// Called from the list item builder for every row that gets rendered.
  /// Queues its instrument key for a batched fetch — only rows Flutter
  /// actually builds (visible + small cache-extent buffer) end up here,
  /// never the full 2,416-row universe.
  void markVisible(Equity e) {
    if (e.lastPrice != null || e.priceLoading || e.instrumentKey.isEmpty) {
      return;
    }
    e.priceLoading = true;
    _pendingKeys.add(e.instrumentKey);
    _fetchDebounce?.cancel();
    _fetchDebounce = Timer(const Duration(milliseconds: 150), _flushPending);
  }

  Future<void> _flushPending() async {
    if (_pendingKeys.isEmpty) return;
    final keys = _pendingKeys.toList();
    _pendingKeys.clear();
    await _applyQuotes(keys);
  }

  /// Re-fetches prices for stocks that have already loaded at least once
  /// (used by pull-to-refresh) rather than the whole list.
  Future<void> refreshLoadedPrices() async {
    final keys = all
        .where((e) => e.lastPrice != null)
        .map((e) => e.instrumentKey)
        .toList();
    if (keys.isEmpty) return;
    for (final e in all) {
      if (keys.contains(e.instrumentKey)) e.priceLoading = true;
    }
    notifyListeners();
    await _applyQuotes(keys);
  }

  Future<void> _applyQuotes(List<String> keys) async {
    try {
      final quotes = await _quoteService.fetchQuotes(keys);
      if (kDebugMode) {
        debugPrint('[StockListController] fetched ${quotes.length}/'
            '${keys.length} quote(s).');
      }
      for (final e in all) {
        final q = quotes[e.instrumentKey];
        if (q != null) {
          e.lastPrice = q.lastPrice;
          e.dayChangePercent = q.changePercent;
        }
        if (keys.contains(e.instrumentKey)) e.priceLoading = false;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[StockListController] quote fetch failed: $e');
      for (final eq in all) {
        if (keys.contains(eq.instrumentKey)) eq.priceLoading = false;
      }
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _fetchDebounce?.cancel();
    super.dispose();
  }
}
