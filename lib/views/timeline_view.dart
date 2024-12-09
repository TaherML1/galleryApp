import 'package:flutter/material.dart';
import 'package:gallery_app/main.dart';
import 'package:gallery_app/services/firestore_service.dart';
import 'package:gallery_app/models/photo.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; 


class FullImageScreen extends StatefulWidget {
  final Photo photo;

  const FullImageScreen({Key? key, required this.photo}) : super(key: key);

  @override
  _FullImageScreenState createState() => _FullImageScreenState();
}

class _FullImageScreenState extends State<FullImageScreen> {
  late bool _isFavorite;
  late String _description = '';
  bool _isEditing = false;
  final Logger _logger = Logger();
  final TextEditingController _descriptionController = TextEditingController();
  final FirestoreService _firestoreService = getIt<FirestoreService>();

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.photo.favorite;
    _description = widget.photo.description ?? '';
    _descriptionController.text = _description;
  }

  Future<void> _toggleFavoriteStatus() async {
    setState(() {
      _isFavorite = !_isFavorite;
    });
    // Update the favorite status in Firestore
    await _firestoreService.updateFavoriteStatus(widget.photo.year.toString(), widget.photo.id, _isFavorite);
  }

  Future<void> _downloadAndShareImage(String imageUrl) async {
    try {
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/photo.jpg';

      final response = await Dio().download(imageUrl, filePath);

      if (response.statusCode == 200) {
        XFile file = XFile(filePath);
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

  void _toggleEditMode() async {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        _description = _descriptionController.text;
        // Save the updated description to Firestore
         _firestoreService.updatePhotoDescription(
          widget.photo.year.toString(),
          widget.photo.id,
          _description,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final DateFormat dateFormat = DateFormat('MMMM dd, yyyy');
    final String formattedDate = dateFormat.format(widget.photo.timestamp);

    return Scaffold(
      appBar: AppBar(
        title: Text(formattedDate),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: _isEditing
                      ? TextField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            border: OutlineInputBorder(),
                          ),
                        )
                      : Text(
                          _description.isEmpty ? 'No description available' : _description,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),
                IconButton(
                  icon: Icon(_isEditing ? Icons.check : Icons.edit),
                  onPressed: _toggleEditMode,
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: CachedNetworkImage(
                imageUrl: widget.photo.url,
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),
          ),
          BottomAppBar(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: const Icon(Icons.save_alt),
                    onPressed: () {
                      // _saveImageToGallery(widget.photo.url);
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
                      _downloadAndShareImage(widget.photo.url);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () async {
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
                        try {
                          await _firestoreService.deletePhoto(widget.photo.year.toString(), widget.photo.id, widget.photo.url);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Photo deleted successfully!')),
                          );

                          Navigator.pop(context);
                        } catch (e) {
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
        ],
      ),
    );
  }
}

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreen();
}

class _FavoriteScreen extends State<FavoriteScreen> {




  final FirestoreService _firestoreService = getIt<FirestoreService>();

  @override
  Widget build(BuildContext context) {
 return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
      ),
      body: FutureBuilder<List<Photo>>(
        future: _firestoreService.fetchAllFavoritePhotos(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error fetching favorite photos.'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No favorite photos found.'));
          }

          final favoritePhotos = snapshot.data!;

          return Padding(
             padding: const EdgeInsets.all(4.0),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12.0,
                mainAxisSpacing: 12.0,
                childAspectRatio: 0.7,
              ),
              itemCount: favoritePhotos.length,
              itemBuilder: (context, index) {
                final photo = favoritePhotos[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>FullImageScreen(photo: photo)
                      )
                    );
                  },
                  child: CachedNetworkImage(
                    imageUrl: photo.url,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) => const Icon(Icons.error),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}


class randomPictureWidget extends StatefulWidget {
  const randomPictureWidget({super.key});

  @override
  State<randomPictureWidget> createState() => _RandomPictureWidgetState();
}

class _RandomPictureWidgetState extends State<randomPictureWidget> {
  final FirestoreService _firestoreService = getIt<FirestoreService>();
  Future<Photo?>? _randomPhotoFuture;
  Photo? _currentPhoto;
  DateTime? _lastFetchedDate;

  @override
  void initState() {
    super.initState();
    _loadStoredPhoto();
  }

  // Load stored photo from SharedPreferences if available
  Future<void> _loadStoredPhoto() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedPhoto = prefs.getString('randomPhoto');
    String? storedDate = prefs.getString('fetchedDate');

    if (storedPhoto != null && storedDate != null) {
      DateTime lastDate = DateTime.parse(storedDate);
      DateTime now = DateTime.now();

      if (now.difference(lastDate).inDays == 0) {
        // Use the stored photo if it's the same day
        setState(() {
          _currentPhoto = Photo.fromJson(jsonDecode(storedPhoto));
        });
      } else {
        // If the day has changed, fetch a new photo
        _fetchRandomPhoto();
      }
    } else {
      // No photo stored, fetch a new one
      _fetchRandomPhoto();
    }
  }

  // Fetch a random photo and store it
  void _fetchRandomPhoto() async {
    Photo? fetchedPhoto = await _firestoreService.fetchRandomPhotoFromAllYears();
    if (fetchedPhoto != null) {
      setState(() {
        _currentPhoto = fetchedPhoto;
      });

      // Store the photo and the current date in SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('randomPhoto', jsonEncode(fetchedPhoto.toJson()));
      await prefs.setString('fetchedDate', DateTime.now().toIso8601String());
    }
  }

  @override
 Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Random Photo'),
    ),
    body: _currentPhoto != null
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('❤️ Todays photo is  ❤️',  style: const TextStyle(fontSize: 20 ),),

                SizedBox(height: 20,),
                Text(
                  _currentPhoto!.description, 
                  style: const TextStyle(fontSize: 18),  // Adjust text styling as needed
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: SizedBox(
                    height: 600,  // Set the desired height
                    width: 400,   // Set the desired width
                    child: Image.network(
                      _currentPhoto!.url,
                      fit: BoxFit.cover,  // Adjust how the image should fit the box (e.g., cover, contain, fill)
                    ),
                  ),
                )  // Display the stored or fetched photo
              ],
            ),
          )
        : const Center(child: CircularProgressIndicator()),  // Show loading while fetching
  );
}
}