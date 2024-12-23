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
    _startTyping();
  }

  void _startTyping() {
    _timer = Timer.periodic(widget.speed, (timer) {
      if (_index < widget.text.length) {
        setState(() {
          _displayedText += widget.text[_index];
          _index++;
        });
        _playSound();
      } else {
        _timer?.cancel();
      }
    });
  }

  Future<void> _playSound() async {
    try {
          await _audioPlayer.play(AssetSource('assets/typewriter.mp3'));
      print('Sound played successfully');
    } catch (e) {
      print('Error playing sound: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
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
