import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:gallery_app/views/timeline_view.dart';  
import 'package:gallery_app/views/upload_image_screen.dart';  
import 'package:get_it/get_it.dart';
import 'package:gallery_app/services/firestore_service.dart';

final getIt = GetIt.instance;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  getIt.registerLazySingleton(() => FirestoreService());

  runApp(MyApp());
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
       // scaffoldBackgroundColor: const Color.fromARGB(239, 231, 135, 251),
      ),
      // Define routes for easy navigation
      initialRoute: '/timeline',  // This is the initial screen that will be shown
      routes: {
        '/timeline': (context) => TimelineView(),  // The timeline view screen
        '/upload': (context) => UploadImageScreen(),  // The upload image screen
      },
    );
  }
}
