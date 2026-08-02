import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

/// Local streak + XP engine (Duolingo-style). All on-device.
class ProgressService {
  final SharedPreferences prefs;
  ProgressService(this.prefs);

  static final _fmt = DateFormat('yyyy-MM-dd');

  int get xp => prefs.getInt(AppConstants.kTotalXp) ?? 0;
  int get streak => prefs.getInt(AppConstants.kStreakCount) ?? 0;

  Future<void> addXp(int amount) async {
    await prefs.setInt(AppConstants.kTotalXp, xp + amount);
  }

  /// Call on app open. Increments streak if consecutive day, resets if missed.
  Future<int> registerDailyActivity() async {
    final today = _fmt.format(DateTime.now());
    final last = prefs.getString(AppConstants.kLastActiveDate);

    if (last == today) return streak; // already counted today

    int newStreak;
    if (last == null) {
      newStreak = 1;
    } else {
      final lastDate = _fmt.parse(last);
      final diff = DateTime.now().difference(lastDate).inDays;
      newStreak = diff == 1 ? streak + 1 : 1;
    }

    await prefs.setInt(AppConstants.kStreakCount, newStreak);
    await prefs.setString(AppConstants.kLastActiveDate, today);
    return newStreak;
  }

  int get level => (xp ~/ 100) + 1;

  String get _today => _fmt.format(DateTime.now());

  int? get dailyChallengeAnswer {
    final date = prefs.getString(AppConstants.kDailyChallengeDate);
    if (date != _today) return null;
    final ans = prefs.getInt(AppConstants.kDailyChallengeAnswer);
    return ans;
  }

  Future<void> saveDailyChallengeAnswer(int selectedIndex) async {
    await prefs.setString(AppConstants.kDailyChallengeDate, _today);
    await prefs.setInt(AppConstants.kDailyChallengeAnswer, selectedIndex);
  }

  Set<String> get completedLessonIds =>
      (prefs.getStringList(AppConstants.kCompletedLessons) ?? []).toSet();

  Future<void> markLessonComplete(String lessonId) async {
    final ids = completedLessonIds..add(lessonId);
    await prefs.setStringList(AppConstants.kCompletedLessons, ids.toList());
  }

  /// Increments and returns the running count of lesson completions,
  /// used to frequency-cap interstitial ads (e.g. every 3rd completion).
  Future<int> incrementLessonCompletionCount() async {
    final count =
        (prefs.getInt(AppConstants.kLessonCompletionCount) ?? 0) + 1;
    await prefs.setInt(AppConstants.kLessonCompletionCount, count);
    return count;
  }
}
