import 'package:flutter/material.dart';
import 'package:gallery_app/services/firestore_service.dart';
import 'package:gallery_app/main.dart';
import 'package:gallery_app/views/timeline_view.dart';
import 'package:gallery_app/models/photo.dart';
import 'package:cached_network_image/cached_network_image.dart';
class Homescreen extends StatefulWidget {
const Homescreen({super.key}); // Corrected class name to match Dart naming conventions

@override
State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
final FirestoreService _firestoreService = getIt<FirestoreService>();
late Future<List<String>> _years;
String? _selectedYear;

@override
void initState() {
super.initState();
_years = _firestoreService.fetchYears();
}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: const Text('New Photo Gallery'),
backgroundColor: const Color(0xFF3E4A59), // Cool dark color
actions: [
IconButton(
icon: const Icon(Icons.add_a_photo, color: Colors.white),
onPressed: () {
Navigator.pushNamed(context, '/upload');
},
),
IconButton(
icon: const Icon(Icons.home, color: Colors.white),
onPressed: () {


Navigator.pushNamed(context, '/home');
        },
      )
    ],
  ),
   drawer: FutureBuilder<List<String>>(
    future: _years,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return Center(child: Text('Error: \${snapshot.error}'));
      }
      if (!snapshot.hasData || snapshot.data!.isEmpty) {
        return const Center(child: Text('No years found.'));
      }

      final years = snapshot.data!;
      years.sort((a, b) => int.parse(b).compareTo(int.parse(a)));

      return Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: const Color(0xFF3E4A59),
              ),
              child: const Text(
                'Select Year',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ExpansionTile(
              title: const Text('Show Years'),
              leading: const Icon(Icons.calendar_today),
              children: years.map((year) {
                return ListTile(
                  title: Text(year),
                  onTap: () {
                    setState(() {
                      _selectedYear = year;
                    });
                    Navigator.pop(context); // Close the drawer when a year is selected
                  },
                );
              }).toList(),
            ),

           ListTile(
              leading: const Icon(Icons.favorite),
              title: const Text('Favorites'),
              onTap: () {
                // Close the drawer and navigate to the favorites page (assuming you have a favorites route)
                Navigator.pop(context); 
                Navigator.pushNamed(context, '/favorites');
           }),

         
          ],
          
        ),
      );
    },
  ),
  body: _selectedYear != null
      ? StreamBuilder<List<Photo>>(
          stream: _firestoreService.fetchPhotosStream(_selectedYear!),
          builder: (context, photoSnapshot) {
            if (photoSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (photoSnapshot.hasError) {
              return const Center(child: Text('Error loading photos.'));
            }
            if (!photoSnapshot.hasData || photoSnapshot.data!.isEmpty) {
              return const Center(child: Text('No photos found.'));
            }

            final photos = photoSnapshot.data!;

            return SizedBox(
              height: MediaQuery.of(context).size.height, // Use full height
              child: PageView.builder(
                controller: PageController(viewportFraction: 1), // Controls slide snapping and fraction
                itemCount: (photos.length / 4).ceil(), // Number of pages based on photos
                itemBuilder: (context, pageIndex) {
                  final startIndex = pageIndex * 4;
                  final endIndex = (startIndex + 4 > photos.length)
                      ? photos.length
                      : startIndex + 4;

                  final photoSubset = photos.sublist(startIndex, endIndex);

                  return Padding(
                    padding: const EdgeInsets.all(4.0), // Reduced padding
                    child: Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12.0, // Reduced spacing
                          mainAxisSpacing: 12.0, // Reduced spacing
                          childAspectRatio: 0.47, // More square-like photos
                        ),
                        itemCount: photoSubset.length,
                        itemBuilder: (context, index) {
                          final photo = photoSubset[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FullImageScreen(photo: photo),
                                ),
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                imageUrl: photo.url,
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    const Center(child: CircularProgressIndicator()),
                                errorWidget: (context, url, error) => const Icon(Icons.error),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            );
          },
        )
      : const Center(child: Text('Select a year to view photos.')),
);
}
}