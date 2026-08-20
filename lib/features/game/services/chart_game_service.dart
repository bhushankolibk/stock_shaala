import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_round_model.dart';

class ChartGameService {
  final SharedPreferences prefs;

  ChartGameService(this.prefs);

  static const String _kHighScoreKey = 'stockshaala_chart_game_high_score';
  static const String _kGamesPlayedKey = 'stockshaala_chart_game_played';

  int get highScore => prefs.getInt(_kHighScoreKey) ?? 0;
  int get totalGamesPlayed => prefs.getInt(_kGamesPlayedKey) ?? 0;

  Future<void> updateHighScore(int score) async {
    if (score > highScore) {
      await prefs.setInt(_kHighScoreKey, score);
    }
    await prefs.setInt(_kGamesPlayedKey, totalGamesPlayed + 1);
  }

  /// Returns a shuffled mix of real technical pattern rounds and procedurally generated dynamic rounds.
  List<GameRound> getRandomRounds({int count = 5}) {
    final pool = List<GameRound>.from(_roundDataset)..shuffle(Random());
    final list = pool.take(count).toList();

    // Fill remaining if requested count is larger than dataset
    while (list.length < count) {
      list.add(generateProceduralRound());
    }

    return list;
  }

  /// Generates an infinite procedural chart scenario with realistic price action dynamics in Hindi & Hinglish.
  GameRound generateProceduralRound() {
    final rand = Random();
    final stocks = [
      {'symbol': 'BANKNIFTY', 'name': 'NSE Bank Index', 'base': 48000.0},
      {'symbol': 'TATASTEEL', 'name': 'Tata Steel Ltd.', 'base': 160.0},
      {'symbol': 'BAJFINANCE', 'name': 'Bajaj Finance Ltd.', 'base': 6800.0},
      {'symbol': 'BHARTIARTL', 'name': 'Bharti Airtel Ltd.', 'base': 1420.0},
      {'symbol': 'MARUTI', 'name': 'Maruti Suzuki India Ltd.', 'base': 12400.0},
      {'symbol': 'WIPRO', 'name': 'Wipro Limited', 'base': 490.0},
      {'symbol': 'TITAN', 'name': 'Titan Company Ltd.', 'base': 3450.0},
    ];

    final stock = stocks[rand.nextInt(stocks.length)];
    final symbol = stock['symbol'] as String;
    final name = stock['name'] as String;
    double currentPrice = stock['base'] as double;

    final isBull = rand.nextBool();
    final direction = isBull ? MarketDirection.bull : MarketDirection.bear;
    final volatility = currentPrice * 0.012;

    final visible = <CandleData>[];
    // Generate 4 baseline trend setup candles
    for (int i = 0; i < 4; i++) {
      final change = (rand.nextDouble() - 0.48) * volatility;
      final open = currentPrice;
      final close = open + change;
      final high = max(open, close) + rand.nextDouble() * (volatility * 0.4);
      final low = min(open, close) - rand.nextDouble() * (volatility * 0.4);

      visible.add(CandleData(open: open, high: high, low: low, close: close));
      currentPrice = close;
    }

    // 5th visible candle is the key Breakout / Breakdown trigger candle
    final triggerOpen = currentPrice;
    final triggerClose = isBull
        ? triggerOpen + (volatility * (0.8 + rand.nextDouble() * 0.4))
        : triggerOpen - (volatility * (0.8 + rand.nextDouble() * 0.4));
    final triggerHigh = max(triggerOpen, triggerClose) + rand.nextDouble() * (volatility * 0.2);
    final triggerLow = min(triggerOpen, triggerClose) - rand.nextDouble() * (volatility * 0.2);

    visible.add(CandleData(open: triggerOpen, high: triggerHigh, low: triggerLow, close: triggerClose));
    currentPrice = triggerClose;

    // Generate 3 hidden continuation candles
    final hidden = <CandleData>[];
    final breakoutFactor = isBull ? 1.0 : -1.0;
    for (int i = 0; i < 3; i++) {
      final step = (volatility * (0.9 + rand.nextDouble() * 0.6)) * breakoutFactor;
      final open = currentPrice;
      final close = open + step;
      final high = max(open, close) + rand.nextDouble() * (volatility * 0.3);
      final low = min(open, close) - rand.nextDouble() * (volatility * 0.3);

      hidden.add(CandleData(open: open, high: high, low: low, close: close));
      currentPrice = close;
    }

    final patternName = isBull ? 'Bullish Breakout 🟢' : 'Bearish Breakdown 🔴';
    final explanation = isBull
        ? 'Support level par buying momentum aane se price upar breakout ho gaya!'
        : 'Key support level break hote hi panic selling aayi aur price tezi se neeche gir gaya!';

    final hindiExp = isBull
        ? 'सपोर्ट लेवल पर मजबूत खरीदारी (buying) आने से शेयर की कीमत में तेजी से ब्रेकआउट आया!'
        : 'मुख्य सपोर्ट लेवल टूटते ही पैनिक सेलिंग (panic selling) आई और शेयर का भाव तेजी से नीचे गिर गया!';

    return GameRound(
      id: 'proc_${DateTime.now().millisecondsSinceEpoch}_${rand.nextInt(1000)}',
      symbol: symbol,
      companyName: name,
      visibleCandles: visible,
      hiddenCandles: hidden,
      correctDirection: direction,
      patternName: patternName,
      explanation: explanation,
      hindiExplanation: hindiExp,
      difficulty: GameDifficulty.medium,
    );
  }

  static final List<GameRound> _roundDataset = [
    // 1. Bullish Engulfing at Support (NIFTY 50)
    GameRound(
      id: 'round_nifty_bull_engulfing',
      symbol: 'NIFTY 50',
      companyName: 'NSE Benchmark Index',
      difficulty: GameDifficulty.easy,
      visibleCandles: const [
        CandleData(open: 22100, high: 22150, low: 22050, close: 22080),
        CandleData(open: 22080, high: 22090, low: 21980, close: 22000),
        CandleData(open: 22000, high: 22020, low: 21920, close: 21940),
        CandleData(open: 21940, high: 21950, low: 21880, close: 21900), // Red Candle at support 21,880
        CandleData(open: 21890, high: 22120, low: 21880, close: 22100), // Strong Bullish Engulfing Green Candle!
      ],
      hiddenCandles: const [
        CandleData(open: 22100, high: 22250, low: 22090, close: 22220),
        CandleData(open: 22220, high: 22340, low: 22200, close: 22310),
        CandleData(open: 22310, high: 22450, low: 22290, close: 22420),
      ],
      correctDirection: MarketDirection.bull,
      patternName: 'Bullish Engulfing Pattern',
      explanation:
          'Support level 21,880 par ek strong green candle ne picchli red candle ko poora engulf kar liya! Buyers ne heavy buying karke +520 pts ki rally laayi.',
      hindiExplanation:
          'सपोर्ट लेवल 21,880 पर एक मजबूत ग्रीन कैंडल ने पिछली रेड कैंडल को पूरा ढक (engulf) लिया! बायर्स की भारी खरीदारी से +520 पॉइंट्स की शानदार तेजी (rally) आई।',
    ),

    // 2. Bearish Shooting Star at Resistance (RELIANCE)
    GameRound(
      id: 'round_rel_shooting_star',
      symbol: 'RELIANCE',
      companyName: 'Reliance Industries Ltd.',
      difficulty: GameDifficulty.medium,
      visibleCandles: const [
        CandleData(open: 2880, high: 2910, low: 2875, close: 2905),
        CandleData(open: 2905, high: 2935, low: 2900, close: 2930),
        CandleData(open: 2930, high: 2960, low: 2925, close: 2955),
        CandleData(open: 2955, high: 3020, low: 2940, close: 2948), // Shooting Star Pinbar with long upper wick to 3020
      ],
      hiddenCandles: const [
        CandleData(open: 2948, high: 2950, low: 2890, close: 2895),
        CandleData(open: 2895, high: 2900, low: 2840, close: 2850),
        CandleData(open: 2850, high: 2860, low: 2800, close: 2810),
      ],
      correctDirection: MarketDirection.bear,
      patternName: 'Shooting Star Reversal',
      explanation:
          'Resistance ke paas ₹3,020 par long upper wick bani jo heavy selling pressure dikhaati hai. Sellers ne price ko neeche ₹2,810 tak push kar diya.',
      hindiExplanation:
          'रेजिस्टेंस के पास ₹3,020 पर लंबी ऊपरी बत्ती (upper wick) बनी जो भारी बिकवाली का दबाव दर्शाती है। सेलर्स ने कीमत को नीचे ₹2,810 तक गिरा दिया।',
    ),

    // 3. W-Shape Double Bottom Breakout (TATAMOTORS)
    GameRound(
      id: 'round_tatamotors_double_bottom',
      symbol: 'TATAMOTORS',
      companyName: 'Tata Motors Limited',
      difficulty: GameDifficulty.easy,
      visibleCandles: const [
        CandleData(open: 940, high: 945, low: 900, close: 905), // Drop to Bottom #1 at ₹900
        CandleData(open: 905, high: 938, low: 905, close: 935), // Bounce up to Neckline ₹935
        CandleData(open: 935, high: 938, low: 915, close: 920), // Pullback from Neckline
        CandleData(open: 920, high: 922, low: 898, close: 902), // Drop to Bottom #2 at ₹898 (W-shape second leg)
        CandleData(open: 902, high: 935, low: 900, close: 930), // Bullish recovery towards Neckline
        CandleData(open: 930, high: 945, low: 928, close: 942), // Breakout Candle closing ABOVE ₹940 Neckline!
      ],
      hiddenCandles: const [
        CandleData(open: 942, high: 968, low: 938, close: 965),
        CandleData(open: 965, high: 995, low: 960, close: 990),
        CandleData(open: 990, high: 1025, low: 985, close: 1018),
      ],
      correctDirection: MarketDirection.bull,
      patternName: 'W-Shape Double Bottom',
      explanation:
          'Stock ne ₹900 support level ko 2 baar test kiya aur ₹940 neckline ko break karke W-shape Double Bottom pattern ke saath ₹1,018 tak bullish rally di.',
      hindiExplanation:
          'स्टॉक ने ₹900 सपोर्ट लेवल को 2 बार टेस्ट किया और ₹940 नेकलाइन को तोड़कर W-शेप डबल बॉटम पैटर्न के साथ ₹1,018 तक तेजी दर्ज की।',
    ),

    // 4. Head & Shoulders Breakdown (HDFCBANK)
    GameRound(
      id: 'round_hdfc_head_shoulders',
      symbol: 'HDFCBANK',
      companyName: 'HDFC Bank Ltd.',
      difficulty: GameDifficulty.hard,
      visibleCandles: const [
        CandleData(open: 1610, high: 1660, low: 1605, close: 1650), // Left Shoulder peak at ₹1,660
        CandleData(open: 1650, high: 1652, low: 1625, close: 1630), // Dip to Neckline ₹1,630
        CandleData(open: 1630, high: 1710, low: 1630, close: 1700), // Head peak at ₹1,710
        CandleData(open: 1700, high: 1705, low: 1625, close: 1630), // Dip back to Neckline ₹1,630
        CandleData(open: 1630, high: 1665, low: 1628, close: 1655), // Right Shoulder peak at ₹1,665
        CandleData(open: 1655, high: 1655, low: 1615, close: 1618), // Breakdown Candle closing BELOW ₹1,630 Neckline!
      ],
      hiddenCandles: const [
        CandleData(open: 1618, high: 1620, low: 1570, close: 1575),
        CandleData(open: 1575, high: 1580, low: 1530, close: 1535),
        CandleData(open: 1535, high: 1545, low: 1490, close: 1500),
      ],
      correctDirection: MarketDirection.bear,
      patternName: 'Head & Shoulders Breakdown',
      explanation:
          'Classic Head & Shoulders pattern ne ₹1,630 neckline ko break kar diya. Selling pressure ki wajah se HDFC Bank ka price ₹1,500 tak gir gaya.',
      hindiExplanation:
          'क्लासिक हेड एंड शोल्डर्स पैटर्न ने ₹1,630 नेकलाइन को तोड़ दिया। बिकवाली के दबाव से HDFC बैंक का शेयर ₹1,500 तक गिर गया।',
    ),

    // 5. Hammer Candle at Support (TCS)
    GameRound(
      id: 'round_tcs_hammer',
      symbol: 'TCS',
      companyName: 'Tata Consultancy Services',
      difficulty: GameDifficulty.easy,
      visibleCandles: const [
        CandleData(open: 3950, high: 3960, low: 3900, close: 3910),
        CandleData(open: 3910, high: 3920, low: 3850, close: 3860),
        CandleData(open: 3860, high: 3865, low: 3780, close: 3855), // Pinbar Hammer with long lower shadow to ₹3,780
      ],
      hiddenCandles: const [
        CandleData(open: 3855, high: 3930, low: 3850, close: 3925),
        CandleData(open: 3925, high: 4010, low: 3920, close: 3995),
        CandleData(open: 3995, high: 4080, low: 3990, close: 4060),
      ],
      correctDirection: MarketDirection.bull,
      patternName: 'Bullish Hammer Pinbar',
      explanation:
          '₹3,780 support par lambi bottom shadow wali Hammer candle bani, jisse buyers ne aggressive entry li aur 200+ pts ka strong bullish bounce aaya!',
      hindiExplanation:
          '₹3,780 सपोर्ट पर लंबी निचली परछाई (bottom shadow) वाली हैमर कैंडल बनी, जिससे बायर्स ने आक्रामक एंट्री ली और 200+ पॉइंट्स की मजबूत रिकवरी हुई!',
    ),

    // 6. Bearish Evening Star (INFY)
    GameRound(
      id: 'round_infy_evening_star',
      symbol: 'INFY',
      companyName: 'Infosys Limited',
      difficulty: GameDifficulty.medium,
      visibleCandles: const [
        CandleData(open: 1480, high: 1525, low: 1475, close: 1520), // Strong Green Candle
        CandleData(open: 1522, high: 1538, low: 1518, close: 1530), // Small Doji top at peak
        CandleData(open: 1528, high: 1530, low: 1470, close: 1475), // Large Red Engulfing Candle
      ],
      hiddenCandles: const [
        CandleData(open: 1475, high: 1480, low: 1430, close: 1435),
        CandleData(open: 1435, high: 1440, low: 1390, close: 1395),
        CandleData(open: 1395, high: 1405, low: 1360, close: 1370),
      ],
      correctDirection: MarketDirection.bear,
      patternName: 'Bearish Evening Star',
      explanation:
          'Top par 3-candle Evening Star pattern bana. Large red candle ne reversal confirm kiya aur trend neeche ki taraf ghoom gaya.',
      hindiExplanation:
          'टॉप पर 3-कैंडल इवनिंग स्टार पैटर्न बना। बड़ी रेड कैंडल ने ट्रेंड रिवर्सल की पुष्टि की और कीमत नीचे गिरना शुरू हो गई।',
    ),
  ];
}
