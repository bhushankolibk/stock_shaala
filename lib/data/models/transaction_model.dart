import 'package:equatable/equatable.dart';

enum TradeType { buy, sell }

class TradeTransaction extends Equatable {
  final int? id;
  final String symbol;
  final String name;
  final TradeType type;
  final int quantity;
  final double price;
  final DateTime timestamp;

  const TradeTransaction({
    this.id,
    required this.symbol,
    required this.name,
    required this.type,
    required this.quantity,
    required this.price,
    required this.timestamp,
  });

  double get total => quantity * price;

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'symbol': symbol,
        'name': name,
        'type': type.name,
        'quantity': quantity,
        'price': price,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };

  factory TradeTransaction.fromMap(Map<String, dynamic> map) => TradeTransaction(
        id: map['id'] as int?,
        symbol: map['symbol'] as String,
        name: map['name'] as String,
        type: TradeType.values.byName(map['type'] as String),
        quantity: map['quantity'] as int,
        price: (map['price'] as num).toDouble(),
        timestamp:
            DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      );

  @override
  List<Object?> get props => [id, symbol, type, quantity, price, timestamp];
}
