import 'package:equatable/equatable.dart';

/// A single holding in the user's virtual portfolio.
class Holding extends Equatable {
  final String symbol;
  final String name;
  final int quantity;
  final double avgBuyPrice;

  const Holding({
    required this.symbol,
    required this.name,
    required this.quantity,
    required this.avgBuyPrice,
  });

  double get invested => quantity * avgBuyPrice;

  double currentValue(double ltp) => quantity * ltp;
  double pnl(double ltp) => currentValue(ltp) - invested;
  double pnlPercent(double ltp) =>
      invested == 0 ? 0 : (pnl(ltp) / invested) * 100;

  Holding copyWith({int? quantity, double? avgBuyPrice}) => Holding(
        symbol: symbol,
        name: name,
        quantity: quantity ?? this.quantity,
        avgBuyPrice: avgBuyPrice ?? this.avgBuyPrice,
      );

  Map<String, dynamic> toMap() => {
        'symbol': symbol,
        'name': name,
        'quantity': quantity,
        'avg_buy_price': avgBuyPrice,
      };

  factory Holding.fromMap(Map<String, dynamic> map) => Holding(
        symbol: map['symbol'] as String,
        name: map['name'] as String,
        quantity: map['quantity'] as int,
        avgBuyPrice: (map['avg_buy_price'] as num).toDouble(),
      );

  @override
  List<Object?> get props => [symbol, quantity, avgBuyPrice];
}
