import 'package:flutter/material.dart';
import 'package:gallery_app/main.dart';
import 'package:gallery_app/services/firestore_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:gal/gal.dart';

class NotificationScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const NotificationScreen({Key? key, required this.data}) : super(key: key);

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late bool _isFavorite;
  late String _description = '';
  bool _isDownloading = false;
  bool _isEditing = false;
  int _currentIndex = 0;
   int count = 0;

  final TextEditingController _descriptionController = TextEditingController();
  final FirestoreService _firestoreService = getIt<FirestoreService>();

  int _getPhotoCount() {
  count = 0;
  while (widget.data.containsKey('photo_${count}_url')) {
    count++;
  }
  return count;
}

  @override
  void initState() {
    super.initState();
    if (widget.data != null && widget.data.isNotEmpty) {
      _isFavorite = widget.data['photo_${_currentIndex}_favorite'] ?? false;
      _description = widget.data['photo_${_currentIndex}_description'] ?? '';
      _descriptionController.text = _description;

      // Now you can use _getPhotoCount() to retrieve the number of photos
    int numberOfPhotos = _getPhotoCount();
    logger.i('Total number of photos: $numberOfPhotos');
    }
  }

  Future<void> _toggleFavoriteStatus() async {
    setState(() {
      _isFavorite = !_isFavorite;
    });
    await _firestoreService.updateFavoriteStatus(
      widget.data['photo_${_currentIndex}_year'].toString(),
      widget.data['photo_${_currentIndex}_id'],
      _isFavorite,
    );
  }

  Future<void> _downloadAndShareImage(String imageUrl) async {
    try {
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/photo.jpg';

      final response = await Dio().download(imageUrl, filePath);

      if (response.statusCode == 200) {
        final file = XFile(filePath);
        Share.shareXFiles(
          [file],
          text: 'Check out this photo!',
        );
      } else {
        throw Exception('Failed to download image');
      }
    } catch (e) {
      logger.e('Error downloading or sharing image: $e');
    }
  }

  void _toggleEditMode() async {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        _description = _descriptionController.text;

        _firestoreService.updatePhotoDescription(
          widget.data['photo_${_currentIndex}_year'].toString(),
          widget.data['photo_${_currentIndex}_id'],
          _description,
        );
      }
    });
  }

  Future<void> _downloadImage(String imageUrl) async {
  setState(() {
    _isDownloading = true;
  });

  try {
    logger.i('Starting image download from $imageUrl...');
    final response = await http.get(Uri.parse(imageUrl));
    logger.i('Response status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final Uint8List bytes = response.bodyBytes;
      logger.i('Image download successful, bytes length: ${bytes.length}');

      // Use the putImageBytes method from the gal package
      await Gal.putImageBytes(bytes, album: 'Downloaded Images');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image saved to gallery!'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to download image, status code: ${response.statusCode}')),
      );
    }
  } catch (e) {
    print('Error occurred while downloading image: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error occurred while downloading image')),
    );
  } finally {
    setState(() {
      _isDownloading = false;
    });
  }
}

 void _navigatePhotos(int direction) {
  if (widget.data.isEmpty) return; // Prevent navigation if data is empty
  logger.i('widget data length : ' + widget.data.length.toString());
  setState(() {
    int newIndex = _currentIndex + direction;
     logger.i('newIndex : ' + newIndex.toString());
   logger.i('Total number of photos: $count');
     if (newIndex >= 0 && newIndex < count){
   _currentIndex = ((_currentIndex + direction) % widget.data.length).toInt();
    _isFavorite = widget.data['photo_${_currentIndex}_favorite'] ?? false;
    _description = widget.data['photo_${_currentIndex}_description'] ?? '';
    _descriptionController.text = _description;
     }else{
       ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('there is no image'), backgroundColor: Colors.red),
          );
     }
 
  });
}





  @override
  Widget build(BuildContext context) {
    if (widget.data == null || widget.data.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('No Data', style: TextStyle(color: Colors.white)),
          backgroundColor: Color(0xFF9c51b6),
          iconTheme: IconThemeData(
            color: Colors.white,
          ),
        ),
        body: Center(
          child: Text('No data available'),
        ),
      );
    }

    final DateFormat dateFormat = DateFormat('MMMM dd, yyyy');
    final String formattedDate = dateFormat.format(DateTime.parse(widget.data['photo_${_currentIndex}_timestamp']));

    return Scaffold(
      appBar: AppBar(
        title: Text(formattedDate, style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF9c51b6),
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
      ),
      body: Container(
        color: Color(0xffD4BEE4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                child: Row(
                  children: [
                    Expanded(
                      child: _isEditing
                          ? TextField(
                              controller: _descriptionController,
                              style: TextStyle(color: Color(0xFF9c51b6), fontWeight: FontWeight.w700),
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(
                                labelText: 'Description',
                                border: OutlineInputBorder(),
                              ),
                            )
                          : Text(
                              _description.isEmpty ? 'No description available' : _description,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF9c51b6),
                                letterSpacing: 1.2,
                                shadows: [
                                  Shadow(
                                    blurRadius: 1.0,
                                    color: Colors.black26,
                                    offset: Offset(1.1, 1.1),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                    ),
                    IconButton(
                      icon: Icon(_isEditing ? Icons.check : Icons.edit, size: 30, color: Color(0xFF9c51b6)),
                      onPressed: _toggleEditMode,
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: CachedNetworkImage(
                    imageUrl: widget.data['photo_${_currentIndex}_url'],
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) => const Icon(Icons.error),
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios, color: Color(0xFF9c51b6)),
                  onPressed: () => _navigatePhotos(-1),
                ),
                IconButton(
                  icon: Icon(Icons.arrow_forward_ios, color: Color(0xFF9c51b6)),
                  onPressed: () => _navigatePhotos(1),
                ),
              ],
            ),
            BottomAppBar(
              color: Color(0xFFF8F6F4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.save_alt, color: Color(0xFF9c51b6)),
                      onPressed: () {
                        _downloadImage(widget.data['photo_${_currentIndex}_url']);
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: _isFavorite ? Color(0xFF9c51b6) : Color(0xFF9c51b6),
                      ),
                      onPressed: _toggleFavoriteStatus,
                    ),
                    IconButton(
                      icon: const Icon(Icons.share, color: Color(0xFF9c51b6)),
                      onPressed: () {
                        _downloadAndShareImage(widget.data['photo_${_currentIndex}_url']);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



