import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/firestore_service.dart';
import 'views/timeline_view.dart';
import 'views/upload_image_screen.dart';
import 'package:gallery_app/views/homeScreen.dart';
import 'package:gallery_app/views/IntroView.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gallery_app/views/NotificationScreen.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:gallery_app/services/firebaseMessaging.dart';
import 'package:logger/logger.dart';

var logger = Logger();
final getIt = GetIt.instance;
final FirestoreService _firestoreService = getIt<FirestoreService>();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    systemNavigationBarColor: Color(0xFF9c51b6), // Set the navigation bar color
    systemNavigationBarIconBrightness: Brightness.light, // Change the icon color to light (if the background is dark)
  ));

  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize FirestoreService
  getIt.registerLazySingleton(() => FirestoreService());

  //storeUserData();
  checkUserExistence();

  // Initialize Firebase Messaging
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Request permission for notifications
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    logger.i('User granted permission');
  } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
    logger.i('User granted provisional permission');
  } else {
    logger.e('User declined or has not accepted permission');
  }

  // Handle background messages
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Handle foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    logger.i('Got a message whilst in the foreground!');
    logger.i('Message data: ${message.data}');

    if (message.notification != null) {
      logger.i('Message also contained a notification: ${message.notification}');
    }
  });

  // Handle message opening
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  logger.i('Message clicked!');
  // Navigate to the NotificationScreen with the data
  navigatorKey.currentState?.pushNamed(
    '/notification',
    arguments: message.data,
  );
});


  // Check if the intro has been shown before
  final prefs = await SharedPreferences.getInstance();
  bool isFirstTime = prefs.getBool('first_time') ?? true;


  runApp(MyApp(isFirstTime: isFirstTime));
}



Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  logger.i("Handling a background message: ${message.messageId}");
}

Future<void> requestStoragePermission() async {
  // Check and request storage permission at runtime
  var status = await Permission.storage.request();

  if (status.isGranted) {
    logger.i('Storage permission granted');
  } else {
    logger.e('Storage permission denied');
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
      navigatorKey: navigatorKey,
      initialRoute: isFirstTime ? '/intro' : '/home',
      routes: {
        '/home': (context) => Homescreen(),
        '/upload': (context) => UploadImageScreen(),
        '/favorites': (context) => FavoriteScreen(),
        '/random': (context) => randomPictureWidget(),
        '/intro': (context) => IntroInfoWidget(),
        '/info': (context) => InfoPageWidget(),
        '/notification': (context) => NotificationScreen(data: ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>),
      },
    );
  }
}

