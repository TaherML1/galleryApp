import 'package:flutter/material.dart';
import 'package:gallery_app/services/firestore_service.dart';
import 'package:gallery_app/models/photo.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gallery_app/main.dart';
import 'package:gallery_app/views/timeline_view.dart';
class YearPhotosScreen extends StatelessWidget {
  final String year;

  const YearPhotosScreen({required this.year, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final FirestoreService _firestoreService = getIt<FirestoreService>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Photos from $year', style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF9c51b6),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      backgroundColor: const Color(0xffD4BEE4),
      body: StreamBuilder<List<Photo>>(
        stream: _firestoreService.fetchPhotosStream(year),
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
            height: MediaQuery.of(context).size.height,
            child: PageView.builder(
              controller: PageController(viewportFraction: 1),
              itemCount: (photos.length / 4).ceil(),
              itemBuilder: (context, pageIndex) {
                final startIndex = pageIndex * 4;
                final endIndex = (startIndex + 4 > photos.length)
                    ? photos.length
                    : startIndex + 4;

                final photoSubset = photos.sublist(startIndex, endIndex);

                return Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Card(
                    elevation: 5,
                    color: const Color(0xffD4BEE4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12.0,
                        mainAxisSpacing: 12.0,
                        childAspectRatio: 0.47,
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
      ),
    );
  }
}
