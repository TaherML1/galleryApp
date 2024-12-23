import 'package:flutter/material.dart';
import 'package:gallery_app/services/firestore_service.dart';
import 'package:gallery_app/models/photo.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gallery_app/main.dart';
import 'package:gallery_app/views/timeline_view.dart';

class YearPhotosScreen extends StatefulWidget {
  final String year;

  const YearPhotosScreen({required this.year, Key? key}) : super(key: key);

  @override
  _YearPhotosScreenState createState() => _YearPhotosScreenState();
}

class _YearPhotosScreenState extends State<YearPhotosScreen> {
  late final FirestoreService _firestoreService;
  final PageController _pageController = PageController(viewportFraction: 1);
  final ValueNotifier<int> _currentPage = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _firestoreService = getIt<FirestoreService>();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _currentPage.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Photos from ${widget.year}', style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF9c51b6),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      backgroundColor: const Color(0xffD4BEE4),
      body: StreamBuilder<List<Photo>>(
        stream: _firestoreService.fetchPhotosStream(widget.year),
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
          final totalPages = (photos.length / 4).ceil();

          return Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: totalPages,
                  onPageChanged: (pageIndex) {
                    _currentPage.value = pageIndex;
                  },
                  itemBuilder: (context, pageIndex) {
                    final startIndex = pageIndex * 4;
                    final endIndex = (startIndex + 4 > photos.length) ? photos.length : startIndex + 4;
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
                            childAspectRatio: 0.54,
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
              ),
              ValueListenableBuilder<int>(
                valueListenable: _currentPage,
                builder: (context, currentPage, child) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        totalPages,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4.0),
                          width: currentPage == index ? 12.0 : 8.0,
                          height: currentPage == index ? 10.0 : 6.0,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: currentPage == index
                                ? Color(0xFF9c51b6) // Current page color
                                : (index < currentPage
                                    ? Colors.grey // Previous pages
                                    : Colors.grey), // Next pages
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
