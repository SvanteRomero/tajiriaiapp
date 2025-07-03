import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final StreamController<String?> onNotificationTap =
      StreamController.broadcast();

  Future<void> initialize(GlobalKey<NavigatorState> navigatorKey) async {
    // Request permission from the user for Firebase Messaging
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Initialize flutter_local_notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();
    const InitializationSettings initializationSettings =
        InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS);
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        onNotificationTap.add(response.payload);
      },
    );

    // Get the FCM token for this device for debugging or direct messaging.
    final token = await _firebaseMessaging.getToken();
    print("FCM Token: $token");

    // Handle incoming messages while the app is in the foreground.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in theforeground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
        showNotification(
          title: message.notification?.title ?? 'No Title',
          body: message.notification?.body ?? 'No Body',
          // FIX: Safely handle the payload, providing a default value if null.
          payload: message.data['payload'] ?? 'default_payload',
        );
      }
    });

    // Handle notification taps when the app is in the background or terminated.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      onNotificationTap.add(message.data['payload']);
    });
  }

  Future<void> subscribeToUserTopic(String userId) async {
    await _firebaseMessaging.subscribeToTopic(userId);
    print('Subscribed to topic: $userId');
  }

  Future<void> unsubscribeFromUserTopic(String userId) async {
    await _firebaseMessaging.unsubscribeFromTopic(userId);
    print('Unsubscribed from topic: $userId');
  }

  /// Displays a local notification.
  Future<void> showNotification({
    required String title,
    required String body,
    required String payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'your_channel_id', // This should be unique
      'your_channel_name',
      channelDescription: 'your_channel_description',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecond, // Use a unique ID to show multiple notifications
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  /// Schedules the daily reminder to log expenses.
  Future<void> scheduleDailyReminderNotification() async {
    try {
      final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation(currentTimeZone));

      final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
      // Schedule for 8 PM (20:00) in the user's local time.
      tz.TZDateTime scheduledDate =
          tz.TZDateTime(tz.local, now.year, now.month, now.day, 20);

      // If it's already past 8 PM today, schedule for tomorrow.
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        1, // A static ID for the daily reminder so it overwrites itself.
        'Friendly Reminder',
        'Don\'t forget to log your expenses for today!',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_reminder_channel',
            'Daily Reminder',
            channelDescription: 'A reminder to log your daily expenses.',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        //LocalNotificationDateInterpretation:
            //calNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'add_transaction',
      );
    } catch (e) {
      print("Error scheduling daily reminder: $e");
    }
  }
}