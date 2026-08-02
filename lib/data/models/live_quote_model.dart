/// A single instrument's live quote from Upstox's Full Market Quote API
/// (`GET /v2/market-quote/quotes`).
class LiveQuote {
  final double lastPrice;
  final double open;
  final double high;
  final double low;
  final double close;

  const LiveQuote({
    required this.lastPrice,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
  });

  factory LiveQuote.fromJson(Map<String, dynamic> json) {
    final ohlc = json['ohlc'] as Map<String, dynamic>? ?? const {};
    return LiveQuote(
      lastPrice: (json['last_price'] as num?)?.toDouble() ?? 0,
      open: (ohlc['open'] as num?)?.toDouble() ?? 0,
      high: (ohlc['high'] as num?)?.toDouble() ?? 0,
      low: (ohlc['low'] as num?)?.toDouble() ?? 0,
      close: (ohlc['close'] as num?)?.toDouble() ?? 0,
    );
  }

  double get change => lastPrice - close;
  double get changePercent => close == 0 ? 0 : (change / close) * 100;
}
