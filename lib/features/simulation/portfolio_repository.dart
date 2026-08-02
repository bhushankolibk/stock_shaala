import 'package:fpdart/fpdart.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/local_db_service.dart';
import '../../core/services/market_api_service.dart';
import '../../data/models/holding_model.dart';
import '../../data/models/quote_model.dart';
import '../../data/models/transaction_model.dart';

/// Result of a portfolio valuation.
class PortfolioSnapshot {
  final double cash;
  final double holdingsValue;
  final double invested;
  final List<({Holding holding, double ltp})> positions;
  final int tradeCount;

  const PortfolioSnapshot({
    required this.cash,
    required this.holdingsValue,
    required this.invested,
    required this.positions,
    required this.tradeCount,
  });

  double get totalValue => cash + holdingsValue;
  double get totalPnl => holdingsValue - invested;
  double get totalPnlPercent =>
      invested == 0 ? 0 : (totalPnl / invested) * 100;
}

/// Trade failures.
sealed class TradeFailure {
  final String message;
  const TradeFailure(this.message);
}

class InsufficientFunds extends TradeFailure {
  const InsufficientFunds() : super('Not enough virtual cash for this trade.');
}

class InsufficientShares extends TradeFailure {
  const InsufficientShares()
      : super("You don't own enough shares to sell.");
}

class PriceUnavailable extends TradeFailure {
  const PriceUnavailable()
      : super('Live price unavailable. Pull to refresh and try again.');
}

/// All trading is virtual and local. No real orders are ever placed.
class PortfolioRepository {
  final LocalDbService _db;
  final MarketApiService _api;

  PortfolioRepository(this._db, this._api);

  Future<double> cash() => _db.getCash(AppConstants.startingVirtualCash);

  /// Build a valued snapshot using fresh quotes.
  Future<PortfolioSnapshot> snapshot(List<Quote> quotes) async {
    final cashVal = await cash();
    final holdings = await _db.getHoldings();
    final tradeCount = await _db.transactionCount();

    final priceMap = {for (final q in quotes) q.symbol: q.price};

    double holdingsValue = 0;
    double invested = 0;
    final positions = <({Holding holding, double ltp})>[];

    for (final h in holdings) {
      final ltp = priceMap[h.symbol] ?? h.avgBuyPrice;
      holdingsValue += h.currentValue(ltp);
      invested += h.invested;
      positions.add((holding: h, ltp: ltp));
    }

    return PortfolioSnapshot(
      cash: cashVal,
      holdingsValue: holdingsValue,
      invested: invested,
      positions: positions,
      tradeCount: tradeCount,
    );
  }

  Future<Either<TradeFailure, Unit>> buy({
    required String symbol,
    required String name,
    required int quantity,
    required double price,
  }) async {
    if (price <= 0) return const Left(PriceUnavailable());
    final cost = price * quantity;
    final cashVal = await cash();
    if (cost > cashVal) return const Left(InsufficientFunds());

    final existing = await _db.getHolding(symbol);
    if (existing == null) {
      await _db.upsertHolding(Holding(
        symbol: symbol,
        name: name,
        quantity: quantity,
        avgBuyPrice: price,
      ));
    } else {
      final totalQty = existing.quantity + quantity;
      final newAvg =
          ((existing.avgBuyPrice * existing.quantity) + cost) / totalQty;
      await _db.upsertHolding(
          existing.copyWith(quantity: totalQty, avgBuyPrice: newAvg));
    }

    await _db.setCash(cashVal - cost);
    await _db.addTransaction(TradeTransaction(
      symbol: symbol,
      name: name,
      type: TradeType.buy,
      quantity: quantity,
      price: price,
      timestamp: DateTime.now(),
    ));
    return const Right(unit);
  }

  Future<Either<TradeFailure, Unit>> sell({
    required String symbol,
    required String name,
    required int quantity,
    required double price,
  }) async {
    if (price <= 0) return const Left(PriceUnavailable());
    final existing = await _db.getHolding(symbol);
    if (existing == null || existing.quantity < quantity) {
      return const Left(InsufficientShares());
    }

    final proceeds = price * quantity;
    final remaining = existing.quantity - quantity;
    if (remaining == 0) {
      await _db.deleteHolding(symbol);
    } else {
      await _db.upsertHolding(existing.copyWith(quantity: remaining));
    }

    final cashVal = await cash();
    await _db.setCash(cashVal + proceeds);
    await _db.addTransaction(TradeTransaction(
      symbol: symbol,
      name: name,
      type: TradeType.sell,
      quantity: quantity,
      price: price,
      timestamp: DateTime.now(),
    ));
    return const Right(unit);
  }

  Future<List<TradeTransaction>> transactions() => _db.getTransactions();

  /// Reset the simulator to the starting cash.
  Future<void> reset() => _db.resetAll();

  /// Tops up virtual cash by [amount] (e.g. after a rewarded ad).
  Future<void> addFunds(double amount) async {
    final cashVal = await cash();
    await _db.setCash(cashVal + amount);
  }

  Future<List<Quote>> refreshQuotes() => _api.fetchStockQuotes();
  Future<List<Quote>> refreshIndices() => _api.fetchIndices();
}
