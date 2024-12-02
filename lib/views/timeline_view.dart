import 'package:flutter/material.dart';
import 'package:gallery_app/services/firestore_service.dart';
import 'package:gallery_app/models/photo.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TimelineView extends StatefulWidget {
  const TimelineView({Key? key}) : super(key: key); // Added key parameter

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
        title: const Text('Photo Gallery'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_a_photo),
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

          return ListView.builder(
            itemCount: years.length,
            itemBuilder: (context, index) {
              final year = years[index];

              return StreamBuilder<List<Photo>>(
                stream: _firestoreService.fetchPhotosStream(year),
                builder: (context, photoSnapshot) {
                  if (photoSnapshot.connectionState == ConnectionState.waiting) {
                    return ExpansionTile(
                      title: Text(
                        '$year',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      children: const [Center(child: CircularProgressIndicator())],
                    );
                  }
                  if (photoSnapshot.hasError) {
                    return ExpansionTile(
                      title: Text('$year'),
                      children: const [Center(child: Text('Error loading photos.'))],
                    );
                  }
                  if (!photoSnapshot.hasData || photoSnapshot.data!.isEmpty) {
                    return ExpansionTile(
                      title: Text('$year'),
                      children: const [Center(child: Text('No photos found.'))],
                    );
                  }

                  final photos = photoSnapshot.data!;

                  return ExpansionTile(
                    title: Text(
                      '$year',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    children: [
                      GridView.builder(
                        shrinkWrap: true, // To prevent grid from taking full height
                        physics: const NeverScrollableScrollPhysics(), // Disable scrolling on the grid
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                                    const Center(child: CircularProgressIndicator()),
                                errorWidget: (context, url, error) => const Icon(Icons.error),
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
}

// Full Image Screen to show the image in full size
class FullImageScreen extends StatefulWidget {
  final Photo photo;

  const FullImageScreen({Key? key, required this.photo}) : super(key: key); // Added key parameter

  @override
  _FullImageScreenState createState() => _FullImageScreenState();
}

class _FullImageScreenState extends State<FullImageScreen> {
  late bool _isFavorite =false;
  final Logger _logger = Logger();

  @override
  void initState() {
    super.initState();
    _loadFavoriteStatus();
  }

  Future<void> _loadFavoriteStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isFavorite = prefs.getBool(widget.photo.id) ?? false;
    });
  }

  Future<void> _toggleFavoriteStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isFavorite = !_isFavorite;
      prefs.setBool(widget.photo.id, _isFavorite);
    });
  }

 Future<void> _downloadAndShareImage(String imageUrl) async {
  try {
    // Get the temporary directory to store the image
    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/photo.jpg';

    // Download the image using Dio
    final response = await Dio().download(imageUrl, filePath);

    if (response.statusCode == 200) {
      // Create an XFile for the image
      XFile file = XFile(filePath);

      // Share the image using shareXFiles
      Share.shareXFiles(
        [file],
        text: 'Check out this photo!',
      );
    } else {
      throw Exception('Failed to download image');
    }
  } catch (e) {
    print('Error downloading or sharing image: $e');
  }
}

Future<void> _saveImageToGallery(String imageUrl) async {
  try {
    // Get the directory to store the image (for Android/iOS it will be in Downloads folder)
    final directory = await getExternalStorageDirectory();
    if (directory == null) throw Exception('Unable to get external storage directory.');

    // Define a path to save the image
    final filePath = '${directory.path}/${widget.photo.id}.jpg';

    // Download the image using Dio
    final response = await Dio().download(imageUrl, filePath);

    if (response.statusCode == 200) {
      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image saved successfully!')),
      );
    } else {
      throw Exception('Failed to download image');
    }
  } catch (e) {
    // Show an error message in case of failure
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error saving image: $e')),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Full Image'),
      ),
      body: Stack(
        children: [
          Center(
            child: CachedNetworkImage(
              imageUrl: widget.photo.url,
              fit: BoxFit.contain,
              placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: BottomAppBar(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                     
                      icon: const Icon(Icons.save_alt),
                       onPressed: (){
                        _saveImageToGallery(widget.photo.url);
                       }, 
                    ),
                   IconButton(
                      icon: Icon(
                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: _isFavorite ? Colors.red : null,
                      ),
                      onPressed: _toggleFavoriteStatus,
                    ),
                    IconButton(
                      icon: const Icon(Icons.share),
                      onPressed: () {
                        // Share the image directly
                        _downloadAndShareImage(widget.photo.url);
                      },
                    ),
                 IconButton(
  icon: const Icon(Icons.delete),
  onPressed: () async {
    // Show confirmation dialog
    bool confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Photo'),
        content: const Text('Are you sure you want to delete this photo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      final FirestoreService _firestoreService = FirestoreService();

      try {
        // Attempt to delete the photo
        await _firestoreService.deletePhoto(widget.photo.year.toString(), widget.photo.id, widget.photo.url);

        // If the deletion succeeds, show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo deleted successfully!')),
        );
        
        // Return to the previous screen
        Navigator.pop(context); // Go back to the timeline
      } catch (e) {
        // If there is an error, show an error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete photo: $e')),
        );
      }
    }
  },
),

                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
