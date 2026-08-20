import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/injection.dart';
import '../../core/services/content_service.dart';
import '../../core/services/progress_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/banner_ad_widget.dart';
import '../../data/models/lesson_model.dart';
import 'read_section.dart';
import 'watch_section.dart';

class LearnPage extends StatefulWidget {
  const LearnPage({super.key});

  @override
  State<LearnPage> createState() => _LearnPageState();
}

class _LearnPageState extends State<LearnPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                const Text('Learn',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                const Spacer(),
                GestureDetector(
                  onTap: () => context.push('/concept-cards'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.purple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.purple.withValues(alpha: 0.25)),
                    ),
                    child: const Text('Concept Cards',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.purple)),
                  ),
                ),
              ],
            ),
          ),
          _tabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: const [
                _LessonsTab(),
                ReadSection(),
                WatchSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabBar() {
    return AnimatedBuilder(
      animation: _tabs,
      builder: (_, __) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: Row(
          children: [
            _tab(0, 'Lessons', Icons.school_outlined),
            const SizedBox(width: 8),
            _tab(1, 'Read', Icons.article_outlined),
            const SizedBox(width: 8),
            _tab(2, 'Watch', Icons.play_circle_outline),
          ],
        ),
      ),
    );
  }

  Widget _tab(int index, String label, IconData icon) {
    final active = _tabs.index == index;
    return GestureDetector(
      onTap: () => _tabs.animateTo(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? AppColors.accent.withValues(alpha: 0.12)
              : AppColors.dim,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active
                ? AppColors.accent.withValues(alpha: 0.35)
                : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13,
                color: active ? AppColors.accent : AppColors.muted),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: active ? AppColors.accent : AppColors.muted)),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Lessons tab (original content)
// ──────────────────────────────────────────────

class _LessonsTab extends StatefulWidget {
  const _LessonsTab();

  @override
  State<_LessonsTab> createState() => _LessonsTabState();
}

class _LessonsTabState extends State<_LessonsTab>
    with AutomaticKeepAliveClientMixin {
  List<Lesson> _lessons = [];
  String _filter = 'All';
  bool _loading = true;

  static const _filters = ['All', 'Basics', 'Technical', 'Fundamental', 'F&O'];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final lessons = await sl<ContentService>().loadLessons();
    final done = sl<ProgressService>().completedLessonIds;
    bool foundActive = false;
    final processed = lessons.map((l) {
      if (done.contains(l.id)) return l.copyWith(status: LessonStatus.done);
      if (!foundActive) {
        foundActive = true;
        return l.copyWith(status: LessonStatus.active);
      }
      return l.copyWith(status: LessonStatus.locked);
    }).toList();
    if (mounted) setState(() { _lessons = processed; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final visible = _filter == 'All'
        ? _lessons
        : _lessons.where((l) => l.category == _filter).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          decoration: BoxDecoration(
              color: AppColors.dim, borderRadius: BorderRadius.circular(12)),
          child: const Row(children: [
            Icon(Icons.search, size: 16, color: AppColors.muted),
            SizedBox(width: 8),
            Text('Search topics…',
                style: TextStyle(fontSize: 12, color: AppColors.muted)),
          ]),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          children: _filters
              .map((f) => GestureDetector(
                    onTap: () => setState(() => _filter = f),
                    child: _chip(f, f == _filter),
                  ))
              .toList(),
        ),
        const SizedBox(height: 12),
        const Center(child: BannerAdWidget()),
        const SizedBox(height: 12),
        if (_loading)
          const Center(
              child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(
                      color: AppColors.accent, strokeWidth: 2)))
        else
          ...visible.map(_lessonRow),
        const SizedBox(height: 14),
        _gameCta(),
        const SizedBox(height: 14),
        _conceptCardsCta(),
      ],
    );
  }

  Widget _chip(String text, bool active) => Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: (active ? AppColors.accent : AppColors.muted)
              .withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: (active ? AppColors.accent : AppColors.muted)
                  .withValues(alpha: 0.2)),
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: active ? AppColors.accent : AppColors.muted)),
      );

  Widget _lessonRow(Lesson l) {
    final locked = l.status == LessonStatus.locked;
    final active = l.status == LessonStatus.active;
    final done = l.status == LessonStatus.done;

    Color numBg, numColor;
    String numText;
    if (done) {
      numBg = AppColors.up.withValues(alpha: 0.15);
      numColor = AppColors.up;
      numText = '✓';
    } else if (active) {
      numBg = AppColors.accent.withValues(alpha: 0.15);
      numColor = AppColors.accent;
      numText = '▶';
    } else {
      numBg = AppColors.dim;
      numColor = AppColors.muted;
      numText = '🔒';
    }

    return GestureDetector(
      onTap: locked
          ? null
          : () async {
              await context.push('/lesson', extra: l);
              if (mounted) _load();
            },
      child: Container(
        margin: const EdgeInsets.only(bottom: 7),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: active
              ? AppColors.accent.withValues(alpha: 0.04)
              : AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: active
                  ? AppColors.accent.withValues(alpha: 0.3)
                  : AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: numBg, borderRadius: BorderRadius.circular(8)),
              child: Text(numText,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: numColor)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.title,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: active
                              ? AppColors.accent
                              : locked
                                  ? AppColors.muted
                                  : AppColors.text)),
                  Text('${l.durationMin} min · ${l.category}',
                      style: const TextStyle(
                          fontSize: 9, color: AppColors.muted)),
                ],
              ),
            ),
            Text('+${l.xp} XP',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: locked ? AppColors.muted : AppColors.up)),
          ],
        ),
      ),
    );
  }

  Widget _gameCta() => GlassCard(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
        ),
        borderColor: AppColors.accent.withValues(alpha: 0.35),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.3)),
                  ),
                  child: const Text('MINI GAME',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          color: AppColors.accent)),
                ),
                const Text('+XP Rewards',
                    style: TextStyle(fontSize: 11, color: AppColors.up)),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Bull vs Bear: Chart Breakout Master 📈',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 4),
            const Text(
              'Practice technical price action and chart patterns under timed rounds!',
              style: TextStyle(
                  fontSize: 11, height: 1.4, color: AppColors.muted),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => context.push('/chart-game'),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('Play Chart Master Mini Game →',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.black)),
              ),
            ),
          ],
        ),
      );

  Widget _conceptCardsCta() => GlassCard(
        gradient: const LinearGradient(
            colors: [Color(0xFF120D24), Color(0xFF0C1628)]),
        borderColor: AppColors.purple.withValues(alpha: 0.25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: AppColors.purple.withValues(alpha: 0.25)),
                  ),
                  child: const Text('CONCEPT CARDS',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          color: AppColors.purple)),
                ),
                const Text('Swipe & learn',
                    style: TextStyle(fontSize: 11, color: AppColors.up)),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
                'Bite-sized concepts: P/E, EBITDA, Circuit Breakers and more.',
                style: TextStyle(
                    fontSize: 12, height: 1.5, color: AppColors.muted)),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => context.push('/concept-cards'),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                    color: AppColors.purple,
                    borderRadius: BorderRadius.circular(10)),
                child: const Text('Open Concept Cards →',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ),
          ],
        ),
      );
}
