import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

import '../../data/datasources/local/hive_datasource.dart';
import '../../data/datasources/remote/supabase_datasource.dart';

/// Top-level handler required by FirebaseMessaging for background messages.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Show a local notification when a background message arrives.
  await NotificationService._showFromRemoteMessage(message);
}

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'whatnow_channel',
    'What Now? Reminders',
    description: 'Task reminders and overdue alerts',
    importance: Importance.high,
  );

  /// Initialize both FCM and local notifications.
  static Future<void> init() async {
    tz_data.initializeTimeZones();

    // --- Local notifications setup ---
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(initSettings);

    // Create the Android notification channel.
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // --- FCM setup ---
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  /// Request notification permissions from the user.
  static Future<bool> requestPermission() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  /// Retrieve the current FCM token.
  static Future<String?> getToken() async {
    return await FirebaseMessaging.instance.getToken();
  }

  /// Save the FCM token both locally (Hive) and remotely (Supabase profiles).
  static Future<void> saveToken(String userId) async {
    final token = await getToken();
    if (token == null) return;

    final hive = HiveDatasource();
    await hive.setSetting('fcm_token', token);

    final supabase = SupabaseDatasource();
    await supabase.updateProfile(userId, {'fcm_token': token});
  }

  /// Schedule two reminders for a task:
  ///   1. The day before the due date at 9 AM.
  ///   2. The day of the due date at 9 AM.
  ///
  /// Notification IDs are derived from [taskId.hashCode] so they can be
  /// cancelled later.  The day-before reminder uses the base hash; the day-of
  /// reminder uses the base hash + 1.
  static Future<void> scheduleTaskReminder(
    String taskId,
    String taskName,
    DateTime dueDate,
  ) async {
    final baseId = taskId.hashCode;

    final dayBefore = tz.TZDateTime(
      tz.local,
      dueDate.year,
      dueDate.month,
      dueDate.day - 1,
      9, // 9 AM
    );

    final dayOf = tz.TZDateTime(
      tz.local,
      dueDate.year,
      dueDate.month,
      dueDate.day,
      9, // 9 AM
    );

    final now = tz.TZDateTime.now(tz.local);

    final notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        channelDescription: _channel.description,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );

    // Day-before reminder
    if (dayBefore.isAfter(now)) {
      await _localNotifications.zonedSchedule(
        baseId,
        'Task Reminder',
        '$taskName is due tomorrow',
        dayBefore,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }

    // Day-of reminder
    if (dayOf.isAfter(now)) {
      await _localNotifications.zonedSchedule(
        baseId + 1,
        'Task Due Today',
        '$taskName is due today',
        dayOf,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  /// Cancel both reminders associated with [taskId].
  static Future<void> cancelReminder(String taskId) async {
    final baseId = taskId.hashCode;
    await _localNotifications.cancel(baseId);
    await _localNotifications.cancel(baseId + 1);
  }

  /// Cancel all scheduled and pending notifications.
  static Future<void> cancelAll() async {
    await _localNotifications.cancelAll();
  }

  /// Show an immediate notification alerting the user of an overdue task.
  static Future<void> showOverdueAlert(String taskName) async {
    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'whatnow_channel',
        'What Now? Reminders',
        channelDescription: 'Task reminders and overdue alerts',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      'Overdue Task',
      '$taskName is overdue!',
      notificationDetails,
    );
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Handle a foreground FCM message by displaying a local notification.
  static Future<void> _onForegroundMessage(RemoteMessage message) async {
    await _showFromRemoteMessage(message);
  }

  /// Display a local notification from a [RemoteMessage].
  static Future<void> _showFromRemoteMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'whatnow_channel',
        'What Now? Reminders',
        channelDescription: 'Task reminders and overdue alerts',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      notificationDetails,
    );
  }
}
