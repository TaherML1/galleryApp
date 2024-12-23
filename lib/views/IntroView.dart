import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gallery_app/views/homeScreen.dart';
import 'package:gallery_app/models/TypewriterText .dart';

class IntroInfoWidget extends StatefulWidget {
  const IntroInfoWidget({super.key});

  @override
  State<IntroInfoWidget> createState() => _IntroInfoWidget();
}

class _IntroInfoWidget extends State<IntroInfoWidget> {
  late SharedPreferences _prefs;
  bool _isFirstTime = true;
  late PageController _pageController; // Controller for page navigation
  int _currentPage = 0; // Variable to keep track of the current page index

  @override
  void initState() {
    super.initState();
    _checkFirstTime();
    _pageController = PageController(); // Initialize PageController
    _pageController.addListener(_onPageChanged); // Add listener for page changes
  }

  // Check if it's the first time the app is opened
  Future<void> _checkFirstTime() async {
    _prefs = await SharedPreferences.getInstance();
    bool? firstTime = _prefs.getBool('first_time');
    if (firstTime == false) {
      _isFirstTime = false;
      _navigateToHome();
    }
  }

  // Mark intro as shown and navigate to home
  Future<void> _markIntroAsShown() async {
    await _prefs.setBool('first_time', false);
    _navigateToHome();
  }

  // Navigate to Home screen
  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const Homescreen()),
    );
  }

  void _onPageChanged() {
    setState(() {
      _currentPage = _pageController.page!.round(); // Update current page index
    });
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageChanged); // Remove listener
    _pageController.dispose(); // Dispose of PageController when not needed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Intro Messages', style: TextStyle(color: Colors.white)),
      ),
      body: _isFirstTime
          ? Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: _pageController, // Assign the PageController
                    children: [
                      _buildIntroPage(
                        'Doğum günün dolaysıyla bu uygulamayı sana hediye etmek istiyorum ablacım',
                        const Color.fromARGB(255, 233, 65, 227),
                      ),
                      _buildIntroPage(
                        'Uzun ve mutlu bir ömür diliyorum',
                        Colors.amber[500]!,
                      ),
                      _buildIntroPage(
                        'Seni çok seviyorum ❤️',
                        Colors.purpleAccent,
                      ),
                    ],
                  ),
                ),
                if (_currentPage == 2) // Show button only on the last page
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed: _markIntroAsShown,
                      child: const Text('Go to Home'),
                    ),
                  ),
                // Buttons for navigating between pages
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        if (_pageController.page! > 0) {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: () {
                        if (_pageController.page! < 2) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()), // Show loader until check is done
    );
  }

  Widget _buildIntroPage(String text, Color color) {
    return Container(
      color: color,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: TypewriterText(
            text: text,
            textStyle: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            speed: const Duration(milliseconds: 100),
          ),
        ),
      ),
    );
  }
}





class InfoPageWidget extends StatefulWidget {
  const InfoPageWidget({super.key});

  @override
  State<InfoPageWidget> createState() => _InfoPageWidgetState();
}

class _InfoPageWidgetState extends State<InfoPageWidget> {
  late PageController _pageController; // Controller for page navigation
  int _currentPage = 0; // Variable to keep track of the current page index

  @override
  void initState() {
    super.initState();
    _pageController = PageController(); // Initialize PageController
    _pageController.addListener(_onPageChanged); // Add listener for page changes
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageChanged); // Remove listener
    _pageController.dispose(); // Dispose of PageController when not needed
    super.dispose();
  }

  void _onPageChanged() {
    setState(() {
      _currentPage = _pageController.page!.round(); // Update current page index
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Info Page', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF9c51b6),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: Stack(
        children: [
          Container(
           decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [Color(0xFFFAD0C4), Color(0xFF9C51B6)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
            child: Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: _pageController, // Assign the PageController
                    children: [
                      _buildIntroPage('Doğum günün dolayıla bu uygulamayı sana hediye etmek istiyorum ablacım', const Color(0xFFCF9FFF)),
                      _buildIntroPage('Uzun ve mutlu bir ömür diliyorum', const Color(0xFFCF9FFF)),
                      _buildIntroPage('Seni çok seviyorum ❤️', const Color(0xFFCF9FFF)),
                    ],
                  ),
                ),
                if (_currentPage == 2) // Show button only on the last page
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Close the info page and return to home
                      },
                      child: const Text('Back to Home'),
                    ),
                  ),
              ],
            ),
          ),
          // Positioned Next Button
          Positioned(
            right: 16.0,
            top: 100.0, // Adjust this based on your UI needs
            child: IconButton(
              icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
              onPressed: () {
                if (_pageController.page! < 2) { // Adjust this based on the number of pages
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              },
            ),
          ),
          // Positioned Back Button
          Positioned(
            left: 16.0,
            top: 100.0, // Adjust this based on your UI needs
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () {
                if (_pageController.page! > 0) {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroPage(String text, Color color) {
    return Container(
      color: color,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: TypewriterText(
            text: text,
            textStyle: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            speed: const Duration(milliseconds: 100),
          ),
        ),
      ),
    );
  }
}
