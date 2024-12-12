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

  @override
  void initState() {
    super.initState();
    _checkFirstTime();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Intro Messages'),
      ),
      body: _isFirstTime
          ? Column(
              children: [
                Expanded(
                  child: PageView(
                    children: [
                      _buildIntroPage('Doğum günün dolaysıla bu uygulamayı sana hediye etmek istiyorum ablacım', const Color.fromARGB(255, 233, 65, 227)!),
                      _buildIntroPage('Uzun ve mutlu bir ömür diliyorum', Colors.amber[500]!),
                      _buildIntroPage('Seni çok seviyorum ❤️', Colors.purpleAccent),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: _markIntroAsShown,
                    child: const Text('Go to Home'),
                  ),
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

class InfoPageWidget extends StatelessWidget {
  const InfoPageWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Info Page'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: PageView(
                children: [
                  _buildIntroPage('Doğum günün dolayıla bu uygulamayı sana hediye etmek istiyorum ablacım', const Color.fromARGB(255, 233, 65, 227)!),
                  _buildIntroPage('Uzun ve mutlu bir ömür diliyorum', Colors.amber[500]!),
                  _buildIntroPage('Seni çok seviyorum ❤️', Colors.purpleAccent),
                ],
              ),
            ),
          ),
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

