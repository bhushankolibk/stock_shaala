/// An NSE-listed equity from the bundled instrument list, with live-price
/// fields that start null and get filled in as the row scrolls into view.
class Equity {
  final String tradingSymbol;
  final String name;
  final String instrumentKey;

  double? lastPrice;
  double? dayChangePercent;
  bool priceLoading;

  Equity({
    required this.tradingSymbol,
    required this.name,
    required this.instrumentKey,
    this.lastPrice,
    this.dayChangePercent,
    this.priceLoading = false,
  });

  factory Equity.fromJson(Map<String, dynamic> json) => Equity(
        tradingSymbol: json['trading_symbol']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        instrumentKey: json['instrument_key']?.toString() ?? '',
      );

  bool get isUp => (dayChangePercent ?? 0) >= 0;
}
