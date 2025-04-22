import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';

class Notifications {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  bool get initialized => _isInitialized;

  // Request runtime notification permission for Android 13+
  Future<void> requestPermission() async {
    final status = await Permission.notification.request();
    if (status.isDenied) {
      print('Notification permission denied');
    }
  }

  //init notifications
  Future<void> initNotification() async {
    try {
      //prevents multiple initializations
      if (_isInitialized) return;

      await requestPermission();

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

      //test start
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              'daily_channel_id',
              'Daily Notifications',
              description: 'Daily Notification Channel',
              importance: Importance.max,
            ),
          );

      //test end
      _isInitialized = true;
    } catch (e) {
      print('Error initializing notifications: $e');
    }
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
      notificationDetails(),
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

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

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

      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  //cancel notif
  Future<void> cancelNotifications(int id) async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
