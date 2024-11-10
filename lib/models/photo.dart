import 'package:cloud_firestore/cloud_firestore.dart';

class Photo {
  final String description;
  final String url;
  final DateTime timestamp;  // Change the type to DateTime

  Photo({
    required this.description,
    required this.url,
    required this.timestamp,
  });

  // Update this method to handle both Timestamp and String date
  factory Photo.fromFirestore(Map<String, dynamic> data) {
    return Photo(
      description: data['description'] ?? 'No description',
      url: data['url'] ?? '',
      timestamp: data['timestamp'] is Timestamp
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.tryParse(data['timestamp']) ?? DateTime(1970),  // Parse ISO 8601 string, fallback to epoch if invalid
    );
  }
}
 