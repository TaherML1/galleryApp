import 'package:flutter/material.dart';
import 'package:gallery_app/services/firestore_service.dart';
import 'package:gallery_app/models/photo.dart';

class TimelineView extends StatefulWidget {
  @override
  _TimelineViewState createState() => _TimelineViewState();
}

class _TimelineViewState extends State<TimelineView> {
  late Future<List<String>> _years;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    // Fetch years when the screen loads
    _years = _firestoreService.fetchYears();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Photo Timeline'),
        actions: [
          IconButton(
            icon: Icon(Icons.add_a_photo),
            onPressed: () {
              // Navigate to the Upload Image screen
              Navigator.pushNamed(context, '/upload');
            },
          ),
        ],
      ),
      body: FutureBuilder<List<String>>(
        future: _years,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No years found.'));
          }

          final years = snapshot.data!;

          return ListView.builder(
            itemCount: years.length,
            itemBuilder: (context, index) {
              final year = years[index];

              return FutureBuilder<List<Photo>>(
                future: _firestoreService.fetchPhotos(year),
                builder: (context, photoSnapshot) {
                  if (photoSnapshot.connectionState == ConnectionState.waiting) {
                    return ExpansionTile(
                      title: Text('$year'),
                      children: [Center(child: CircularProgressIndicator())],
                    );
                  }
                  if (photoSnapshot.hasError) {
                    return ExpansionTile(
                      title: Text('$year'),
                      children: [Center(child: Text('Error loading photos.'))],
                    );
                  }
                  if (!photoSnapshot.hasData || photoSnapshot.data!.isEmpty) {
                    return ExpansionTile(
                      title: Text('$year'),
                      children: [Center(child: Text('No photos found.'))],
                    );
                  }

                  final photos = photoSnapshot.data!;

                  return ExpansionTile(
                    title: Text('$year'),
                    children: photos.map((photo) {
                      return ListTile(
                        leading: Image.network(photo.url),
                        title: Text(photo.description),
                      );
                    }).toList(),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
