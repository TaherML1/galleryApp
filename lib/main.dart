import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:get_it/get_it.dart';
import 'services/firestore_service.dart';
import 'services/notification_service.dart';
import 'services/background_task_handler.dart'; // Import your background task handler
import 'views/timeline_view.dart';
import 'views/upload_image_screen.dart';
import 'package:gallery_app/views/homeScreen.dart';

final getIt = GetIt.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  getIt.registerLazySingleton(() => FirestoreService());

  // Initialize notifications and background tasks
  await initializeNotifications();
  setupBackgroundTask();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Photo Gallery App',
      theme: ThemeData(
        primarySwatch: Colors.purple,
      ),
      initialRoute: '/home',
      routes: {
        '/home': (context) => Homescreen(),
        '/upload': (context) => UploadImageScreen(),
        '/favorites': (context) => FavoriteScreen(),
       
      },
    );
  }
}
