import 'package:flutter/material.dart';

class PromotionItem extends StatelessWidget {
  final Map<String, dynamic> product;

  const PromotionItem({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // IMAGE + DISCOUNT
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.asset(
                  product["img"] ?? "",
                  height: 110,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 110,
                    color: Colors.grey.shade200,
                    alignment: Alignment.center,
                    child: const Text("Image Not Found"),
                  ),
                ),
              ),

              // DISCOUNT BADGE
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    product["discount"] ?? "",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // CONTENT SECTION
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // TAG LABEL
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    product["tag"] ?? "",
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                ),

                const SizedBox(height: 6),

                // TITLE
                Text(
                  product["title"] ?? "",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 6),

                // PRICES
                Row(
                  children: [
                    Text(
                      product["newPrice"] ?? "",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      product["oldPrice"] ?? "",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black45,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ),

                // UNIT
                Text(
                  product["unit"] ?? "",
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
