enum MarketDirection { bull, bear }

enum GameDifficulty { easy, medium, hard }

class CandleData {
  final double open;
  final double high;
  final double low;
  final double close;

  const CandleData({
    required this.open,
    required this.high,
    required this.low,
    required this.close,
  });

  bool get isBullish => close >= open;
}

class GameRound {
  final String id;
  final String symbol;
  final String companyName;
  final List<CandleData> visibleCandles;
  final List<CandleData> hiddenCandles;
  final MarketDirection correctDirection;
  final String patternName;
  final String explanation;
  final String? hindiExplanation;
  final GameDifficulty difficulty;

  const GameRound({
    required this.id,
    required this.symbol,
    required this.companyName,
    required this.visibleCandles,
    required this.hiddenCandles,
    required this.correctDirection,
    required this.patternName,
    required this.explanation,
    this.hindiExplanation,
    this.difficulty = GameDifficulty.easy,
  });

  List<CandleData> get allCandles => [...visibleCandles, ...hiddenCandles];
}
