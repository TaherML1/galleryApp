import 'package:cloud_firestore/cloud_firestore.dart';

class Photo {
  final String id;
  final String description;
  final String url;
  final DateTime timestamp;
  bool favorite;

  Photo({
    required this.id,
    required this.description,
    required this.url,
    required this.timestamp,
    required this.favorite,
  });

  // Factory method to create Photo from Firestore data
  factory Photo.fromFirestore(Map<String, dynamic> data, String id) {
    return Photo(
      id: id,
      description: data['description'] ?? 'No description',
      url: data['url'] ?? '',
      timestamp: data['timestamp'] is Timestamp
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.tryParse(data['timestamp']) ?? DateTime(1970),
      favorite: data['favorite'] ?? false,
    );
  }

  // Create a Photo object from JSON (for local storage)
  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      id: json['id'] ?? '',
      description: json['description'] ?? 'No description',
      url: json['url'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      favorite: json['favorite'] ?? false,
    );
  }

  // Convert the Photo object to JSON (for local storage)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'url': url,
      'timestamp': timestamp.toIso8601String(),
      'favorite': favorite,
    };
  }

  int get year => timestamp.year;

  // Toggle the favorite status
  void toggleFavorite() {
    favorite = !favorite;
  }

  // Convert the photo to a map for updating Firestore
  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'url': url,
      'timestamp': timestamp,
      'favorite': favorite,
    };
  }
}
