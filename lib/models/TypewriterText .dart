import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle textStyle;
  final Duration speed;

  const TypewriterText({
    super.key,
    required this.text,
    required this.textStyle,
    this.speed = const Duration(milliseconds: 100),
  });

  @override
  _TypewriterTextState createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  String _displayedText = '';
  int _index = 0;
  Timer? _timer;
  late AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.setReleaseMode(ReleaseMode.loop); 
    _startTyping();
  }

  void _startTyping() {
    _playSound(); // Start the sound when typing begins
    _timer = Timer.periodic(widget.speed, (timer) {
      if (_index < widget.text.length) {
        setState(() {
          _displayedText += widget.text[_index];
          _index++;
        });
      } else {
        _timer?.cancel();
        _stopSound(); // Stop the sound when typing is done
      }
    });
  }

  Future<void> _playSound() async {
    try {
      await _audioPlayer.play(AssetSource('typewriter.mp3'));
      print('Sound started successfully');
    } catch (e) {
      print('Error playing sound: $e');
    }
  }

  

  Future<void> _stopSound() async {
    try {
      await _audioPlayer.stop();
      print('Sound stopped successfully');
    } catch (e) {
      print('Error stopping sound: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopSound(); // Ensure sound stops when widget is disposed
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayedText,
      style: widget.textStyle,
      textAlign: TextAlign.center, // Centralize the text
    );
  }
}
