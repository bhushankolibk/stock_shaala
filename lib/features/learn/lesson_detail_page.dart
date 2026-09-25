import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/injection.dart';
import '../../core/services/ad_service.dart';
import '../../core/services/analytics_service.dart';
import '../../core/services/progress_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/banner_ad_widget.dart';
import '../../data/models/lesson_model.dart';

class LessonDetailPage extends StatelessWidget {
  final Lesson lesson;
  const LessonDetailPage({super.key, required this.lesson});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(lesson.category)),
      bottomNavigationBar: const BannerAdWidget(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          children: [
            Text(lesson.title,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w700, height: 1.25)),
            const SizedBox(height: 8),
            Row(children: [
              Pill('${lesson.durationMin} min', AppColors.blue),
              const SizedBox(width: 6),
              Pill('+${lesson.xp} XP', AppColors.up),
            ]),
            const SizedBox(height: 20),
            Text(
              lesson.content.isEmpty
                  ? 'Lesson content for "${lesson.title}" goes here. '
                      'Add rich educational text in lessons.json or via Remote Config.'
                  : lesson.content,
              style: const TextStyle(
                  fontSize: 14, height: 1.7, color: Color(0xFFB8C5DC)),
            ),
            const SizedBox(height: 24),
            // Educational-only reminder
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.blue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppColors.blue.withValues(alpha: 0.2)),
              ),
              child: const Text(
                '📖 यह content सिर्फ educational है। कोई buy/sell सलाह नहीं।',
                style: TextStyle(
                    fontSize: 11, height: 1.5, color: AppColors.muted),
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton('Mark Complete (+${lesson.xp} XP)', onTap: () async {
              final progress = sl<ProgressService>();
              final ads = sl<AdService>();
              final alreadyDone = progress.completedLessonIds.contains(lesson.id);
              if (!alreadyDone) await progress.addXp(lesson.xp);
              await progress.markLessonComplete(lesson.id);

              if (!alreadyDone) {
                await sl<AnalyticsService>()
                    .logLessonComplete(lesson.id, lesson.xp);
                final count = await progress.incrementLessonCompletionCount();
                if (count % 3 == 0) ads.showInterstitialIfReady();
              }

              if (context.mounted) {
                if (!alreadyDone) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('+${lesson.xp} XP earned!'),
                      backgroundColor: AppColors.up,
                      action: SnackBarAction(
                        label: 'Watch ad for 2x XP',
                        textColor: Colors.white,
                        onPressed: () {
                          ads.showRewarded(
                            onReward: () {
                              progress.addXp(lesson.xp);
                              sl<AnalyticsService>()
                                  .logAdRewardEarned('lesson_bonus_xp');
                            },
                          );
                        },
                      ),
                    ),
                  );
                }
                context.pop();
              }
            }),
          ],
        ),
      ),
    );
  }
}
