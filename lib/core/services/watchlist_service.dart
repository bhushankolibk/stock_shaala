import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../../data/models/watchlist_item_model.dart';

/// The user's watchlist — entirely on-device (SharedPreferences), no API
/// call involved in adding/removing a stock. A [ChangeNotifier] so any
/// star/bookmark button showing watched-state anywhere in the app updates
/// immediately when the list changes.
class WatchlistService extends ChangeNotifier {
  final SharedPreferences prefs;
  WatchlistService(this.prefs);

  List<WatchlistItem> get items {
    final raw = prefs.getStringList(AppConstants.kWatchlistItems) ?? [];
    return raw
        .map((s) => WatchlistItem.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  bool isWatched(String instrumentKey) =>
      items.any((i) => i.instrumentKey == instrumentKey);

  Future<void> toggle(WatchlistItem item) async {
    final current = items;
    final exists = current.any((i) => i.instrumentKey == item.instrumentKey);
    final updated = exists
        ? current.where((i) => i.instrumentKey != item.instrumentKey).toList()
        : [...current, item];
    await prefs.setStringList(
      AppConstants.kWatchlistItems,
      updated.map((i) => jsonEncode(i.toJson())).toList(),
    );
    notifyListeners();
  }

  Future<void> remove(String instrumentKey) async {
    final updated =
        items.where((i) => i.instrumentKey != instrumentKey).toList();
    await prefs.setStringList(
      AppConstants.kWatchlistItems,
      updated.map((i) => jsonEncode(i.toJson())).toList(),
    );
    notifyListeners();
  }
}
