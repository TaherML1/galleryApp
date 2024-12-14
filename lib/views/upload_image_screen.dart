import 'package:flutter/material.dart';
import 'dart:io';
import 'package:gallery_app/services/firestore_service.dart';
import 'package:gallery_app/services/storage_service.dart';
import 'package:gallery_app/services/image_picker_service.dart'; 
import 'package:gallery_app/main.dart';
class UploadImageScreen extends StatefulWidget {
  @override
  _UploadImageScreenState createState() => _UploadImageScreenState();
}

class _UploadImageScreenState extends State<UploadImageScreen> {
  File? _image;
  final StorageService _storageService = StorageService();
  final FirestoreService _firestoreService = getIt<FirestoreService>();
  final ImagePickerService _imagePickerService = ImagePickerService(); // Instantiate the image picker service
  DateTime? _selectedDate;
   // ignore: unused_field
   bool _isUploading = false;

  // Method to pick image from gallery
  Future<void> _pickImage() async {
    File? pickedImage = await _imagePickerService.pickImage(); // Use the service to pick an image

    if (pickedImage != null) {
      setState(() {
        _image = pickedImage;
      });
    }
  }


  // Method to upload image and save its URL to Firestore dynamically based on the current year
  Future<void> _uploadImage() async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("You should choose a picture first"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() {
      _isUploading = true;
    });

    try {
      // Upload the image to Firebase Storage and get the URL
      String imageUrl = await _storageService.uploadImage(_image!);

      // Use the current year dynamically
      String currentYear = DateTime.now().year.toString();

      // Save the photo data to Firestore under the current year
      await _firestoreService.addPhoto(currentYear, {
        'url': imageUrl,
        'description': 'A photo uploaded automatically via app',
        'timestamp': DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Image uploaded successfully"),
          backgroundColor: Colors.green,
        ),
      );

      // Clear the selected image after upload
      setState(() {
        _image = null;
      });

    } catch (e) {
      print('Error uploading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error uploading image: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Method to upload image to a specific year selected by the user
  Future<void> _uploadImageForSelectedDate() async {
    if (_image == null || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("You should choose a picture and a date"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Upload the image to Firebase Storage and get the URL
      String imageUrl = await _storageService.uploadImage(_image!);

      // Get the year from the selected date
      String selectedYear = _selectedDate!.year.toString();

      // Use the selected date for the timestamp
      String timestamp = _selectedDate!.toIso8601String();

      // Save the photo data to Firestore under the selected year
      await _firestoreService.addPhoto(selectedYear, {
        'url': imageUrl,
        'description': 'A photo uploaded for a specific year',
        'timestamp': timestamp,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Image uploaded successfully for the selected date"),
          backgroundColor: Colors.green,
        ),
      );

      // Clear the selected image and date after upload
      setState(() {
        _image = null;
        _selectedDate = null;
      });

    } catch (e) {
      print('Error uploading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error uploading image: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Method to pick a date from a calendar
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Upload Image')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Display image or placeholder
            if (_image != null)
              Container(
                height: 400,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(_image!, fit: BoxFit.cover),
                ),
              )
            else
              Container(
                height: 400,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    'No image selected',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            SizedBox(height: 30),
            Divider(
              color: Colors.grey,
              thickness: 1,
            ),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: Icon(Icons.photo_library),
              label: Text('Select Image'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _uploadImage,
              icon: Icon(Icons.upload),
              label: Text('Upload Image (Current Year)'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _selectDate(context),
              icon: Icon(Icons.date_range),
              label: Text('Select Date from Calendar'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            if (_selectedDate != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  "Selected Date: ${_selectedDate!.toLocal()}".split(' ')[0],
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
              SizedBox(
                height: 10,
              ),
            ElevatedButton.icon(
              onPressed: _uploadImageForSelectedDate,
              icon: Icon(Icons.cloud_upload),
              label: Text('Upload Image for Selected Date'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12),
                
              ),
            ),
          ],
        ),
      ),
    );
  }
}
