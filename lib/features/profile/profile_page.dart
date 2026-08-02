import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/constants/app_constants.dart';
import '../../core/di/injection.dart';
import '../../core/services/ad_service.dart';
import '../../core/services/analytics_service.dart';
import '../../core/services/app_services.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/local_db_service.dart';
import '../../core/services/progress_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../features/simulation/portfolio_repository.dart';
import '../disclaimer/disclaimer_content.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _version = '';

  static const _badges = [
    (icon: '🥇', name: 'First Trade', unlocked: true),
    (icon: '🔥', name: '7-Day Streak', unlocked: true),
    (icon: '🧠', name: 'Quiz Master', unlocked: true),
    (icon: '💰', name: 'Profit ₹10K', unlocked: false),
    (icon: '📊', name: 'Chart Pro', unlocked: false),
  ];

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) {
        setState(() => _version = 'v${info.version}+${info.buildNumber}');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = sl<AuthService>().currentUser;
    final progress = sl<ProgressService>();
    final name = user?.displayName ?? 'Learner';
    final email = user?.email ?? '';

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          _hero(name, email, user?.photoURL, progress.level),
          const SizedBox(height: 14),
          _statsGrid(progress),
          const SizedBox(height: 18),
          const Text('BADGES',
              style: TextStyle(fontSize: 11, color: AppColors.muted)),
          const SizedBox(height: 8),
          _badgeGrid(),
          const SizedBox(height: 18),
          const Text('SETTINGS',
              style: TextStyle(fontSize: 11, color: AppColors.muted)),
          const SizedBox(height: 8),
          _settingsMenu(),
          const SizedBox(height: 18),
          if (_version.isNotEmpty)
            Center(
              child: Text('StockShaala $_version',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.muted)),
            ),
        ],
      ),
    );
  }

  Widget _hero(String name, String email, String? photo, int level) =>
      GlassCard(
        color: AppColors.card,
        gradient: const LinearGradient(
            colors: [Color(0xFF111E30), Color(0xFF0C1520)]),
        borderColor: AppColors.border2,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: AppColors.accent,
              backgroundImage: photo != null ? NetworkImage(photo) : null,
              child: photo == null
                  ? Text(name.substring(0, 1),
                      style: const TextStyle(
                          fontSize: 20,
                          color: Colors.black,
                          fontWeight: FontWeight.w700))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(email,
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.muted),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Pill('Level $level Trader', AppColors.accent),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _statsGrid(ProgressService p) {
    final stats = [
      (label: 'Total XP', value: '${p.xp}', color: AppColors.accent),
      (label: 'Day Streak', value: '🔥 ${p.streak}', color: AppColors.text),
      (label: 'Level', value: '${p.level}', color: AppColors.up),
    ];
    return Row(
      children: stats
          .map((s) => Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Text(s.value,
                          style: AppTheme.mono(
                              size: 16,
                              weight: FontWeight.w700,
                              color: s.color)),
                      const SizedBox(height: 3),
                      Text(s.label,
                          style: const TextStyle(
                              fontSize: 9, color: AppColors.muted)),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _badgeGrid() => Wrap(
        spacing: 7,
        runSpacing: 7,
        children: _badges
            .map((b) => Opacity(
                  opacity: b.unlocked ? 1 : 0.35,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Text(b.icon, style: const TextStyle(fontSize: 20)),
                        const SizedBox(height: 4),
                        Text(b.name,
                            style: const TextStyle(
                                fontSize: 9, color: AppColors.muted)),
                      ],
                    ),
                  ),
                ))
            .toList(),
      );

  Widget _settingsMenu() => ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            _menuRow(Icons.language, 'Language: हिंदी / English',
                onTap: _showLanguageDialog),
            _menuRow(Icons.notifications_outlined, 'Notifications',
                onTap: () => _toast('Notification settings coming soon')),
            _menuRow(Icons.refresh, 'Reset Virtual Portfolio',
                onTap: _confirmReset),
            _menuRow(Icons.system_update, 'Check for Update',
                onTap: () async {
              await AppServices.checkForUpdate();
              _toast('You are on the latest version');
            }),
            _menuRow(Icons.share_outlined, 'Share App',
                onTap: AppServices.shareApp),
            _menuRow(Icons.star_outline, 'Rate StockShaala',
                onTap: AppServices.requestReview),
            _menuRow(Icons.feedback_outlined, 'Send Feedback',
                onTap: AppServices.sendFeedback),
            _menuRow(Icons.description_outlined, 'Disclaimer & About',
                onTap: _showAbout),
            _menuRow(Icons.privacy_tip_outlined, 'Privacy Policy',
                onTap: () =>
                    AppServices.openUrl(AppConstants.privacyPolicyUrl)),
            _menuRow(Icons.delete_outline, 'Delete Account',
                color: AppColors.down, onTap: _confirmDelete),
            _menuRow(Icons.logout, 'Sign Out',
                color: AppColors.down, onTap: _confirmSignOut, isLast: true),
          ],
        ),
      );

  Widget _menuRow(IconData icon, String label,
          {Color color = AppColors.text,
          VoidCallback? onTap,
          bool isLast = false}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.card,
            border: isLast
                ? null
                : const Border(
                    bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: color)),
              ),
              Icon(Icons.chevron_right,
                  size: 18,
                  color: color == AppColors.down
                      ? AppColors.down
                      : AppColors.muted),
            ],
          ),
        ),
      );

  // ── Actions ──

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card2,
        title: const Text('Choose Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('हिंदी'),
              onTap: () {
                Navigator.pop(context);
                _toast('Language set to Hindi');
              },
            ),
            ListTile(
              title: const Text('English'),
              onTap: () {
                Navigator.pop(context);
                _toast('Language set to English');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmReset() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card2,
        title: const Text('Reset Virtual Portfolio?'),
        content: const Text(
          'This wipes all your virtual holdings and trade history, and '
          'restores your starting cash of ₹5,000. This cannot be undone.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final shown = sl<AdService>().showRewarded(
                onReward: () async {
                  await sl<PortfolioRepository>().reset();
                  await sl<AnalyticsService>().logPortfolioReset();
                  await sl<AnalyticsService>()
                      .logAdRewardEarned('portfolio_reset');
                  _toast('Portfolio reset to ₹5,000');
                },
              );
              if (!shown) {
                // No ad ready — don't block a core feature, reset directly.
                await sl<PortfolioRepository>().reset();
                await sl<AnalyticsService>().logPortfolioReset();
                _toast('Portfolio reset to ₹1,00,000');
              }
            },
            child: const Text('Reset',
                style: TextStyle(color: AppColors.down)),
          ),
        ],
      ),
    );
  }

  void _showAbout() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card2,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scroll) => SingleChildScrollView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.dim2,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Disclaimer & About',
                  style:
                      TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              const DisclaimerPoints(),
              const SizedBox(height: 4),
              const SebiNotice(),
            ],
          ),
        ),
      ),
    );
  }

  /// "Delete Account" — since the only identity is Google sign-in, we explain,
  /// wipe local sim data, attempt the Firebase delete, then log out.
  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card2,
        title: const Text('Delete Account?'),
        content: const Text(
          'This will remove your StockShaala data (XP, streak, virtual portfolio) '
          'from this device and sign you out.\n\n'
          'Since you sign in with Google, you can return any time by signing in '
          'again with the same Google account.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _performDelete();
            },
            child: const Text('Delete',
                style: TextStyle(color: AppColors.down)),
          ),
        ],
      ),
    );
  }

  Future<void> _performDelete() async {
    // 1. Wipe local simulation data.
    await sl<LocalDbService>().resetAll();
    // 2. Try to delete Firebase auth record; fall back to sign-out.
    try {
      await sl<AuthService>().deleteAccount();
    } catch (_) {
      await sl<AuthService>().signOut();
    }
    if (mounted) context.go('/login');
  }

  void _confirmSignOut() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card2,
        title: const Text('Sign Out?'),
        content: const Text(
            'Your progress is tied to your Google account and will be here '
            'when you sign back in.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await sl<AuthService>().signOut();
              if (mounted) context.go('/login');
            },
            child: const Text('Sign Out',
                style: TextStyle(color: AppColors.down)),
          ),
        ],
      ),
    );
  }
}

