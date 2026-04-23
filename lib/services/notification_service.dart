import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/reminder.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onTap,
    );

    // Request permissions
    await Permission.notification.request();
    await Permission.scheduleExactAlarm.request();

    // Create notification channel with ALARM importance
    const channel = AndroidNotificationChannel(
      'sehati_alarms',
      'تنبيهات صحتي',
      description: 'تنبيهات قياس السكر والضغط والأدوية',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('alarm'), // uses phone alarm sound
      enableVibration: true,
      vibrationPattern: [0, 500, 200, 500, 200, 500],
      ledColor: Color(0xFF0f4c75),
      enableLights: true,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static void _onTap(NotificationResponse response) {
    // App handles navigation when opened from notification
  }

  // ── SCHEDULE DAILY REMINDER ──
  static Future<void> scheduleReminder(Reminder r) async {
    await cancelReminder(r.notifId);
    if (!r.enabled) return;

    final parts = r.time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local, now.year, now.month, now.day, hour, minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final isGlucose = r.type == 'glucose';
    final title = isGlucose ? '🩸 حان وقت قياس السكر' : '💉 حان وقت قياس الضغط';
    final body = '${r.label} — ${r.time}';
    final color = isGlucose ? 0xFFb71c1c : 0xFF1a237e;

    await _plugin.zonedSchedule(
      r.notifId,
      title,
      body,
      scheduled,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'sehati_alarms',
          'تنبيهات صحتي',
          channelDescription: 'تنبيهات قياس السكر والضغط',
          importance: Importance.max,
          priority: Priority.max,
          sound: const RawResourceAndroidNotificationSound('alarm'),
          playSound: true,
          enableVibration: true,
          vibrationPattern: [0, 500, 200, 500, 200, 500],
          color: Color(color),
          icon: '@mipmap/ic_launcher',
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          styleInformation: BigTextStyleInformation(body),
          category: AndroidNotificationCategory.alarm,
          fullScreenIntent: true, // Shows on lock screen
          ongoing: false,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'default',
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repeats daily
    );
  }

  static Future<void> cancelReminder(int id) =>
      _plugin.cancel(id);

  static Future<void> scheduleAllReminders(List<Reminder> reminders) async {
    for (final r in reminders) {
      await scheduleReminder(r);
    }
  }

  static Future<void> cancelAll() => _plugin.cancelAll();

  // ── TEST NOTIFICATION (immediate) ──
  static Future<void> testNow(String type) async {
    final isGlucose = type == 'glucose';
    await _plugin.show(
      999,
      isGlucose ? '🩸 اختبار — قياس السكر' : '💉 اختبار — قياس الضغط',
      'هكذا سيظهر التنبيه عند حلول الموعد',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'sehati_alarms', 'تنبيهات صحتي',
          importance: Importance.max,
          priority: Priority.max,
          sound: RawResourceAndroidNotificationSound('alarm'),
          playSound: true,
          enableVibration: true,
          vibrationPattern: [0, 500, 200, 500],
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
        ),
      ),
    );
  }
}
