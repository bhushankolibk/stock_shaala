import 'dart:convert';
import 'package:flutter/services.dart';
import '../../data/models/equity_model.dart';

/// Loads the bundled NSE equity list (~2,416 rows) from assets and caches
/// it in memory for the app session — parsed only once.
class EquityListService {
  List<Equity>? _cache;

  Future<List<Equity>> loadAll() async {
    final cached = _cache;
    if (cached != null) return cached;
    final raw =
        await rootBundle.loadString('assets/data/nse_equity_list.json');
    final list = jsonDecode(raw) as List;
    final equities =
        list.map((e) => Equity.fromJson(e as Map<String, dynamic>)).toList();
    _cache = equities;
    return equities;
  }

  /// Case-insensitive contains-match on trading symbol or name.
  /// Only valid after [loadAll] has completed at least once.
  List<Equity> search(String query) {
    final all = _cache ?? const <Equity>[];
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all
        .where((e) =>
            e.tradingSymbol.toLowerCase().contains(q) ||
            e.name.toLowerCase().contains(q))
        .toList();
  }
}
