import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gallery_app/models/photo.dart';
import 'package:intl/intl.dart';

class NotificationsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> initializeNotifications() async {
    await AwesomeNotifications().initialize(
      null, // Icon for notification
      [
        NotificationChannel(
          channelKey: 'basic_channel',
          channelName: 'Basic notifications',
          channelDescription: 'Notification channel for basic tests',
        ),
      ],
      debug: true, // Set to false in production
    );

    // Request notification permissions
    await AwesomeNotifications().requestPermissionToSendNotifications();
  }

  Future<void> scheduleNotificationsForPhotos() async {
    DateTime now = DateTime.now();
    String currentDay = DateFormat('MM-dd').format(now);

    QuerySnapshot snapshot = await _firestore.collection('photos').get();
    List<Photo> photos = snapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      return Photo.fromFirestore(data, doc.id);
    }).toList();

    for (var photo in photos) {
      // Check if the photo's date matches today's month and day
      if (DateFormat('MM-dd').format(photo.timestamp) == currentDay) {
        // Schedule notification to trigger at the same time as when the photo was taken
        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: int.parse(photo.id),
            channelKey: 'basic_channel',
            title: 'Memory Lane',
            body: 'You took a photo on this day ${DateFormat('yyyy-MM-dd').format(photo.timestamp)}',
            notificationLayout: NotificationLayout.Default,
            payload: {'photoId': photo.id},
          ),
          schedule: NotificationCalendar(
            year: now.year, // This year
            month: photo.timestamp.month,
            day: photo.timestamp.day,
            hour: photo.timestamp.hour,
            minute: photo.timestamp.minute,
            second: 0,
            repeats: true, // Set to true if you want it to repeat yearly
          ),
          actionButtons: [
            NotificationActionButton(
              key: 'open',
              label: 'Open Photo',
            ),
          ],
        );
      }
    }
  }

  Future<void> sendNotification() async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 10,
        channelKey: 'basic_channel',
        title: "Test",
        body: 'This is a test notification',
        notificationLayout: NotificationLayout.Default,
      ),
    );
  }
}
