import 'package:firebase_storage/firebase_storage.dart';
import 'package:gallery_app/main.dart';
import 'dart:io';
import 'package:path/path.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';


class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Method to compress image before uploading
  Future<File?> _compressImage(File file) async {
    final dir = Directory.systemTemp;
    final targetPath = '${dir.path}/${basename(file.path)}';

    var result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,  // Input file path
      targetPath,          // Output file path
      quality: 75,         // Adjust compression quality (0-100)
    );

    if (result == null) {
      return null;
    }

    return File(result.path);  // Convert XFile to File
  }

  // Method to upload image
  Future<String> uploadImage(File file) async {
    try {
      // Compress the image before upload
      File? compressedFile = await _compressImage(file);

      if (compressedFile == null) {
        throw Exception('Image compression failed');
      }

      // Generate a unique file name
      String fileName = basename(compressedFile.path);
      Reference storageRef = _storage.ref().child('photos/$fileName');

      // Upload the compressed file
      await storageRef.putFile(compressedFile);

      // Get the download URL after the file is uploaded
      String downloadURL = await storageRef.getDownloadURL();
      return downloadURL;
    } catch (e) {
      logger.e('Error uploading image: $e');
      throw Exception('Error uploading image');
    }
  }
}
