import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/photo.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Fetch list of years (i.e., document IDs)
  Future<List<String>> fetchYears() async {
    try {
      // Get all documents in the 'photos' collection where each document represents a year
      QuerySnapshot snapshot = await _db.collection('photos').get();

      // Extract the document IDs (years) and return them
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      print('Error fetching years: $e');
      return [];
    }
  }

  // Fetch photos for a specific year
  // Fetch photos for a specific year
Future<List<Photo>> fetchPhotos(String year) async {
  try {
    print('Fetching photos for year $year...'); // Log function entry

    QuerySnapshot snapshot = await _db
        .collection('photos')
        .doc(year)
        .collection('photos')
        .orderBy('timestamp', descending: true)
        .get();
        

    if (snapshot.docs.isEmpty) {
      print('No photos found for year $year');
    } else {
      print('Retrieved ${snapshot.docs.length} documents from Firestore');
    }

    // Log each document's data
    List<Photo> photos = snapshot.docs.map((doc) {
      print('Document data: ${doc.data()}'); // Print Firestore data
      return Photo.fromFirestore(doc.data() as Map<String, dynamic>);
    }).toList();

    print('Fetched ${photos.length} photos for year $year');
    return photos;
  } catch (e) {
    print('Error fetching photos for year $year: $e');
    return [];
  }
}



  // Add a photo to a specific year
  Future<void> addPhoto(String year, Map<String, dynamic> photoData) async {
    try {
      
      await _db
          .collection('photos')  // Root collection
          .doc(year)             // Document for the year
          .collection('photos')  // Subcollection for photos
          .add(photoData);

      print('Photo added for year $year');
    } catch (e) {
      print('Error adding photo: $e');
    }
  }
}
