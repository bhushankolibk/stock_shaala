import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../di/injection.dart';
import '../services/analytics_service.dart';
import '../../features/splash/splash_page.dart';
import '../../features/disclaimer/disclaimer_page.dart';
import '../../features/onboarding/onboarding_page.dart';
import '../../features/auth/login_page.dart';
import '../../features/home/main_shell.dart';
import '../../features/learn/concept_cards_page.dart';
import '../../features/learn/lesson_detail_page.dart';
import '../../features/quiz/quiz_page.dart';
import '../../features/simulation/stock_detail_page.dart';
import '../../data/models/lesson_model.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashPage()),
      GoRoute(path: '/disclaimer', builder: (_, __) => const DisclaimerPage()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingPage()),
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/home', builder: (_, __) => const MainShell()),
      GoRoute(
          path: '/concept-cards',
          builder: (_, __) => const ConceptCardsPage()),
      GoRoute(path: '/quiz', builder: (_, __) => const QuizPage()),
      GoRoute(
        path: '/lesson',
        builder: (_, state) => LessonDetailPage(lesson: state.extra as Lesson),
      ),
      GoRoute(
        path: '/stock',
        builder: (_, state) {
          final args = state.extra as Map<String, dynamic>;
          return StockDetailPage(
            symbol: args['symbol'] as String,
            name: args['name'] as String,
          );
        },
      ),
    ],
    observers: [
      if (sl<AnalyticsService>().observer != null)
        sl<AnalyticsService>().observer!,
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Route error: ${state.error}')),
    ),
  );
}
