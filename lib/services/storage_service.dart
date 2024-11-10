// lib/services/storage_service.dart
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:path/path.dart';  // To extract file name from path

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Method to upload image
  Future<String> uploadImage(File file) async {
    try {
      // Generate a unique file name
      String fileName = basename(file.path);  // Use the file's original name
      Reference storageRef = _storage.ref().child('photos/$fileName');

      // Upload the file
      await storageRef.putFile(file);

      // Get the download URL after the file is uploaded
      String downloadURL = await storageRef.getDownloadURL();
      return downloadURL;
    } catch (e) {
      print('Error uploading image: $e');
      throw Exception('Error uploading image');
    }
  }
}
