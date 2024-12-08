import 'package:workmanager/workmanager.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import 'package:gallery_app/models/photo.dart';
import 'package:intl/intl.dart';
import 'package:gallery_app/main.dart';

void setupBackgroundTask() {
  Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
  Workmanager().registerPeriodicTask(
    'daily_memory_check',
    'checkForAnniversaries',
    frequency: const Duration(days: 1),
  );
}

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    List<Photo> photos = await getIt<FirestoreService>().fetchAllPhotos();
    checkForAnniversaries(photos);
    return Future.value(true);
  });
}

void checkForAnniversaries(List<Photo> photos) {
  final now = DateTime.now();
  final today = DateFormat('MM/dd').format(now);

  for (var photo in photos) {
    final photoDate = DateFormat('MM/dd').format(photo.timestamp);
    if (photoDate == today && photo.timestamp.year != now.year) {
      sendAnniversaryNotification(photo);
    }
  }
}
