import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class Notifications {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  bool get initialized => _isInitialized;

  //init notifications
  Future<void> initNotification() async {
    //prevents multiple initializations
    if (_isInitialized) return;

    //init timezone handling
    tz.initializeTimeZones();
    final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(currentTimeZone));

    //android init settings
    const initSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    //ios init settings
    const initSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    //init settings
    const initSettings = InitializationSettings(
      android: initSettingsAndroid,
      iOS: initSettingsIOS,
    );

    //init plugin
    await flutterLocalNotificationsPlugin.initialize(initSettings);
  }

  //notif setup
  NotificationDetails notificationDetails() {
    return const NotificationDetails(
      //set up for android
      android: AndroidNotificationDetails(
        'daily_channel_id',
        'Daily Notifications',
        channelDescription: 'Daily Notification Channel',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  //show notif
  Future<void> showNotification({
    int id = 0,
    String? title,
    String? body,
  }) async {
    return flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      const NotificationDetails(),
    );
  }

  //method to schedule a notif
  Future<void> scheduleNotification({
    int id = 1,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    //get current date time in device's tz
    final now = tz.TZDateTime.now(tz.local);

    //create date time for today at specified time
    var scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    //schedule notif
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      notificationDetails(),

      //IOS settings to use specific time
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,

      //android settings for use in low power mode
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  //cancel notif
  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
