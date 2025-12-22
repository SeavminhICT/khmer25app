import 'package:flutter/material.dart';
import 'package:khmer25/product/product_detail_screen.dart';
import 'package:khmer25/product/model/product_model.dart';
import 'package:khmer25/login/api_service.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final double imageHeight;

  const ProductCard({
    super.key,
    required this.product,
    required this.imageHeight,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product),
            settings: RouteSettings(name: '/product/${product.id}'),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300, width: 1.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: _productImage(product.imageUrl, imageHeight),
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
                    maxLines: 1,
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
      ),
    );
  }

  Widget _productImage(String url, double height) {
    final normalized = _normalizeImageUrl(url);
    if (normalized != null) {
      return Image.network(
        normalized,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(height),
      );
    }
    return _placeholder(height);
  }

  Widget _placeholder(double height) {
    return Container(
      height: height,
      width: double.infinity,
      color: Colors.grey.shade100,
      child: const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
    );
  }

  String? _normalizeImageUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('http')) return trimmed;
    if (trimmed.startsWith('/')) return '${ApiService.baseUrl}$trimmed';
    if (trimmed.startsWith('media/')) return '${ApiService.baseUrl}/$trimmed';
    if (trimmed.startsWith('static/')) return '${ApiService.baseUrl}/$trimmed';
    if (trimmed.startsWith('https:/') && !trimmed.startsWith('https://')) {
      return trimmed.replaceFirst('https:/', 'https://');
    }
    return trimmed;
  }
}
