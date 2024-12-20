import 'package:flutter/material.dart';
import 'package:gallery_app/services/firestore_service.dart';
import 'package:gallery_app/main.dart';
import 'package:gallery_app/views/timeline_view.dart';
import 'package:gallery_app/models/photo.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Homescreen extends StatefulWidget {
  const Homescreen({super.key}); // Corrected class name to match Dart naming conventions

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  final FirestoreService _firestoreService = getIt<FirestoreService>();
  late Future<List<String>> _years;
  String? _selectedYear;
    // ignore: unused_field
    List<String> _favoritePhotos = [];


  @override
  void initState() {
    super.initState();
    _years = _firestoreService.fetchYears();
   _loadFavorites();
  }


  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _favoritePhotos = prefs.getStringList('favorites') ?? [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo Gallery', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF9c51b6), 
        iconTheme: const IconThemeData(
    color: Colors.white, // Change the drawer icon color here
  ),
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
                 Navigator.popUntil(context, ModalRoute.withName('/home'));
            },
          ),
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/random');
            },
            icon: const Icon(Icons.shuffle, color: Colors.white),
          ),
          
        ],
      ),
     drawer: FutureBuilder<List<String>>(
  future: _years,
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }
    if (snapshot.hasError) {
      return Center(child: Text('Error: ${snapshot.error}'));
    }
    if (!snapshot.hasData || snapshot.data!.isEmpty) {
      return const Center(child: Text('No years found.'));
    }

    final years = snapshot.data!;
    years.sort((a, b) => int.parse(b).compareTo(int.parse(a)));

    return Drawer(
      child: Container(  // Added a container to wrap the column
        color: Color(0xFFD4BEE4),  // Change to any desired background color
        child: Column(
          children: [
            // Drawer header
            DrawerHeader(
              decoration: BoxDecoration(
                color: const Color(0xFF9c51b6),
              ),
              child: Center(
                child: const Text(
                  '          Select Year                             ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              ),
            ),
            // Years ExpansionTile
            ExpansionTile(
              title: const Text('Show Years', style: TextStyle(
                color: Color(0xFF9c51b6),
                fontWeight: FontWeight.w700
              )),
              leading: const Icon(Icons.calendar_today, color: Color(0xFF9c51b6)),  // Set icon color as needed
              iconColor: Color(0xFF9c51b6),
                collapsedIconColor: Color(0xFF9c51b6),
              children: years.map((year) {
                return ListTile(
                  title: Text(year , style: TextStyle(
                    color: Color(0xFF9c51b6),
                  ),),
                  onTap: () {
                    setState(() {
                      _selectedYear = year;
                    });
                    Navigator.pop(context); // Close the drawer when a year is selected
                  },
                );
              }).toList(),
            ),
            // Favorites ListTile
            ListTile(
              leading: const Icon(Icons.favorite, color: Color(0xFF9c51b6),  ),  // Set icon color as needed
              title: const Text('Favorites', style: TextStyle(color: Color(0xFF9c51b6) , fontWeight: FontWeight.w700)),  // Set text color
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/favorites');
              },
            ),
            // Expanded to push the Info button to the bottom
            Expanded(child: Container()),

            // Info ListTile at the bottom
            ListTile(
              leading: const Icon(Icons.info, color: Color(0xFF9c51b6)),  // Set icon color as needed
              title: const Text('Info', style: TextStyle(color: Color(0xFF9c51b6) , fontWeight: FontWeight.w700)),  // Set text color
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/info');
              },
            ),
          ],
        ),
      ),
    );
  },
),

backgroundColor: Color(0xffD4BEE4),

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
                          color: Color(0xffD4BEE4),
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
          : const Center(child: Text('Select a year to view photos.',style: TextStyle(color: Color(0xFF9c51b6) , fontWeight: FontWeight.w700  ,fontSize: 20),  ) ),
    );
  }
}
