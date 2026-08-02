import 'package:firebase_analytics/firebase_analytics.dart';

/// Thin wrapper around FirebaseAnalytics. Every call is best-effort —
/// analytics must never crash or block a user-facing flow.
class AnalyticsService {
  final FirebaseAnalytics? _analytics;
  AnalyticsService(this._analytics);

  FirebaseAnalyticsObserver? get observer {
    final analytics = _analytics;
    return analytics == null
        ? null
        : FirebaseAnalyticsObserver(analytics: analytics);
  }

  Future<void> setUserId(String? id) =>
      _guard(() => _analytics?.setUserId(id: id));

  Future<void> logLogin(String method) =>
      _guard(() => _analytics?.logLogin(loginMethod: method));

  Future<void> logSignUp(String method) =>
      _guard(() => _analytics?.logSignUp(signUpMethod: method));

  Future<void> logLessonComplete(String lessonId, int xp) => _guard(() =>
      _analytics?.logEvent(name: 'lesson_complete', parameters: {
        'lesson_id': lessonId,
        'xp': xp,
      }));

  Future<void> logQuizComplete(int score, int total, int xp) => _guard(() =>
      _analytics?.logEvent(name: 'quiz_complete', parameters: {
        'score': score,
        'total': total,
        'xp': xp,
      }));

  Future<void> logPortfolioReset() =>
      _guard(() => _analytics?.logEvent(name: 'portfolio_reset'));

  Future<void> logAdRewardEarned(String placement) => _guard(() =>
      _analytics?.logEvent(
          name: 'ad_reward_earned', parameters: {'placement': placement}));

  Future<void> logEvent(String name, [Map<String, Object>? params]) =>
      _guard(() => _analytics?.logEvent(name: name, parameters: params));

  Future<void> _guard(Future<void>? Function() action) async {
    try {
      await action();
    } catch (_) {
      // Swallow — analytics is non-critical.
    }
  }
}
