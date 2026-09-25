import 'package:equatable/equatable.dart';
import 'live_quote_model.dart';

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
  final String? instrumentKey;
  final double? volume;
  final double? upperCircuitLimit;
  final double? lowerCircuitLimit;

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
    this.instrumentKey,
    this.volume,
    this.upperCircuitLimit,
    this.lowerCircuitLimit,
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

  /// Builds a display Quote from an Upstox Full Market Quote result.
  factory Quote.fromLiveQuote(String symbol, String name, LiveQuote q,
          {String? instrumentKey}) =>
      Quote(
        symbol: symbol,
        name: name,
        price: q.lastPrice,
        change: q.change,
        changePercent: q.changePercent,
        dayHigh: q.high,
        dayLow: q.low,
        week52High: q.yearHigh,
        week52Low: q.yearLow,
        previousClose: q.close,
        instrumentKey: instrumentKey,
        volume: q.volume,
        upperCircuitLimit: q.upperCircuitLimit,
        lowerCircuitLimit: q.lowerCircuitLimit,
      );

  @override
  List<Object?> get props => [symbol, price, change, changePercent];
}
