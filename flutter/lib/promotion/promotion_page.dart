import 'package:flutter/material.dart';
import 'promotion_item.dart'; // ← import your widget

class PromotionPage extends StatelessWidget {
  final List<Map<String, dynamic>> items;

  const PromotionPage({super.key, required this.items});

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
        padding: const EdgeInsets.all(12),
        child: GridView.builder(
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.68,
          ),
          itemBuilder: (context, index) {
            return PromotionItem(product: items[index]);
          },
        ),
      ),
    );
  }
}
