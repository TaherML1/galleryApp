import 'package:flutter/material.dart';
import 'package:gallery_app/services/firestore_service.dart';
import 'package:gallery_app/models/photo.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
              Navigator.pushNamed(context, '/upload'); // Navigate to the Upload Image screen
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
          years.sort((a, b) => int.parse(b).compareTo(int.parse(a)));

          return ListView.builder(
            itemCount: years.length,
            itemBuilder: (context, index) {
              final year = years[index];

              return FutureBuilder<List<Photo>>(
                future: _firestoreService.fetchPhotos(year),
                builder: (context, photoSnapshot) {
                  if (photoSnapshot.connectionState == ConnectionState.waiting) {
                    return ExpansionTile(
                      title: Text(
                        '$year',
                        style: TextStyle(
                          fontSize: 22, 
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                    title: Text(
                      '$year',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    children: [
                      GridView.builder(
                        shrinkWrap: true, // To prevent grid from taking full height
                        physics: NeverScrollableScrollPhysics(), // Disable scrolling on the grid
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, // Two images per row
                          crossAxisSpacing: 10.0, // Space between columns
                          mainAxisSpacing: 10.0, // Space between rows
                          childAspectRatio: 1, // Aspect ratio for the images (square)
                        ),
                        itemCount: photos.length,
                        itemBuilder: (context, index) {
                          final photo = photos[index];
                          return GestureDetector(
                            onTap: () {
                              // Navigate to a detailed view of the image
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FullImageScreen(photo: photo),
                                ),
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: CachedNetworkImage(
                                imageUrl: photo.url,
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    Center(child: CircularProgressIndicator()),
                                errorWidget: (context, url, error) => Icon(Icons.error),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // Method to format the date nicely
  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }
}

// Full Image Screen to show the image in full size
class FullImageScreen extends StatelessWidget {
  final Photo photo;

  FullImageScreen({required this.photo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Full Image'),
      ),
      body: Center(
        child: CachedNetworkImage(
          imageUrl: photo.url,
          fit: BoxFit.contain,
          placeholder: (context, url) => Center(child: CircularProgressIndicator()),
          errorWidget: (context, url, error) => Icon(Icons.error),
        ),
      ),
    );
  }
}
