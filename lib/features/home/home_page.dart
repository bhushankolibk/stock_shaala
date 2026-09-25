import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/injection.dart';
import '../../core/services/ad_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/content_service.dart';
import '../../core/services/market_overview_service.dart';
import '../../core/services/progress_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/banner_ad_widget.dart';
import '../../data/models/quiz_model.dart';
import '../../data/models/quote_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Quote> _indices = [];
  List<Quote> _movers = [];
  QuizQuestion? _challenge;
  bool _loading = true;
  int? _selectedOption;
  int _streak = 0;
  int _xp = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final progress = sl<ProgressService>();
    _streak = await progress.registerDailyActivity();
    _xp = progress.xp;

    try {
      final overview = sl<MarketOverviewService>();
      final indices = await overview.fetchIndices();
      final stocks = await overview.fetchStockQuotes();
      stocks.sort((a, b) => b.changePercent.compareTo(a.changePercent));
      final challenge = await sl<ContentService>().dailyChallenge();
      final savedAnswer = sl<ProgressService>().dailyChallengeAnswer;
      if (!mounted) return;
      setState(() {
        _indices = indices;
        _movers = stocks.take(4).toList();
        _challenge = challenge;
        _selectedOption = savedAnswer;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = sl<AuthService>().currentUser;
    final name = user?.displayName?.split(' ').first ?? 'Learner';

    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.accent,
        backgroundColor: AppColors.card,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _header(name, user?.photoURL),
            const SizedBox(height: 14),
            _marketCard(),
            const SizedBox(height: 14),
            _gameBannerCard(),
            const SizedBox(height: 14),
            _quickHubSection(),
            const SizedBox(height: 14),
            if (_challenge != null) _challengeCard(_challenge!),
            const SizedBox(height: 14),
            _moversSection(),
            const SizedBox(height: 16),
            const Center(child: BannerAdWidget()),
          ],
        ),
      ),
    );
  }

  Widget _header(String name, String? photo) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.accent,
                backgroundImage: photo != null ? NetworkImage(photo) : null,
                child: photo == null
                    ? Text(name.substring(0, 1),
                        style: const TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold))
                    : null,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Namaste 👋',
                      style: TextStyle(fontSize: 11, color: AppColors.muted)),
                  Text(name,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          Row(
            children: [
              Pill('🔥 $_streak', AppColors.accent),
              const SizedBox(width: 4),
              Pill('⚡ $_xp XP', AppColors.up),
            ],
          ),
        ],
      );

  Widget _marketCard() => GlassCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('MARKET TODAY',
                    style: TextStyle(
                        fontSize: 10,
                        color: AppColors.muted,
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.bold)),
                GestureDetector(
                  onTap: _load,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.2)),
                    ),
                    child: Text('↻ Refresh',
                        style: AppTheme.mono(
                            size: 10, color: AppColors.accent)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_loading)
              const SizedBox(
                  height: 48,
                  child: Center(
                      child: CircularProgressIndicator(
                          color: AppColors.accent, strokeWidth: 2)))
            else if (_indices.isEmpty)
              const Text('Market data unavailable. Pull to refresh.',
                  style: TextStyle(fontSize: 11, color: AppColors.muted))
            else
              Row(
                children: _indices
                    .map((q) => Expanded(child: _indexChip(q)))
                    .toList(),
              ),
          ],
        ),
      );

  Widget _indexChip(Quote q) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
            color: AppColors.dim, borderRadius: BorderRadius.circular(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(q.name,
                style: const TextStyle(fontSize: 9, color: AppColors.muted),
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(q.price.toStringAsFixed(0),
                style: AppTheme.mono(
                    size: 12,
                    weight: FontWeight.w700,
                    color: q.isUp ? AppColors.up : AppColors.down)),
            Text('${q.isUp ? '▲' : '▼'} ${Fmt.pct(q.changePercent)}',
                style: AppTheme.mono(
                    size: 9,
                    color: q.isUp ? AppColors.up : AppColors.down)),
          ],
        ),
      );

  Widget _gameBannerCard() => GlassCard(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
        ),
        borderColor: AppColors.accent.withValues(alpha: 0.4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _tag('MINI GAME', AppColors.accent),
                const Spacer(),
                const Text('🔥 Hot',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accent)),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Bull vs Bear: Chart Master 📈',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 2),
            const Text(
              'Test technical chart breakout skills in 10-sec rounds!',
              style: TextStyle(
                  fontSize: 11, height: 1.3, color: AppColors.muted),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => context.push('/chart-game'),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradient,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_arrow_rounded,
                        color: Colors.black, size: 18),
                    SizedBox(width: 4),
                    Text(
                      'PLAY CHART MASTER NOW',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          color: Colors.black),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  /// Navigates to a Quick Features route, occasionally (every 5th tap
  /// across all tiles, see AdService.maybeShowQuickFeatureInterstitial)
  /// showing an interstitial first so it doesn't fire on every single tap.
  void _goToHub(String route) {
    final shown = sl<AdService>().maybeShowQuickFeatureInterstitial(
      onAdClosed: () {
        if (mounted) context.push(route);
      },
    );
    if (!shown) context.push(route);
  }

  Widget _quickHubSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick Features',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _hubTile(
                  title: 'Calculators',
                  subtitle: 'SIP, CAGR & Risk',
                  icon: Icons.calculate_outlined,
                  color: AppColors.blue,
                  onTap: () => _goToHub('/calculators'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _hubTile(
                  title: 'Concept Cards',
                  subtitle: 'Bite-sized Learn',
                  icon: Icons.style_outlined,
                  color: AppColors.purple,
                  onTap: () => _goToHub('/concept-cards'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _hubTile(
                  title: 'eBook Library',
                  subtitle: 'Free Stock PDFs',
                  icon: Icons.menu_book_rounded,
                  color: AppColors.accent,
                  onTap: () => _goToHub('/ebooks'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _hubTile(
                  title: 'Stock Universe',
                  subtitle: '100+ Live Quotes',
                  icon: Icons.show_chart_rounded,
                  color: AppColors.up,
                  onTap: () => _goToHub('/stock-list'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _hubTile(
                  title: 'Quiz Arena',
                  subtitle: 'Earn Bonus XP',
                  icon: Icons.quiz_outlined,
                  color: AppColors.purple,
                  onTap: () => _goToHub('/quiz'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _hubTile(
                  title: 'Compare Stocks',
                  subtitle: 'Side-by-side view',
                  icon: Icons.compare_arrows_rounded,
                  color: AppColors.blue,
                  onTap: () => _goToHub('/compare'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _hubTile(
                  title: 'Sector Screener',
                  subtitle: 'Filter by theme',
                  icon: Icons.filter_alt_outlined,
                  color: AppColors.down,
                  onTap: () => _goToHub('/screener'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _hubTile(
                  title: 'Rewards & Offers',
                  subtitle: 'Earn real cash',
                  icon: Icons.card_giftcard_rounded,
                  color: AppColors.up,
                  onTap: () => _goToHub('/rewards'),
                ),
              ),
            ],
          ),
        ],
      );

  Widget _hubTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 9, color: AppColors.muted),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _challengeCard(QuizQuestion q) => GlassCard(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF120D24), Color(0xFF0C1628)],
        ),
        borderColor: AppColors.purple.withValues(alpha: 0.25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _tag('DAILY CHALLENGE', AppColors.purple),
                const Text('+50 XP',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.up)),
              ],
            ),
            const SizedBox(height: 8),
            Text(q.question,
                style: const TextStyle(
                    fontSize: 12, height: 1.5, fontWeight: FontWeight.w500)),
            const SizedBox(height: 10),
            ...List.generate(q.options.length, (i) {
              final selected = _selectedOption == i;
              final isCorrect = i == q.correctIndex;
              final showResult = _selectedOption != null;
              Color border = Colors.white.withValues(alpha: 0.07);
              Color? bg = Colors.white.withValues(alpha: 0.03);
              Color textColor = AppColors.text;
              if (showResult && isCorrect) {
                border = AppColors.up.withValues(alpha: 0.4);
                bg = AppColors.up.withValues(alpha: 0.07);
                textColor = AppColors.up;
              } else if (showResult && selected && !isCorrect) {
                border = AppColors.down.withValues(alpha: 0.4);
                bg = AppColors.down.withValues(alpha: 0.07);
                textColor = AppColors.down;
              }
              return GestureDetector(
                onTap: showResult
                    ? null
                    : () async {
                        setState(() => _selectedOption = i);
                        final progress = sl<ProgressService>();
                        await progress.saveDailyChallengeAnswer(i);
                        if (isCorrect) {
                          await progress.addXp(50);
                          setState(() => _xp = progress.xp);
                        }
                      },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 5),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: border),
                  ),
                  child: Text(
                      '${showResult && isCorrect ? '✓ ' : ''}${q.options[i]}',
                      style: TextStyle(fontSize: 11, color: textColor)),
                ),
              );
            }),
          ],
        ),
      );

  Widget _moversSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Top Movers',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ..._movers.map((q) => GestureDetector(
                onTap: () => context.push('/stock',
                    extra: {'symbol': q.symbol, 'name': q.name}),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 11, vertical: 8),
                  decoration: BoxDecoration(
                      color: AppColors.dim,
                      borderRadius: BorderRadius.circular(11)),
                  child: Row(
                    children: [
                      TickerBadge(q.symbol, TickerBadge.colorFor(q.symbol)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(q.symbol,
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700)),
                            Text(q.name,
                                style: const TextStyle(
                                    fontSize: 10, color: AppColors.muted),
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(Fmt.money(q.price),
                              style: AppTheme.mono(size: 12)),
                          Text(
                              '${q.isUp ? '▲' : '▼'} ${Fmt.pct(q.changePercent)}',
                              style: AppTheme.mono(
                                  size: 10,
                                  color: q.isUp
                                      ? AppColors.up
                                      : AppColors.down)),
                        ],
                      ),
                    ],
                  ),
                ),
              )),
        ],
      );

  Widget _tag(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                color: color)),
      );
}
