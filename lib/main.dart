import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:gallery_app/views/timeline_view.dart';  
import 'package:gallery_app/upload_image_screen.dart';  

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Photo Timeline App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
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
