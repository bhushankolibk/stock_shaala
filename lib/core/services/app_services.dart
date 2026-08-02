import 'package:in_app_update/in_app_update.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_constants.dart';

/// Wraps Play Store update, in-app review, share, and feedback email.
class AppServices {
  // ── In-app update (Android, Play Store) ──
  static Future<void> checkForUpdate() async {
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        // Flexible update lets the user keep using the app while it downloads.
        if (info.flexibleUpdateAllowed) {
          await InAppUpdate.startFlexibleUpdate();
          await InAppUpdate.completeFlexibleUpdate();
        } else if (info.immediateUpdateAllowed) {
          await InAppUpdate.performImmediateUpdate();
        }
      }
    } catch (_) {
      // Silently ignore (e.g. not installed from Play Store / debug build).
    }
  }

  // ── In-app review ──
  static Future<void> requestReview() async {
    final review = InAppReview.instance;
    if (await review.isAvailable()) {
      await review.requestReview();
    } else {
      await review.openStoreListing(appStoreId: AppConstants.playStoreId);
    }
  }

  // ── Share app ──
  static Future<void> shareApp() async {
    await SharePlus.instance.share(
      ShareParams(
        text: 'StockShaala — शेयर बाज़ार आसान भाषा में सीखें 📈\n\n'
            'Free educational app with virtual trading practice.\n'
            '${AppConstants.playStoreUrl}',
        subject: 'Learn the stock market with StockShaala',
      ),
    );
  }

  // ── Feedback via Play Store review ──
  static Future<void> sendFeedback() async {
    final review = InAppReview.instance;
    if (await review.isAvailable()) {
      await review.requestReview();
    } else {
      await review.openStoreListing(appStoreId: AppConstants.playStoreId);
    }
  }

  static Future<void> openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

}
