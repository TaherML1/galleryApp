import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gallery_app/main.dart';

// Get Firebase Messaging instance
FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
late SharedPreferences _prefs;

// Generate a unique user ID (using UUID in this case)
String userId = Uuid().v4();

Future<void> checkUserExistence() async {
  _prefs = await SharedPreferences.getInstance();
  bool? userExist = _prefs.getBool("user_Exist") ?? false; // Check if the user exists, default to false if null
  
  if (!userExist) {
    logger.i("User does not exist. Storing user data...");
    await storeUserData();
    
    // After storing user data, set the flag to true to avoid future duplicate entries
    await _prefs.setBool("user_Exist", true);
  } else {
    logger.i("User already exists. No need to store data.");
  }
}

// Store user data in Firestore
Future<void> storeUserData() async {
  logger.i("Storing user data...");

  // Get the FCM token
  String? fcmToken = await _firebaseMessaging.getToken();
  
  if (fcmToken != null) {
    // Store user data in Firestore
    await FirebaseFirestore.instance.collection('users').doc(userId).set({
      'fcmToken': fcmToken,
      'userId': userId,
      'createdAt': FieldValue.serverTimestamp(),
    }).then((_) {
      logger.i('User data stored successfully!');
    }).catchError((error) {
      logger.e('Error storing user data: $error');
    });
  } else {
    logger.e('FCM token is null, cannot store user data.');
  }
}
