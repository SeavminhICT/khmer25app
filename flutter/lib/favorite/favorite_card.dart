import 'package:flutter/material.dart';

class FavoriteCard extends StatelessWidget {
  final Map<String, dynamic> product;

  const FavoriteCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image + Discount
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                child: Image.asset(
                  product["img"],
                  height: 130,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

              Positioned(
                left: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    product["discount"],
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Tag
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(product["tag"], style: const TextStyle(fontSize: 11)),
          ),

          const SizedBox(height: 8),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              product["title"],
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),

          const SizedBox(height: 4),

          // Prices
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Text(
                  product["newPrice"],
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold, color: Colors.green),
                ),
                const SizedBox(width: 8),
                Text(
                  product["oldPrice"],
                  style: const TextStyle(
                    fontSize: 12,
                    decoration: TextDecoration.lineThrough,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          // Unit + Favorite Heart
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(product["unit"], style: const TextStyle(fontSize: 12)),
                const Icon(Icons.favorite, color: Colors.red, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
