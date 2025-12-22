import 'package:flutter/material.dart';
import 'package:khmer25/cart/cart_screen.dart';
import 'package:khmer25/cart/cart_store.dart';
import 'package:khmer25/favorite/favorite_store.dart';

class ProductDetailRiceScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  const ProductDetailRiceScreen({super.key, required this.product});

  @override
  State<ProductDetailRiceScreen> createState() =>
      _ProductDetailRiceScreenState();
}

class _ProductDetailRiceScreenState extends State<ProductDetailRiceScreen> {
  int qty = 1;
  late bool isFavorite;

  String get _productId =>
      (widget.product['id'] ?? widget.product['title'] ?? '').toString();
  String get _resolvedImage => _resolveImageFromProduct();

  @override
  void initState() {
    super.initState();
    isFavorite = FavoriteStore.isProductFavorite(_productId);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.product['title'] as String? ?? '';
    final price = widget.product['price'] as String? ?? '';
    final unit = widget.product['unit'] as String? ?? '';
    final tag = widget.product['tag'] as String? ?? '';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(title, style: const TextStyle(color: Colors.black)),
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: Colors.red,
            ),
            onPressed: _toggleFavorite,
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined, color: Colors.green),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CartScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _ProductImage(imagePath: _resolvedImage, height: 240),
              ),
              const SizedBox(height: 12),

              // title & meta
              Text(title,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(16)),
                    child: Text(tag,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey)),
                  ),
                  const SizedBox(width: 12),
                  Text(price,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Text('/ $unit', style: const TextStyle(color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 12),

              // description placeholder
              const Text('Description',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              const Text(
                'This is a product detail description. Replace with actual product information, origin, packaging, and other details.',
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 16),

              // quantity + actions
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade300)),
                    child: Row(
                      children: [
                        IconButton(
                            onPressed: () {
                              setState(() {
                                if (qty > 1) qty--;
                              });
                            },
                            icon: const Icon(Icons.remove),
                            iconSize: 18),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text('$qty',
                              style: const TextStyle(fontSize: 16)),
                        ),
                        IconButton(
                            onPressed: () {
                              setState(() {
                                qty++;
                              });
                            },
                            icon: const Icon(Icons.add),
                            iconSize: 18),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _addToCart(),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green),
                      child: const Text('Add to Cart'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _addToCart(goToCart: true),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    child: const Text('Buy Now'),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // related (simple horizontal list)
              const Text('Related Products',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 3,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => SizedBox(
                    width: 110,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _ProductImage(
                              imagePath: _resolvedImage,
                              height: double.infinity,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12)),
                        Text(price,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleFavorite() {
    setState(() {
      isFavorite = !isFavorite;
      FavoriteStore.toggleProductFavorite(_favoritePayload());
    });
  }

  Future<void> _addToCart({bool goToCart = false}) async {
    CartStore.addItem(_cartPayload(), qty: qty);
    await _showAddedDialog();
    if (goToCart) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CartScreen()),
      );
    }
  }

  Future<void> _showAddedDialog() {
    final title = widget.product['title'] ?? 'Item';
    return showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.green, width: 2),
              ),
              child: const Icon(Icons.check, size: 38, color: Colors.green),
            ),
            const SizedBox(height: 14),
            const Text(
              'Added to cart',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$title has been added to your cart.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black87),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 120,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _favoritePayload() {
    return {
      'id': _productId,
      'title': widget.product['title'],
      'img': _resolvedImage,
      'price': widget.product['price'],
      'unit': widget.product['unit'],
    };
  }

  Map<String, dynamic> _cartPayload() {
    return {
      'id': _productId,
      'title': widget.product['title'] ?? '',
      'img': _resolvedImage,
      'price': widget.product['price'] ?? '',
      'unit': widget.product['unit'] ?? '',
    };
  }

  String _resolveImageFromProduct() {
    final candidates = [
      widget.product['img'],
      widget.product['image'],
      widget.product['images'],
    ];

    for (final candidate in candidates) {
      if (candidate == null) continue;
      if (candidate is List && candidate.isNotEmpty) {
        final first = candidate.first?.toString() ?? '';
        if (first.trim().isNotEmpty) return _normalizeImage(first);
      } else {
        final value = candidate.toString();
        if (value.trim().isNotEmpty) return _normalizeImage(value);
      }
    }
    return '';
  }

  String _normalizeImage(String path) {
    String trimmed = path.trim();
    if (trimmed.isEmpty) return trimmed;

    // Decode encoded URLs if present.
    try {
      final decoded = Uri.decodeComponent(trimmed);
      if (decoded.startsWith('http')) return decoded;
      trimmed = decoded;
    } catch (_) {
      // ignore decode errors
    }

    if (trimmed.startsWith('http') || trimmed.contains('://')) return trimmed;
    if (trimmed.startsWith('assets/')) return trimmed;

    const host = 'http://127.0.0.1:8000';
    if (trimmed.startsWith('/')) return '$host$trimmed';
    return '$host/$trimmed';
  }
}

class _ProductImage extends StatelessWidget {
  final String imagePath;
  final double height;

  const _ProductImage({required this.imagePath, required this.height});

  @override
  Widget build(BuildContext context) {
    final path = imagePath.trim();
    if (path.isEmpty) {
      return _placeholder();
    }

    final isNetwork = path.startsWith('http');
    final ImageProvider<Object> provider =
        isNetwork ? NetworkImage(path) : AssetImage(path);

    return Image(
      image: provider,
      width: double.infinity,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      height: height,
      width: double.infinity,
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: const Icon(Icons.image_not_supported, color: Colors.grey),
    );
  }
}
