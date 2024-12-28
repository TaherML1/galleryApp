import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class AnimationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Animation Cake'),
        backgroundColor: const Color(0xFF9c51b6),
      ),
      body: Column(
        children: [
   Lottie.asset(
          'assets/animations/happyBirthday.json',  // Path to your animation JSON
          width: 200,
          height: 200,
          fit: BoxFit.fill,
        ), 
        SizedBox(height: 20,),
           Lottie.asset(
          'assets/animations/AnimationCake.json',  // Path to your animation JSON
          width: 200,
          height: 200,
          fit: BoxFit.fill,
        ),
        ],
       
      ),
    );
  }
}
