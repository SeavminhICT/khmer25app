import 'package:flutter/material.dart';
import 'package:khmer25/l10n/lang_store.dart';
import 'onboarding1_screen.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Image.asset("assets/images/logo.jpg", height: 30),
                        const SizedBox(width: 8),
                        const Text(
                          "Khmer 25",
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      LangStore.t('onboarding.skip'),
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Orange Box
              Container(
                width: 720,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(10),
                height: isMobile ? 260 : 400,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC34A),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      left: 60,
                      bottom: 20,
                      top: 40,
                      child: Image.asset(
                        "assets/images/farmer.png",
                        height: isMobile ? 170 : 240,
                      ),
                    ),
                    Positioned(
                      right: 60,
                      top: 40,
                      child: Image.asset(
                        "assets/images/phone.png",
                        height: isMobile ? 200 : 300,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              Text(
                LangStore.t('onboarding.title'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),

              const SizedBox(height: 25),

              // Bullet points
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    BulletPoint(text: LangStore.t('onboarding.bullet1')),
                    BulletPoint(text: LangStore.t('onboarding.bullet2')),
                    BulletPoint(text: LangStore.t('onboarding.bullet3')),
                  ],
                ),
              ),

              const SizedBox(height: 35),

              // Button on Right
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: 150,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const Onboarding1(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          LangStore.t('onboarding.next'),
                          style: const TextStyle(fontSize: 17, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// Bullet point widget
class BulletPoint extends StatelessWidget {
  final String text;
  const BulletPoint({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
