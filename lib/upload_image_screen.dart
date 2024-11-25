import 'package:flutter/material.dart';
import 'dart:io';
import 'package:gallery_app/services/firestore_service.dart';
import 'package:gallery_app/services/storage_service.dart';
import 'package:gallery_app/services/image_picker_service.dart'; // Import the image picker service

class UploadImageScreen extends StatefulWidget {
  @override
  _UploadImageScreenState createState() => _UploadImageScreenState();
}

class _UploadImageScreenState extends State<UploadImageScreen> {
  File? _image;
  final StorageService _storageService = StorageService();
  final FirestoreService _firestoreService = FirestoreService();
  final ImagePickerService _imagePickerService = ImagePickerService(); // Instantiate the image picker service

  // Method to pick image from gallery
  Future<void> _pickImage() async {
    File? pickedImage = await _imagePickerService.pickImage(); // Use the service to pick an image

    if (pickedImage != null) {
      setState(() {
        _image = pickedImage;
      });
    }
  }

  // Method to upload image and save its URL to Firestore
 Future<void> _uploadImage() async {
  if (_image == null) {
 ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text("You should choose a picture first  "),
      backgroundColor: Colors.red,
    )
  );
  return;
  }
 

  try {
    // Upload the image to Firebase Storage and get the URL
    String imageUrl = await _storageService.uploadImage(_image!);

    // Now save the photo data to Firestore under a specific year
    String year = '2024'; // Example year, you can change this or make it dynamic
    await _firestoreService.addPhoto(year, {
      'url': imageUrl,
      'description': 'A sample photo uploaded via app',
      'timestamp': DateTime.now().toIso8601String(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Image uploaded successfully"),
        backgroundColor: Colors.green,
      )
    );

    print('Image uploaded and Firestore data saved successfully');
  } catch (e) {
    print('Error uploading image: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Error uploading images : $e"),
        backgroundColor: Colors.red,
      )
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Upload Image')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_image != null)
              Image.file(_image!, height: 150)
            else
              Text('No image selected'),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('Pick Image'),
            ),
            ElevatedButton(
              onPressed: _uploadImage,
              child: Text('Upload Image'),
            ),
          ],
        ),
      ),
    );
  }
}
