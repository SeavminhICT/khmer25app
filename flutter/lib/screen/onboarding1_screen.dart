import 'package:flutter/material.dart';
import 'package:khmer25/homePage.dart';
import 'package:khmer25/l10n/lang_store.dart';

class Onboarding1 extends StatelessWidget {
  const Onboarding1({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Image.asset("assets/images/logo1.png", height: 30),
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
                      style: const TextStyle(color: Colors.orange, fontSize: 16),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Orange Image Box
              Container(
                width: 720,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(10),
            
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC34A),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Image.asset(
                    "assets/images/delivery.png",
                    height: 160,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Card with shadow
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 12,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        "assets/images/order.png",
                        height: 60,
                        width: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          LangStore.t('onboarding1.card.title'),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          LangStore.t('onboarding1.card.desc'),
                          style: const TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Title
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  LangStore.t('onboarding1.title'),
                  style: const TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // Description
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  LangStore.t('onboarding1.desc'),
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Get Started button aligned to RIGHT
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end, // ⭐ Move to right
                  children: [
                    SizedBox(
                      width: 140,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HomePage(),
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
                          LangStore.t('onboarding1.cta'),
                          style: const TextStyle(fontSize: 18, color: Colors.white),
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
