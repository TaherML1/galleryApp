import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gallery_app/services/firestore_service.dart';
import 'package:gallery_app/models/photo.dart';  // Import your Firestore service

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> initializeNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

Future<void> sendAnniversaryNotification(Photo photo) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  String todayKey = DateFormat('MM_dd_yyyy').format(DateTime.now());
  bool hasSentNotification = prefs.getBool(todayKey) ?? false;

  if (!hasSentNotification) {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'memory_channel', 'Memories',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      photo.id.hashCode,  // Use hashCode as the ID (ensure it's an int)
      'Memory from ${DateFormat.yMMMMd().format(photo.timestamp)}',  // Title
      'Check out a photo you took on this day!',  // Body
      notificationDetails,  // Named argument for notification details
    );

    await prefs.setBool(todayKey, true);
  }
}
