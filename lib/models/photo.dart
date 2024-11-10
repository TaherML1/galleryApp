
import 'package:cloud_firestore/cloud_firestore.dart';
class Photo {
  final String description;
  final String url;
  final Timestamp timestamp;

  Photo({
    required this.description,
    required this.url,
    required this.timestamp,
  });

  // Update this method to handle the Timestamp field safely
  factory Photo.fromFirestore(Map<String, dynamic> data) {
    return Photo(
      description: data['description'] ?? 'No description', 
      url: data['url'] ?? '', 
      timestamp: data['timestamp'] is Timestamp
          ? data['timestamp'] as Timestamp
          : Timestamp.fromMillisecondsSinceEpoch(0), 
    );
  }
}
