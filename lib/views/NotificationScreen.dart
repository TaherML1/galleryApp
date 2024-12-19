import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:gallery_app/models/photo.dart';
import 'package:gallery_app/main.dart';
import 'package:gallery_app/services/firestore_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
//import 'package:logger/logger.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';


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

  final TextEditingController _descriptionController = TextEditingController();
  final FirestoreService _firestoreService = getIt<FirestoreService>();

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.data['favorite'] ?? false;
    _description = widget.data['description'] ?? '';
    _descriptionController.text = _description;
  }

  Future<void> _toggleFavoriteStatus() async {
    setState(() {
      _isFavorite = !_isFavorite;
    });
    await _firestoreService.updateFavoriteStatus(
      widget.data['year'].toString(),
      widget.data['id'],
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
          widget.data['year'].toString(),
          widget.data['id'],
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

        final result = await ImageGallerySaver.saveImage(bytes);
        logger.i('Image saving result: $result');

        if (result['isSuccess']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Image saved to gallery!'), backgroundColor: Colors.green),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save image to gallery'), backgroundColor: Colors.red),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download image, status code: ${response.statusCode}')),
        );
      }
    } catch (e) {
      logger.e('Error occurred while downloading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error occurred while downloading image')),
      );
    } finally {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final DateFormat dateFormat = DateFormat('MMMM dd, yyyy');
    final String formattedDate = dateFormat.format(DateTime.parse(widget.data['timestamp']));

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
                    imageUrl: widget.data['photoUrl'],
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) => const Icon(Icons.error),
                  ),
                ),
              ),
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
                        _downloadImage(widget.data['photoUrl']);
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
                        _downloadAndShareImage(widget.data['photoUrl']);
                      },
                    ),
                  /*  IconButton(
                      icon: const Icon(Icons.delete, color: Color(0xFF9c51b6)),
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
                            await _firestoreService.deletePhoto(
                              widget.data['year'].toString(),
                              widget.data['id'],
                              widget.data['photoUrl'],
                            );

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
                    ),*/
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



  // Function to schedule the notification after 5 seconds
  void scheduleNotification() {
    Future.delayed(Duration(seconds: 5), () {
      AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 10,
          channelKey: 'basic_channel',
          title: 'Reminder!',
          body: 'This notification appeared after 5 seconds.',
        ),
      );
    });
  }


  void scheduleMemoryNotification(Photo memoryPhoto) {
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 10, // Unique ID for the notification
        channelKey: 'basic_channel',
        title: 'Memory from ${memoryPhoto.year}!',
        body: 'Remember this? "${memoryPhoto.description}"',
        bigPicture: memoryPhoto.url, // Optional: show the photo in the notification
        notificationLayout: NotificationLayout.BigPicture, // Layout for showing image
      ),
    );
  }



