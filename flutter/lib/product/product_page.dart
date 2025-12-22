import 'package:flutter/material.dart';
import 'package:khmer25/product/model/product_model.dart';

class ProductPage extends StatelessWidget {
  final ProductModel product;
  final double imageHeight;

  const ProductPage({
    super.key,
    required this.product,
    required this.imageHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300, width: 1.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: product.imageUrl.isNotEmpty
                ? Image.network(
                    product.imageUrl,
                    height: imageHeight,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Container(
                    height: imageHeight,
                    width: double.infinity,
                    color: Colors.grey.shade100,
                    child: const Icon(Icons.image_not_supported,
                        size: 40, color: Colors.grey),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (product.tag.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      product.displayTag,
                      style: const TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                  ),
                if (product.tag.isNotEmpty) const SizedBox(height: 8),
                Text(
                  product.title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  product.displayPrice,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade800,
                  ),
                ),
                Text(
                  product.unit,
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
