import 'package:equatable/equatable.dart';

/// A market quote for a stock or index.
class Quote extends Equatable {
  final String symbol;
  final String name;
  final double price;
  final double change;
  final double changePercent;
  final double? dayHigh;
  final double? dayLow;
  final double? week52High;
  final double? week52Low;
  final double? previousClose;

  const Quote({
    required this.symbol,
    required this.name,
    required this.price,
    required this.change,
    required this.changePercent,
    this.dayHigh,
    this.dayLow,
    this.week52High,
    this.week52Low,
    this.previousClose,
  });

  bool get isUp => change >= 0;

  /// Parses Yahoo Finance v8 chart API JSON.
  factory Quote.fromYahooChart(Map<String, dynamic> json, String fallbackName) {
    final result = json['chart']['result'][0];
    final meta = result['meta'] as Map<String, dynamic>;

    final price = (meta['regularMarketPrice'] as num?)?.toDouble() ?? 0;
    final prevClose = (meta['chartPreviousClose'] as num?)?.toDouble() ??
        (meta['previousClose'] as num?)?.toDouble() ??
        price;
    final change = price - prevClose;
    final changePct = prevClose == 0 ? 0.0 : (change / prevClose) * 100;

    return Quote(
      symbol: meta['symbol']?.toString() ?? fallbackName,
      name: fallbackName,
      price: price,
      change: change,
      changePercent: changePct,
      dayHigh: (meta['regularMarketDayHigh'] as num?)?.toDouble(),
      dayLow: (meta['regularMarketDayLow'] as num?)?.toDouble(),
      week52High: (meta['fiftyTwoWeekHigh'] as num?)?.toDouble(),
      week52Low: (meta['fiftyTwoWeekLow'] as num?)?.toDouble(),
      previousClose: prevClose,
    );
  }

  @override
  List<Object?> get props => [symbol, price, change, changePercent];
}
