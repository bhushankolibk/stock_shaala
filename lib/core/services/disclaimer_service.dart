import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

/// Controls the two disclaimer surfaces:
///  - Full screen, shown ONCE on first ever launch (must accept).
///  - Daily bottom-sheet reminder, shown once per calendar day.
class DisclaimerService {
  final SharedPreferences prefs;
  DisclaimerService(this.prefs);

  static final _fmt = DateFormat('yyyy-MM-dd');

  bool get hasAcceptedOnce =>
      prefs.getBool(AppConstants.kDisclaimerAccepted) ?? false;

  Future<void> acceptOnce() async {
    await prefs.setBool(AppConstants.kDisclaimerAccepted, true);
    await markShownToday();
  }

  bool get shouldShowDailyReminder {
    final today = _fmt.format(DateTime.now());
    return prefs.getString(AppConstants.kLastDisclaimerDate) != today;
  }

  Future<void> markShownToday() async {
    final today = _fmt.format(DateTime.now());
    await prefs.setString(AppConstants.kLastDisclaimerDate, today);
  }
}
