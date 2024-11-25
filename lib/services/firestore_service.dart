import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:logger/logger.dart';
import '../../models/photo.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Logger _logger = Logger();

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
}
