import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Add this import
import 'services/firestore_service.dart';
import 'views/timeline_view.dart';
import 'views/upload_image_screen.dart';
import 'package:gallery_app/views/homeScreen.dart';
import 'package:gallery_app/services/notifications_service.dart';
import 'package:gallery_app/views/IntroView.dart';

final getIt = GetIt.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  getIt.registerLazySingleton(() => FirestoreService());

  NotificationsService notificationsService = NotificationsService();
  await notificationsService.initializeNotifications();

  // Check if the intro has been shown before
  final prefs = await SharedPreferences.getInstance();
  bool isFirstTime = prefs.getBool('first_time') ?? true;

  runApp(MyApp(isFirstTime: isFirstTime));
}

class MyApp extends StatelessWidget {
  final bool isFirstTime;

  const MyApp({super.key, required this.isFirstTime});

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
        '/info' : (context) =>InfoPageWidget()
      },
    );
  }
}
