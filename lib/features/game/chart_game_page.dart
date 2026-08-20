import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/injection.dart';
import '../../core/services/ad_service.dart';
import '../../core/services/analytics_service.dart';
import '../../core/services/progress_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/banner_ad_widget.dart';
import 'models/game_round_model.dart';
import 'services/chart_game_service.dart';
import 'widgets/candlestick_chart_painter.dart';

class ChartGamePage extends StatefulWidget {
  const ChartGamePage({super.key});

  @override
  State<ChartGamePage> createState() => _ChartGamePageState();
}

class _ChartGamePageState extends State<ChartGamePage>
    with SingleTickerProviderStateMixin {
  late final ChartGameService _gameService;
  List<GameRound> _rounds = [];
  int _currentRoundIdx = 0;
  int _score = 0;
  int _streak = 0;
  int _multiplier = 1;
  int _correctCount = 0;

  // Timer & state
  static const int _roundTimeSeconds = 10;
  int _secondsRemaining = _roundTimeSeconds;
  Timer? _timer;
  bool _isAnswered = false;
  MarketDirection? _selectedDirection;

  // Animation controller for chart reveal
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _gameService = ChartGameService(sl());
    _rounds = _gameService.getRandomRounds(count: 5);

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _startRoundTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _startRoundTimer() {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = _roundTimeSeconds;
      _isAnswered = false;
      _selectedDirection = null;
    });
    _animController.reset();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 1) {
        setState(() => _secondsRemaining--);
      } else {
        _timer?.cancel();
        if (!_isAnswered) {
          _submitAnswer(null); // Time out
        }
      }
    });
  }

  void _submitAnswer(MarketDirection? chosen) {
    if (_isAnswered) return;
    _timer?.cancel();

    final currentRound = _rounds[_currentRoundIdx];
    final isCorrect = chosen == currentRound.correctDirection;

    setState(() {
      _isAnswered = true;
      _selectedDirection = chosen;

      if (isCorrect) {
        _streak++;
        _correctCount++;
        _multiplier = (_streak >= 3) ? 3 : (_streak >= 2 ? 2 : 1);
        _score += (20 * _multiplier);
      } else {
        _streak = 0;
        _multiplier = 1;
      }
    });

    // Animate candle reveal
    _animController.forward();
  }

  void _nextRound() {
    if (_currentRoundIdx < _rounds.length - 1) {
      setState(() {
        _currentRoundIdx++;
      });
      _startRoundTimer();
    } else {
      _finishGame();
    }
  }

  Future<void> _finishGame() async {
    final earnedXp = _score;
    await sl<ProgressService>().addXp(earnedXp);
    await _gameService.updateHighScore(_score);
    await sl<AnalyticsService>().logQuizComplete(_correctCount, _rounds.length, earnedXp);

    // Show Interstitial Ad on session completion (frequency-capped every 2 game sessions)
    if (_gameService.totalGamesPlayed % 2 == 0) {
      sl<AdService>().showInterstitialIfReady();
    }

    if (!mounted) return;
    _showGameOverDialog(earnedXp);
  }

  void _showGameOverDialog(int earnedXp) {
    bool bonusClaimed = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.card2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Expanded(
                  child: Text(
                    '🏆 Game Poora Hua!',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Pill('$_correctCount/${_rounds.length} Sahi', AppColors.up),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  bonusClaimed
                      ? 'Final Score: $_score pts\n+${earnedXp * 2} XP Mila (2x Bonus apply ho gaya!)'
                      : 'Final Score: $_score pts\n+$earnedXp XP Mila!',
                  style: const TextStyle(fontSize: 16, height: 1.6, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Text(
                  'High Score: ${_gameService.highScore} pts',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
            actions: [
              if (earnedXp > 0 && !bonusClaimed)
                TextButton.icon(
                  icon: const Icon(Icons.movie_rounded, size: 16, color: AppColors.accent),
                  label: const Text('Ad dekho aur 2x Bonus XP paao', style: TextStyle(color: AppColors.accent)),
                  onPressed: () {
                    final shown = sl<AdService>().showRewarded(
                      onReward: () async {
                        await sl<ProgressService>().addXp(earnedXp);
                        setDialogState(() => bonusClaimed = true);
                      },
                    );
                    if (!shown && dialogCtx.mounted) {
                      ScaffoldMessenger.of(dialogCtx).showSnackBar(
                        const SnackBar(content: Text('Abhi ad available nahi hai')),
                      );
                    }
                  },
                ),
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogCtx);
                  context.pop();
                },
                child: const Text('Fir Se Khele / Exit', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentRound = _rounds[_currentRoundIdx];

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bull vs Bear · Round ${_currentRoundIdx + 1}/${_rounds.length}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            Text('${currentRound.symbol} - ${currentRound.companyName}',
                style: const TextStyle(fontSize: 11, color: AppColors.muted)),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt, size: 14, color: AppColors.accent),
                const SizedBox(width: 2),
                Text('$_score XP',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accent)),
              ],
            ),
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: Streak, Multiplier, and Timer
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Pill('🔥 Streak: $_streak', AppColors.accent),
                  const SizedBox(width: 8),
                  if (_multiplier > 1) Pill('${_multiplier}x Multiplier!', AppColors.up),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _secondsRemaining <= 3 ? AppColors.down.withValues(alpha: 0.2) : AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _secondsRemaining <= 3 ? AppColors.down : AppColors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.timer_outlined,
                            size: 14,
                            color: _secondsRemaining <= 3 ? AppColors.down : AppColors.muted),
                        const SizedBox(width: 4),
                        Text(
                          '${_secondsRemaining}s',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _secondsRemaining <= 3 ? AppColors.down : AppColors.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Candlestick Chart Display Area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: GlassCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('PATTERN SPOTTER',
                                  style: AppTheme.mono(size: 10, color: AppColors.muted)),
                              const SizedBox(height: 2),
                              Text(
                                '₹${(currentRound.visibleCandles.last.close >= 1000 ? currentRound.visibleCandles.last.close.toStringAsFixed(0) : currentRound.visibleCandles.last.close.toStringAsFixed(2))}',
                                style: AppTheme.mono(
                                  size: 13,
                                  weight: FontWeight.bold,
                                  color: currentRound.visibleCandles.last.isBullish ? AppColors.up : AppColors.down,
                                ),
                              ),
                            ],
                          ),
                          Pill(currentRound.difficulty.name.toUpperCase(), AppColors.purple),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: AnimatedBuilder(
                          animation: _animController,
                          builder: (context, child) {
                            return CandlestickChartPainterWidget(
                              visibleCandles: currentRound.visibleCandles,
                              hiddenCandles: currentRound.hiddenCandles,
                              revealProgress: _animController.value,
                              isRevealed: _isAnswered,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Answer Action Buttons or Explanation Result Card
            if (!_isAnswered) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: Column(
                  children: [
                    const Text('Predict karo agla move kya hoga:',
                        style: TextStyle(fontSize: 13, color: AppColors.muted)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _gameActionButton(
                            label: 'BULL 🟢 (UPAR)',
                            color: AppColors.up,
                            onTap: () => _submitAnswer(MarketDirection.bull),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _gameActionButton(
                            label: 'BEAR 🔴 (NEECHE)',
                            color: AppColors.down,
                            onTap: () => _submitAnswer(MarketDirection.bear),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            ] else ...[
              // Post-Answer Educational Explanation Card
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: _resultExplanationCard(currentRound),
              ),
            ],
            const Center(child: BannerAdWidget()),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _gameActionButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              color: color,
            ),
          ),
        ),
      ),
    );
  }

  Widget _resultExplanationCard(GameRound round) {
    final isCorrect = _selectedDirection == round.correctDirection;

    return GlassCard(
      color: isCorrect
          ? AppColors.up.withValues(alpha: 0.08)
          : AppColors.down.withValues(alpha: 0.08),
      borderColor: isCorrect
          ? AppColors.up.withValues(alpha: 0.4)
          : AppColors.down.withValues(alpha: 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: isCorrect ? AppColors.up : AppColors.down,
                size: 20,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  isCorrect ? 'Sahi Jawaab! 🎉 (+XP)' : 'Galat Jawaab! ❌',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isCorrect ? AppColors.up : AppColors.down,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.purple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.purple.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    round.patternName,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.purple,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
            ],
          ),
          if (round.hindiExplanation != null) ...[
            const SizedBox(height: 8),
            Text(
              round.hindiExplanation!,
              style: const TextStyle(
                fontSize: 12,
                height: 1.5,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              round.explanation,
              style: const TextStyle(
                fontSize: 11,
                height: 1.4,
                color: AppColors.muted,
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              round.explanation,
              style: const TextStyle(fontSize: 12, height: 1.5, color: AppColors.text),
            ),
          ],
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.dim,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.show_chart_rounded, size: 13, color: AppColors.accent),
                const SizedBox(width: 5),
                Text(
                  'Price Move: ₹${round.visibleCandles.last.close.toStringAsFixed(0)} ➔ ₹${round.allCandles.last.close.toStringAsFixed(0)} (${round.correctDirection == MarketDirection.bull ? '+' : ''}${(round.allCandles.last.close - round.visibleCandles.last.close).toStringAsFixed(0)} pts)',
                  style: AppTheme.mono(size: 10, color: AppColors.text, weight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            _currentRoundIdx < _rounds.length - 1 ? 'Agla Round →' : 'Final Score Dekho 🏆',
            onTap: _nextRound,
          ),
        ],
      ),
    );
  }
}

class CandlestickChartPainterWidget extends StatelessWidget {
  final List<CandleData> visibleCandles;
  final List<CandleData> hiddenCandles;
  final double revealProgress;
  final bool isRevealed;

  const CandlestickChartPainterWidget({
    super.key,
    required this.visibleCandles,
    required this.hiddenCandles,
    required this.revealProgress,
    required this.isRevealed,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: CandlestickChartPainter(
        visibleCandles: visibleCandles,
        hiddenCandles: hiddenCandles,
        revealProgress: revealProgress,
        isRevealed: isRevealed,
      ),
    );
  }
}
