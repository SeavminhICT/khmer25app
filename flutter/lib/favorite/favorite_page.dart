import 'package:flutter/material.dart';

class FavoritePage extends StatelessWidget {
  const FavoritePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          "My Favorite",
          style: TextStyle(
            color: Color(0xFF2C5F2D),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 10),
            _favoriteCard(),
          ],
        ),
      ),
    );
  }

  Widget _favoriteCard() {
    return Container(
      width: 160,
      padding: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image + Discount Badge
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                child: Image.asset(
                  "assets/promotion/manago.webp",
                  height: 130,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

              // Discount badge
              Positioned(
                left: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 206, 50, 39),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    "-30%",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
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
            child: const Text(
              "Fruit",
              style: TextStyle(
                fontSize: 11,
                color: Colors.black54,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              "Mango",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 4),

          // Price Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                const Text(
                  "1.00\$",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "1.70\$",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ),
          ),

          // Unit + Favorite Icon
          Padding(
            padding: const EdgeInsets.only(left: 10, right: 10, top: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  "per Kg",
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                Icon(Icons.favorite, color: Colors.red, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
