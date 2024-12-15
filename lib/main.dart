import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/firestore_service.dart';
import 'views/timeline_view.dart';
import 'views/upload_image_screen.dart';
import 'package:gallery_app/views/homeScreen.dart';
import 'package:gallery_app/services/notifications_service.dart';
import 'package:gallery_app/views/IntroView.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gallery_app/views/NotificationScreen.dart';
import 'package:workmanager/workmanager.dart';  // Import workmanager

final getIt = GetIt.instance;
final FirestoreService _firestoreService = getIt<FirestoreService>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize FirestoreService
  getIt.registerLazySingleton(() => FirestoreService());

  // Initialize notifications
  NotificationsService notificationsService = NotificationsService();
  await notificationsService.initializeNotifications();

  // Request storage permission
  await requestStoragePermission();

  // Check if the intro has been shown before
  final prefs = await SharedPreferences.getInstance();
  bool isFirstTime = prefs.getBool('first_time') ?? true;

  // Initialize WorkManager
  Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
  callbackDispatcher();

  // Register a one-off task to run every 1 minute
  Workmanager().registerOneOffTask(
    "10",
    "checkMemories",
    initialDelay: const Duration(minutes: 15), // Runs after 1 minute
  );

  runApp(MyApp(isFirstTime: isFirstTime));
  //FirestoreService().checkForMemoryAndScheduleNotification();
}

Future<void> requestStoragePermission() async {
  // Check and request storage permission at runtime
  var status = await Permission.storage.request();

  if (status.isGranted) {
    print('Storage permission granted');
  } else {
    print('Storage permission denied');
  }
}

class MyApp extends StatelessWidget {
  final bool isFirstTime;

  MyApp({super.key, required this.isFirstTime});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Photo Gallery App',
      theme: ThemeData(
        primarySwatch: Colors.purple,
      ),
      initialRoute: isFirstTime ? '/intro' : '/home',
      routes: {
        '/home': (context) => Homescreen(),
        '/upload': (context) => UploadImageScreen(),
        '/favorites': (context) => FavoriteScreen(),
        '/random': (context) => randomPictureWidget(),
        '/intro': (context) => IntroInfoWidget(),
        '/info': (context) => InfoPageWidget(),
        '/notification': (context) => NotificationScreen(),
      },
    );
  }
}

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print('Task triggered: $task');

    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    FirestoreService firestoreService = FirestoreService();

    // Call checkForMemoryAndScheduleNotification
    await firestoreService.checkForMemoryAndScheduleNotification();

    // Return true to indicate the task was successful
    return Future.value(true);
  });
}