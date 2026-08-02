import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/injection.dart';
import '../../core/services/ad_service.dart';
import '../../core/services/analytics_service.dart';
import '../../core/services/content_service.dart';
import '../../core/services/progress_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/models/quiz_model.dart';

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  List<QuizQuestion> _questions = [];
  int _current = 0;
  int? _selected;
  int _score = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    sl<ContentService>().loadQuiz().then((q) {
      if (mounted) {
        setState(() {
          _questions = q.take(8).toList();
          _loading = false;
        });
      }
    });
  }

  void _select(int i) {
    if (_selected != null) return;
    setState(() {
      _selected = i;
      if (i == _questions[_current].correctIndex) _score++;
    });
  }

  Future<void> _next() async {
    if (_current < _questions.length - 1) {
      setState(() {
        _current++;
        _selected = null;
      });
    } else {
      final xp = _score * 10;
      await sl<ProgressService>().addXp(xp);
      await sl<AnalyticsService>()
          .logQuizComplete(_score, _questions.length, xp);
      if (mounted) _showResult(xp);
    }
  }

  void _showResult(int xp) {
    var bonusClaimed = false;
    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.card2,
            title: const Text('Quiz Complete! 🎉'),
            content: Text(
              bonusClaimed
                  ? 'You scored $_score / ${_questions.length}\n+${xp * 2} XP earned (bonus applied)!'
                  : 'You scored $_score / ${_questions.length}\n+$xp XP earned!',
              style: const TextStyle(height: 1.6),
            ),
            actions: [
              if (xp > 0 && !bonusClaimed)
                TextButton(
                  onPressed: () {
                    final shown = sl<AdService>().showRewarded(
                      onReward: () async {
                        await sl<ProgressService>().addXp(xp);
                        await sl<AnalyticsService>()
                            .logAdRewardEarned('quiz_bonus_xp');
                        setDialogState(() => bonusClaimed = true);
                      },
                    );
                    if (!shown && dialogCtx.mounted) {
                      ScaffoldMessenger.of(dialogCtx).showSnackBar(
                        const SnackBar(content: Text('No ad available right now')),
                      );
                    }
                  },
                  child: const Text('Watch ad for +XP bonus'),
                ),
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogCtx);
                  context.pop();
                },
                child: const Text('Done'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          body: Center(
              child: CircularProgressIndicator(
                  color: AppColors.accent, strokeWidth: 2)));
    }
    final q = _questions[_current];
    final progress = (_current + (_selected != null ? 1 : 0)) /
        _questions.length;

    return Scaffold(
      appBar: AppBar(
          title: Text('Quiz  ·  Q${_current + 1} of ${_questions.length}')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: AppColors.dim,
                color: AppColors.purple,
              ),
            ),
            const SizedBox(height: 14),
            Pill(q.category, AppColors.purple),
            const SizedBox(height: 14),
            Text(q.question,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600, height: 1.5)),
            const SizedBox(height: 18),
            ...List.generate(q.options.length, (i) => _option(q, i)),
            if (_selected != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.up.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppColors.up.withValues(alpha: 0.2)),
                ),
                child: Text(
                    '${_selected == q.correctIndex ? '✓ सही! ' : '✗ '}${q.explanation}',
                    style: const TextStyle(
                        fontSize: 12,
                        height: 1.55,
                        color: AppColors.up)),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                  _current < _questions.length - 1
                      ? 'Next Question →'
                      : 'Finish Quiz',
                  onTap: _next),
            ],
          ],
        ),
      ),
    );
  }

  Widget _option(QuizQuestion q, int i) {
    final letters = ['A', 'B', 'C', 'D'];
    final selected = _selected == i;
    final isCorrect = i == q.correctIndex;
    final showResult = _selected != null;

    Color border = AppColors.border2;
    Color letterBg = AppColors.dim;
    Color letterColor = AppColors.muted;

    if (showResult && isCorrect) {
      border = AppColors.up.withValues(alpha: 0.5);
      letterBg = AppColors.up;
      letterColor = Colors.black;
    } else if (showResult && selected && !isCorrect) {
      border = AppColors.down.withValues(alpha: 0.5);
      letterBg = AppColors.down;
      letterColor = Colors.black;
    } else if (selected) {
      border = AppColors.accent.withValues(alpha: 0.5);
      letterBg = AppColors.accent;
      letterColor = Colors.black;
    }

    return GestureDetector(
      onTap: () => _select(i),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: border, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: letterBg, borderRadius: BorderRadius.circular(7)),
              child: Text(letters[i],
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: letterColor)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(q.options[i],
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      ),
    );
  }
}
