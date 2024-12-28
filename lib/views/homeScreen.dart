import 'package:flutter/material.dart';
import 'package:gallery_app/services/firestore_service.dart';
import 'package:gallery_app/main.dart';
import 'package:gallery_app/views/timeline_view.dart';
import 'package:gallery_app/models/photo.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:gallery_app/views/yearPhotosScreen.dart'; // Import the new widget
import 'package:audioplayers/audioplayers.dart';

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  final FirestoreService _firestoreService = getIt<FirestoreService>();
  late Future<List<String>> _years;
  List<String> _favoritePhotos = [];
  List<Photo> _memoryPhotos = [];
   late AudioPlayer _audioPlayer;
   bool _isPlaying = true;
   Duration _lastPosition = Duration.zero; // Store the last position here
   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
   

  @override
  void initState() {
    super.initState();
    _years = _firestoreService.fetchYears();
    _loadFavorites();
    _checkForMemory();
   _audioPlayer = AudioPlayer();
      _audioPlayer.setReleaseMode(ReleaseMode.loop); 
      
  }

 Future<void> _playNancy() async {
    setState(() {
      _isPlaying = !_isPlaying;
    });

    if (!_isPlaying) {
      try {
        // Resume from the last position
        await _audioPlayer.play(AssetSource('NancyAjram.mp3'), position: _lastPosition);
        print('Sound started successfully from position $_lastPosition');
      } catch (e) {
        print('Error playing sound: $e');
      }
    } else {
      // Stop the audio and store the current position
      _lastPosition = await _audioPlayer.getCurrentPosition() ?? Duration.zero;
      await _audioPlayer.stop();
      print('Sound stopped at position $_lastPosition');
    }
  }


  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _favoritePhotos = prefs.getStringList('favorites') ?? [];
    });
  }

  Future<void> _checkForMemory() async {
    List<Photo> memoryPhotos = await _firestoreService.checkForMemory();
    setState(() {
      _memoryPhotos = memoryPhotos;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey ,
      appBar: AppBar(
        title: const Text('Photo Gallery', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF9c51b6),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_a_photo, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(context, '/upload');
            },
          ),
          IconButton(
            icon: const Icon(Icons.home, color: Colors.white),
            onPressed: () {
              Navigator.popUntil(context, ModalRoute.withName('/home'));
            },
          ),
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/random');
            },
            icon: const Icon(Icons.shuffle, color: Colors.white),
          ),
          IconButton(
            onPressed:(){
              _playNancy();
            }, 
            icon: Icon(
              _isPlaying ? Icons.music_off_outlined : Icons.music_note,
            ),
            
          )
        ],
      ),
      drawer: FutureBuilder<List<String>>(
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

          return Drawer(
            child: Container(
              color: const Color(0xFFD4BEE4),
              child: Column(
                children: [
                  DrawerHeader(
                    decoration: BoxDecoration(
                      color: const Color(0xFF9c51b6),
                    ),
                    child: Center(
                      child: const Text(
                        '          Select Year                             ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                        ),
                      ),
                    ),
                  ),
                  ExpansionTile(
                    title: const Text('Show Years', style: TextStyle(
                      color: Color(0xFF9c51b6),
                      fontWeight: FontWeight.w700
                    )),
                    leading: const Icon(Icons.calendar_today, color: Color(0xFF9c51b6)),
                    iconColor: const Color(0xFF9c51b6),
                    collapsedIconColor: const Color(0xFF9c51b6),
                    children: years.map((year) {
                      return ListTile(
                        title: Text(year , style: const TextStyle(
                          color: Color(0xFF9c51b6),
                        ),),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => YearPhotosScreen(year: year),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),
                  ListTile(
                    leading: const Icon(Icons.favorite, color: Color(0xFF9c51b6),  ),
                    title: const Text('Favorites', style: TextStyle(color: Color(0xFF9c51b6) , fontWeight: FontWeight.w700)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/favorites');
                    },
                  ),
                  Expanded(child: Container()),
                  ListTile(
                    leading: const Icon(Icons.info, color: Color(0xFF9c51b6)),
                    title: const Text('Info', style: TextStyle(color: Color(0xFF9c51b6) , fontWeight: FontWeight.w700)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/info');
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
      backgroundColor: const Color(0xffD4BEE4),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            if (_memoryPhotos.isNotEmpty)
              Text(
                "Güzel geçmiş anılarımızdan💜",
                style: TextStyle(
                  fontSize: 22,
                  color: Color(0xFF9c51b6),
                  letterSpacing: 1.2,
                  shadows: [
                    Shadow(
                      blurRadius: 1.0,
                    )
                  ]
                ),
              ),
            const SizedBox(height: 40), // Add some space at the top
            if (_memoryPhotos.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0), // Add horizontal padding
                child: CarouselSlider(
                  options: CarouselOptions(
                    height: 400.0, // Increase the height
                    enlargeCenterPage: true,
                    autoPlay: true,
                    aspectRatio: 16 / 9,
                    autoPlayCurve: Curves.fastOutSlowIn,
                    enableInfiniteScroll: true,
                    autoPlayAnimationDuration: const Duration(milliseconds: 800),
                    viewportFraction: 0.8,
                  ),
                  items: _memoryPhotos.map((photo) {
                    return Builder(
                      builder: (BuildContext context) {
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
                            borderRadius: BorderRadius.circular(20),
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
                    );
                  }).toList(),
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'No memories for today.',
                  style: TextStyle(
                    color: Color(0xFF9c51b6),
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
              ),
             Expanded(
              child: Center(
               child: ElevatedButton(onPressed: (){
                _scaffoldKey.currentState?.openDrawer();
               }, child: Text('Selecet a year to view photos'),
               style: ElevatedButton.styleFrom(
                
            backgroundColor: Color(0xFFD4BEE4), // Text (foreground) color
            elevation: 5, // Shadow elevation
            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15), // Padding
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10), // Rounded corners
               ),),
              ),
            ),
           /* SizedBox(height: 20,),
            ElevatedButton(onPressed: (){

   Navigator.pushNamed(context, '/animation');
            }, child: Text("click"))*/
             )
          ],
        ),
      ),
    );
  }
}


