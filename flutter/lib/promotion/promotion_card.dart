// lib/product/widget/promotion_card.dart
import 'package:flutter/material.dart';
import 'package:khmer25/product/product_detail_screen.dart';
import 'package:khmer25/product/model/product_model.dart';

class PromotionCard extends StatelessWidget {
  final Map<String, dynamic> product;

  const PromotionCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(
              product: _mapToModel(product),
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE + DISCOUNT BADGE
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.asset(
                    product["img"],
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),

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
                      product["discount"],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              ],
            ),

            // CONTENT
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tag
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      product["tag"],
                      style: const TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Title
                  Text(
                    product["title"],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Pricing row
                  Row(
                    children: [
                      Text(
                        product["newPrice"],
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        product["oldPrice"],
                        style: const TextStyle(
                          fontSize: 12,
                          decoration: TextDecoration.lineThrough,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  ),

                  Text(
                    product["unit"],
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

ProductModel _mapToModel(Map<String, dynamic> product) {
  String normalize(String value) {
    return value.replaceAll(RegExp(r'[^0-9.]'), '');
  }

  final rawPrice = (product['newPrice'] ?? product['price'] ?? '').toString();
  final currency = rawPrice.contains('៛') ? 'KHR' : 'USD';

  return ProductModel(
    id: (product['id'] ?? product['title'] ?? '').toString(),
    title: (product['title'] ?? '').toString(),
    price: normalize(rawPrice),
    currency: currency,
    unit: (product['unit'] ?? '').toString(),
    tag: (product['tag'] ?? '').toString(),
    subCategory: (product['tag'] ?? '').toString(),
    categoryName: (product['categoryName'] ?? product['category_name'] ?? '').toString(),
    subCategoryName: (product['subCategoryName'] ?? product['subcategory_name'] ?? '').toString(),
    imageUrl: (product['img'] ?? '').toString(),
  );
}
