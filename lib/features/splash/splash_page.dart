import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/di/injection.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/disclaimer_service.dart';
import '../../core/services/app_services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_logo.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Check for Play Store update in the background (non-blocking).
    AppServices.checkForUpdate();

    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;

    final disclaimer = sl<DisclaimerService>();
    final auth = sl<AuthService>();
    final prefs = sl<DisclaimerService>().prefs;

    // 1. First ever launch -> full disclaimer (must accept).
    if (!disclaimer.hasAcceptedOnce) {
      context.go('/disclaimer');
      return;
    }

    // 2. Onboarding not done -> onboarding.
    if (!(prefs.getBool(AppConstants.kOnboardingDone) ?? false)) {
      context.go('/onboarding');
      return;
    }

    // 3. Not signed in -> login.
    if (auth.currentUser == null) {
      context.go('/login');
      return;
    }

    // 4. Signed in -> home.
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF060F1C), Color(0xFF0A1628), Color(0xFF060C18)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AppLogo(size: 84),
              const SizedBox(height: 20),
              const Text.rich(
                TextSpan(children: [
                  TextSpan(
                      text: 'Stock',
                      style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text)),
                  TextSpan(
                      text: 'Shaala',
                      style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent)),
                ]),
              ),
              const SizedBox(height: 8),
              Text(AppConstants.appTagline,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.muted)),
              const SizedBox(height: 40),
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.accent),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
