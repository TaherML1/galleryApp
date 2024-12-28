import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:gallery_app/views/LottieExample.dart';
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
import 'package:gallery_app/views/LottieExample.dart';

var logger = Logger();
final getIt = GetIt.instance;
final FirestoreService _firestoreService = getIt<FirestoreService>();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    systemNavigationBarColor: Color(0xFF9c51b6),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize FirestoreService
  getIt.registerLazySingleton(() => FirestoreService());

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

  // Handle message opening (when the app is running or in the background)
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    logger.i('Message clicked!');
    navigatorKey.currentState?.pushNamed(
      '/notification',
      arguments: message.data,
    );
  });

  // Check for the initial message if the app was launched by a notification
  RemoteMessage? initialMessage = await messaging.getInitialMessage();

  // Check if the intro has been shown before
  final prefs = await SharedPreferences.getInstance();
  bool isFirstTime = prefs.getBool('first_time') ?? true;

  runApp(MyApp(isFirstTime: isFirstTime, initialMessage: initialMessage?.data));
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
  final Map<String, dynamic>? initialMessage;

  const MyApp({super.key, required this.isFirstTime, this.initialMessage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Photo Gallery App',
      theme: ThemeData(
        primarySwatch: Colors.purple,
         fontFamily: 'SanFrancisco',
      ),
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: scaffoldMessengerKey,
      initialRoute: isFirstTime ? '/intro' : '/home',
      routes: {
        '/home': (context) => Homescreen(),
        '/upload': (context) => UploadImageScreen(),
        '/favorites': (context) => FavoriteScreen(),
        '/random': (context) => randomPictureWidget(),
        '/intro': (context) => IntroInfoWidget(),
        '/animation': (context) =>AnimationScreen(),
        '/info': (context) => InfoPageWidget(),
        '/notification': (context) => NotificationScreen(
          data: ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>,
        ),
      },
      onGenerateRoute: (settings) {
        if (initialMessage != null) {
          // Delay navigation to the NotificationScreen by 3 seconds
          Future.delayed(Duration(seconds: 3), () {
            scaffoldMessengerKey.currentState?.showSnackBar(
              SnackBar(
                content: Text('Navigating to Notification Screen...'),
                duration: Duration(seconds: 2),
              ),
            );
            navigatorKey.currentState?.pushNamed(
              '/notification',
              arguments: initialMessage,
            );
          });
        }
        return null;
      },
    );
  }
}
