import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import '../../models/photo.dart';
import 'dart:math';
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Logger _logger = Logger();

 // NotificationScreen notificationScreen = new NotificationScreen();
  Future<List<String>> fetchYears() async {
    try {
      QuerySnapshot snapshot = await _db.collection('photos').get();
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      _logger.e('Error fetching years: $e');
      return [];
    }
  }

  Stream<List<Photo>> fetchPhotosStream(String year) {
    return _db
        .collection('photos')
        .doc(year)
        .collection('photos')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Photo.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Future<void> addPhoto(String year, Map<String, dynamic> photoData) async {
    try {
      await _db
          .collection('photos')
          .doc(year)
          .collection('photos')
          .add(photoData);
      _logger.i('Photo added for year $year');
    } catch (e) {
      _logger.e('Error adding photo: $e');
    }
  }

  Future<void> deletePhoto(String year, String photoId, String imageUrl) async {
    try {
      await _db
          .collection('photos')
          .doc(year)
          .collection('photos')
          .doc(photoId)
          .delete();
      _logger.i('Photo metadata deleted from Firestore.');

       Reference photoRef = _storage.refFromURL(imageUrl);
    await photoRef.delete();
    

      _logger.i("Photo deleted from Firebase Storage");
    } catch (e) {
      _logger.e('Error deleting photo: $e');
    }
  }

  // Update the favorite status of a photo
  Future<void> updateFavoriteStatus(String year, String photoId, bool isFavorite) async {
    try {
      await _db
          .collection('photos')
          .doc(year)
          .collection('photos')
          .doc(photoId)
          .update({'favorite': isFavorite});
      _logger.i('Favorite status updated for photo $photoId in year $year');
    } catch (e) {
      _logger.e('Error updating favorite status: $e');
    }
  }


  Future<void> updatePhotoDescription(String year , String photoId , String newDescription) async{
    try{
      await _db 
      .collection('photos')
      .doc(year)
      .collection('photos')
      .doc(photoId)
      .update({'description' : newDescription});
      _logger.i('new Descitpion updated for photo $photoId in year $year');
    }catch(e){
      _logger.e('Error updating description status : $e');
    }

  }

Future<List<Photo>> fetchAllFavoritePhotos() async {
  try {
    // Log the start of the process
    _logger.i('Starting to fetch all favorite photos from Firestore');

    // Log the execution of the query
    _logger.d('Executing query to fetch photos where "favorite" is true...');
    QuerySnapshot snapshot = await _db
        .collectionGroup('photos')
        .where('favorite', isEqualTo: true)
        .get();

    // Log how many documents were returned by the query
    _logger.i('Query successful, found ${snapshot.docs.length} favorite photos');

    // Log if no photos were found
    if (snapshot.docs.isEmpty) {
      _logger.w('No favorite photos found.');
    }

    // Mapping Firestore documents to the Photo model with logging for each document
    List<Photo> favoritePhotos = snapshot.docs.map((doc) {
      // Log the document ID being mapped
      _logger.d('Mapping photo with document ID: ${doc.id}');
      
      // Log the fields of the document for debugging
      _logger.v('Document fields: ${doc.data()}');

      // Map Firestore document to Photo model
      return Photo.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
    }).toList();

    // Log the number of successfully mapped photos
    _logger.i('Successfully mapped ${favoritePhotos.length} photos to the model');

    return favoritePhotos;
  } catch (e) {
    // Log the error and stack trace for debugging purposes
    _logger.e('Error fetching favorite photos: $e'  );
    return [];
  }
}

// method to fetch photos for notifications
Future<List<Photo>> fetchAllPhotos() async {
  try {
    _logger.i('Starting to fetch all photos from Firestore');

    QuerySnapshot snapshot = await _db
        .collectionGroup('photos')  // Fetch from all "photos" collections across documents
        .get();

    _logger.i('Query successful, found ${snapshot.docs.length} photos');

    if (snapshot.docs.isEmpty) {
      _logger.w('No photos found.');
    }

    List<Photo> allPhotos = snapshot.docs.map((doc) {
      _logger.d('Mapping photo with document ID: ${doc.id}');
      _logger.v('Document fields: ${doc.data()}');

      return Photo.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
    }).toList();

    _logger.i('Successfully mapped ${allPhotos.length} photos to the model');

    return allPhotos;
  } catch (e) {
    _logger.e('Error fetching photos: $e');
    return [];
  }
}
Future<Photo?> fetchRandomPhotoFromAllYears() async {
  try {
    // Fetch all the years
    QuerySnapshot yearsSnapshot = await _db.collection('photos').get();

    if (yearsSnapshot.docs.isEmpty) {
      _logger.w('No years found.');
      return null;
    }

    List<DocumentSnapshot> allPhotos = [];

    // Fetch all the photos for each year
    for (var yearDoc in yearsSnapshot.docs) {
      QuerySnapshot photosSnapshot = await yearDoc.reference.collection('photos').get();
      allPhotos.addAll(photosSnapshot.docs);
    }

    if (allPhotos.isEmpty) {
      _logger.w('No photos found.');
      return null;
    }

    // Get a random document from the combined list of photos
    int randomIndex = (allPhotos.length * Random().nextDouble()).floor();
    var randomDoc = allPhotos[randomIndex];

    // Map Firestore document to Photo model
    return Photo.fromFirestore(randomDoc.data() as Map<String, dynamic>, randomDoc.id);
  } catch (e) {
    _logger.e('Error fetching random photo: $e');
    return null;
  }

}

 Future<Photo> fetchPhotoById(String photoId) async {
    DocumentSnapshot doc = await _db.collection('photos').doc(photoId).get();
    if (doc.exists) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      return Photo.fromFirestore(data, photoId);
    } else {
      throw Exception('Photo not found');
    }
  }


Future<List<Photo>> checkForMemory() async {
    // Get today's date (month and day)
    DateTime today = DateTime.now();
    String todayMonthDay = DateFormat('MM-dd').format(today);

    // Log the current date being checked
    _logger.i('Checking for photos from previous years taken on: $todayMonthDay');

    try {
      // Query Firestore for documents by year
      QuerySnapshot snapshot = await _db.collection('photos').get();

      // Log the number of years documents retrieved from Firestore
      _logger.i('Found ${snapshot.docs.length} year documents in Firestore.');

      // Iterate through each year document
      List<Photo> sameDayPhotos = [];
      for (var yearDoc in snapshot.docs) {
        // Get the photos subcollection for each year
        QuerySnapshot yearPhotosSnapshot = await _db
            .collection('photos')
            .doc(yearDoc.id)
            .collection('photos')
            .get();

        _logger.i('Found ${yearPhotosSnapshot.docs.length} photos in year ${yearDoc.id}.');

        // Iterate through the photos in each year
        for (var photoDoc in yearPhotosSnapshot.docs) {
          Photo photo = Photo.fromFirestore(photoDoc.data() as Map<String, dynamic>, photoDoc.id);
          String photoMonthDay = DateFormat('MM-dd').format(photo.timestamp);

          // Log the photo's date and comparison with today's date
          _logger.d('Checking photo taken on: $photoMonthDay');

          // Check if the photo was taken on the same day (regardless of year)
          if (photoMonthDay == todayMonthDay && photo.timestamp.year < today.year) {
            sameDayPhotos.add(photo);
            _logger.i('Found a matching photo from year ${photo.timestamp.year} for today.');
          }
        }
      }

      // If we found any photos from the same day in previous years, schedule a notification
      if (sameDayPhotos.isNotEmpty) {
        // Choose the first photo (or you could let the user choose from the list)
        Photo memoryPhoto = sameDayPhotos.first;

        // Log the memory photo to be used for the notification
        _logger.i('Scheduling memory notification for photo taken on ${memoryPhoto.timestamp.year}.');

        // Return the list of sameDayPhotos
        return sameDayPhotos;
      } else {
        _logger.w("No memory found for today from previous years.");
        return [];
      }
    } catch (e) {
      // Log any error that occurs during the process
      _logger.e('Error checking for memory: $e');
      return [];
    }
  }
}