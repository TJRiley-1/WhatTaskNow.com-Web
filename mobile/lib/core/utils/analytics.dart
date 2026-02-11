import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Analytics wrapper for Firebase Analytics + Crashlytics
class Analytics {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  static Future<void> logEvent(String name, [Map<String, dynamic>? params]) async {
    try {
      await _analytics.logEvent(name: name, parameters: params?.map(
        (key, value) => MapEntry(key, value is int ? value : value.toString()),
      ));
    } catch (_) {
      // Silently fail if Firebase not configured
    }
  }

  static Future<void> setUserId(String userId) async {
    try {
      await _analytics.setUserId(id: userId);
      await FirebaseCrashlytics.instance.setUserIdentifier(userId);
    } catch (_) {}
  }

  static Future<void> logScreenView(String screenName) async {
    try {
      await _analytics.logScreenView(screenName: screenName);
    } catch (_) {}
  }

  // Convenience methods for common events
  static Future<void> taskCreated(String type, int time) async {
    await logEvent('task_created', {'type': type, 'time': time});
  }

  static Future<void> taskCompleted(String type, int points) async {
    await logEvent('task_completed', {'type': type, 'points': points});
  }

  static Future<void> taskSkipped(String type) async {
    await logEvent('task_skipped', {'type': type});
  }

  static Future<void> swipeSessionStarted(int taskCount) async {
    await logEvent('swipe_session_started', {'task_count': taskCount});
  }

  static Future<void> importTasks(int count) async {
    await logEvent('import_tasks', {'count': count});
  }

  static Future<void> templateUsed(String templateName) async {
    await logEvent('template_used', {'name': templateName});
  }

  static Future<void> groupCreated() async {
    await logEvent('group_created');
  }

  static Future<void> groupJoined() async {
    await logEvent('group_joined');
  }

  static Future<void> premiumUpgrade(String type) async {
    await logEvent('premium_upgrade', {'type': type});
  }

  static Future<void> adViewed(String type) async {
    await logEvent('ad_viewed', {'type': type});
  }
}
