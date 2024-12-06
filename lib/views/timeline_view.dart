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
import 'package:get_it/get_it.dart';
class TimelineView extends StatefulWidget {
  const TimelineView({Key? key}) : super(key: key);

  @override
  _TimelineViewState createState() => _TimelineViewState();
}

class _TimelineViewState extends State<TimelineView> {
  late Future<List<String>> _years;
  final FirestoreService _firestoreService = FirestoreService();
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
        title: const Text('Photo Gallery'),
        backgroundColor: const Color(0xFF3E4A59), // Cool dark color
        actions: [
          IconButton(
            icon: const Icon(Icons.add_a_photo),
            onPressed: () {
              Navigator.pushNamed(context, '/upload');
            },
          ),
          FutureBuilder<List<String>>(
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

              return DropdownButton<String>(
                value: _selectedYear,
                hint: const Text('Select Year'),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedYear = newValue;
                  });
                },
                items: years.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              );
            },
          ),
        ],
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
                              crossAxisSpacing:12.0, // Reduced spacing
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
