/// A stock saved to the user's on-device watchlist.
class WatchlistItem {
  final String symbol;
  final String name;
  final String instrumentKey;

  const WatchlistItem({
    required this.symbol,
    required this.name,
    required this.instrumentKey,
  });

  Map<String, dynamic> toJson() => {
        'symbol': symbol,
        'name': name,
        'instrument_key': instrumentKey,
      };

  factory WatchlistItem.fromJson(Map<String, dynamic> json) => WatchlistItem(
        symbol: json['symbol']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        instrumentKey: json['instrument_key']?.toString() ?? '',
      );
}
