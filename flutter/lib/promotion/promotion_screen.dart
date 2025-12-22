// promotion_screen.dart
import 'package:flutter/material.dart';
import 'package:khmer25/promotion/fake_data.dart';
import 'package:khmer25/promotion/promotion_card.dart';

class PromotionScreen extends StatelessWidget {
  const PromotionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Promotion",
          style: TextStyle(color: Colors.green),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          itemCount: promotionProducts.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.68,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (_, index) {
            return PromotionCard(
              product: promotionProducts[index],
            );
          },
        ),
      ),
    );
  }
}
