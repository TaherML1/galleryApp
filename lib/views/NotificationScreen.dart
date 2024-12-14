import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:gallery_app/models/photo.dart';

class NotificationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Schedule Notification"),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Call the function to schedule notification after 5 seconds
            scheduleNotification();
          },
          child: Text("Show Notification After 5 Seconds"),
        ),
      ),
    );
  }

  // Function to schedule the notification after 5 seconds
  void scheduleNotification() {
    Future.delayed(Duration(seconds: 5), () {
      AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 10,
          channelKey: 'basic_channel',
          title: 'Reminder!',
          body: 'This notification appeared after 5 seconds.',
        ),
      );
    });
  }


  void scheduleMemoryNotification(Photo memoryPhoto) {
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 10, // Unique ID for the notification
        channelKey: 'basic_channel',
        title: 'Memory from ${memoryPhoto.year}!',
        body: 'Remember this? "${memoryPhoto.description}"',
        bigPicture: memoryPhoto.url, // Optional: show the photo in the notification
        notificationLayout: NotificationLayout.BigPicture, // Layout for showing image
      ),
    );
  }
}


