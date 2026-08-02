import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/injection.dart';
import '../../core/services/analytics_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_logo.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _loading = false;

  static const _features = [
    (icon: '✅', bg: Color(0x1A00C896), text: '50+ modules in Hindi & English'),
    (icon: '🔥', bg: Color(0x1AF5A623), text: 'Daily challenges with streaks'),
    (
      icon: '📈',
      bg: Color(0x1A8A5CF5),
      text: 'Virtual portfolio, real NSE prices'
    ),
    (icon: '🎯', bg: Color(0x1A3B82F6), text: 'Quizzes, badges & XP'),
  ];

  Future<void> _signIn() async {
    setState(() => _loading = true);
    try {
      final user = await sl<AuthService>().signInWithGoogle();
      if (!mounted) return;
      if (user != null) {
        final analytics = sl<AnalyticsService>();
        await analytics.setUserId(user.uid);
        await analytics.logLogin('google');
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign-in failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 28),
          child: Column(
            children: [
              const Center(child: AppLogo(size: 60)),
              const SizedBox(height: 16),
              const Text.rich(
                TextSpan(children: [
                  TextSpan(text: 'StockShaala में '),
                  TextSpan(
                      text: 'स्वागत',
                      style: TextStyle(color: AppColors.accent)),
                  TextSpan(text: ' है'),
                ]),
                textAlign: TextAlign.center,
                style:
                    TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              const Text('Sign in to save progress,\nstreaks & virtual portfolio',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12, height: 1.6, color: AppColors.muted)),
              const SizedBox(height: 30),
              _GoogleButton(loading: _loading, onTap: _signIn),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.border)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: const Text('FREE FOREVER',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.muted)),
                  ),
                  const Expanded(child: Divider(color: AppColors.border)),
                ],
              ),
              const SizedBox(height: 22),
              for (final f in _features)
                Padding(
                  padding: const EdgeInsets.only(bottom: 11),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            color: f.bg,
                            borderRadius: BorderRadius.circular(8)),
                        child:
                            Text(f.icon, style: const TextStyle(fontSize: 13)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(f.text,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.muted)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;
  const _GoogleButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border2, width: 1.5),
        ),
        child: loading
            ? const Center(
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.accent)))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/search.png', width: 22, height: 22),
                  const SizedBox(width: 10),
                  const Text('Continue with Google',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
      ),
    );
  }
}
