import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:gallery_app/models/photo.dart';
import 'package:gallery_app/services/firestore_service.dart';
// ignore: unused_import
import 'package:get_it/get_it.dart';
import 'package:gallery_app/main.dart';
class NotificationHandler {
  static void onActionReceivedMethod(ReceivedAction receivedAction) {
    if (receivedAction.actionType == ActionType.SilentAction ||
        receivedAction.actionType == ActionType.SilentBackgroundAction) {
      // Handle silent actions here
    } else {
      // Handle button actions here
      if (receivedAction.buttonKeyPressed == 'open') {
        // ignore: unused_local_variable
        String photoId = receivedAction.payload?['photoId'] as String;
        // Navigate to the photo screen with the photoId
     /*   Navigator.push(
          navigatorKey.currentState!.overlay!.context,
          MaterialPageRoute(
            builder: (context) => FullImageScreen(photoId: photoId),
          ),
        );*/
      }
    }
  }
}

class FullImageScreen extends StatelessWidget {
  final String photoId;

  FullImageScreen({required this.photoId});

  @override
  Widget build(BuildContext context) {
   final FirestoreService _firestoreService = getIt<FirestoreService>();
    return Scaffold(
      appBar: AppBar(
        title: Text('Photo'),
      ),
      body: FutureBuilder<Photo>(
        future: _firestoreService.fetchPhotoById(photoId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading photo.'));
          }
          if (!snapshot.hasData) {
            return Center(child: Text('No photo found.'));
          }

          final photo = snapshot.data!;

          return Center(
            child: Image.network(photo.url), // Use the appropriate method to load the image
          );
        },
      ),
    );
  }
}
