// splash_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'onboarding_screen.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to your home/main screen after 3 seconds
    Timer(const Duration(seconds: 5), () {
      Navigator.of(context).pushReplacementNamed('/home'); // or use your route
      // Example with MaterialPageRoute:
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Your logo (shopping bag + text)
            Image.asset(
              'assets/images/logo1.png', // Make sure to add your logo in assets
              width: 180,
              height: 180,
            ),
            const SizedBox(height: 20),
            LoadingAnimationWidget.discreteCircle(
              color: Colors.green,
              secondRingColor: Colors.red,
              size: 42,
            ),
          ],
        ),
      ),
    );
  }
}
