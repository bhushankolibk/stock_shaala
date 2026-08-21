import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Must be a top-level (or static) function — handles messages received
/// while the app is fully terminated or in the background.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background FCM message: ${message.messageId}');
}

/// Wraps push-notification setup: permission request, token retrieval,
/// and foreground message handling. Notifications shown while the app is
/// backgrounded/terminated are displayed automatically by the OS using
/// the "notification" payload — no extra plugin needed for that case.
class MessagingService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  String? _token;
  String? get token => _token;

  /// Called once at startup, after Firebase.initializeApp().
  Future<void> init({
    required void Function(RemoteMessage message) onForegroundMessage,
    required void Function(RemoteMessage message) onMessageOpenedApp,
  }) async {
    try {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      _token = await _messaging.getToken();
      _messaging.onTokenRefresh.listen((t) => _token = t);

      // Lets notifications be sent to "all_users" as a real FCM topic send
      // instead of relying on Firebase Console's Analytics-based "All users"
      // targeting, which can take 24-48h to pick up new devices and skips
      // devices with limited Analytics data collection.
      await _messaging.subscribeToTopic('all_users');

      FirebaseMessaging.onMessage.listen(onForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(onMessageOpenedApp);
    } catch (e) {
      debugPrint('MessagingService init skipped/failed: $e');
    }
  }
}
