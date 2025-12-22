import 'package:flutter/material.dart';
import 'package:khmer25/cart/cart_screen.dart';
import 'package:khmer25/cart/cart_store.dart';
import 'package:khmer25/favorite/favorite_store.dart';
import 'package:khmer25/homePage.dart';
import 'package:khmer25/l10n/lang_store.dart';
import 'package:khmer25/login/api_service.dart';
import 'package:khmer25/product/model/product_model.dart';
import 'package:khmer25/services/analytics_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int qty = 1;
  late bool isFavorite;
  late ProductModel _product;
  List<ProductModel> _related = [];
  bool _loadingDetail = false;
  bool _loadingRelated = false;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    isFavorite = FavoriteStore.isProductFavorite(_productId);
    _trackView(_product);
    _loadDetail();
    _loadRelated();
  }

  String get _productId => _product.id;

  void _addToCart(
    BuildContext context,
    ProductModel product, {
    bool goToCart = false,
    bool showDialogOnly = false,
  }) {
    CartStore.addItem(_cartPayload(product), qty: qty);
    if (showDialogOnly) {
      _showAddedDialog(context, product.title.isNotEmpty ? product.title : 'Item');
      return;
    }
    if (goToCart) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CartScreen()),
      );
    }
  }

  void _showAddedDialog(BuildContext context, String title) {
    showDialog(
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
            Text(
              LangStore.t('dialog.added'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$title ${LangStore.t('dialog.added.desc')}',
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
                child: Text(LangStore.t('dialog.ok')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _cartPayload(ProductModel product) {
    return {
      'id': product.id,
      'title': product.title,
      'img': product.imageUrl,
      'price': product.displayPrice,
      'currency': product.currency,
      'unit': product.unit,
      //can add blog order
    };
  }

  Future<void> _loadDetail() async {
    if (_product.id.isEmpty || !_isNumericId(_product.id)) return;
    setState(() => _loadingDetail = true);
    try {
      final fetched = await ApiService.fetchProductDetail(_product.id);
      if (!mounted) return;
      setState(() {
        _product = fetched;
      });
      _trackView(fetched);
    } catch (_) {} finally {
      if (mounted) setState(() => _loadingDetail = false);
    }
  }

  Future<void> _loadRelated() async {
    setState(() => _loadingRelated = true);
    try {
      final items = await ApiService.fetchProducts();
      if (!mounted) return;
      final filtered = items
          .where((p) =>
              p.id != _product.id &&
              (p.tag == _product.tag || p.subCategory == _product.subCategory))
          .take(6)
          .toList();
      setState(() => _related = filtered);
    } catch (_) {} finally {
      if (mounted) setState(() => _loadingRelated = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final related = _related;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          _product.title,
          style: const TextStyle(color: Colors.black87, fontSize: 16),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_loadingDetail)
              const LinearProgressIndicator(minHeight: 2),
            // Product image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _productImage(_product.imageUrl, 210),
            ),
            const SizedBox(height: 14),
            Text(
              _product.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  _product.displayTag,
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: Colors.black38,
                ),
                const SizedBox(width: 6),
                Text(
                  _product.displaySubCategory,
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      isFavorite = !isFavorite;
                      FavoriteStore.toggleProductFavorite(
                        _favoritePayload(_product),
                      );
                    });
                  },
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: Colors.red,
                  ),
                ),
                const Text('Favorite', style: TextStyle(color: Colors.black87)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _product.displayPrice,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              _product.unit,
              style: const TextStyle(color: Colors.black87, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _QtyButton(
                  icon: Icons.remove,
                  onTap: qty > 1 ? () => setState(() => qty--) : null,
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$qty',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _QtyButton(icon: Icons.add, onTap: () => setState(() => qty++)),
                const Spacer(),
                Expanded(
                  flex: 0,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => _addToCart(context, _product, showDialogOnly: true),
                    child: const Text('Add to Cart'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 0,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => _addToCart(context, _product, goToCart: true),
                    child: const Text('Buy Now'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            if (related.isNotEmpty) ...[
              const Text(
                'Related Products',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 280,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: related.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, index) {
                    final r = related[index];
                    return SizedBox(
                      width: 160,
              child: _RelatedCard(
                product: r,
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetailScreen(product: r),
                      settings: RouteSettings(name: '/product/${r.id}'),
                    ),
                  );
                },
              ),
            );
          },
                ),
              ),
            ],
            if (_loadingRelated && related.isEmpty)
              const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Categories',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_offer),
            label: 'Promotions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorite',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
        ],
        onTap: (index) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => HomePage(initialIndex: index)),
            (route) => false,
          );
        },
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18),
      ),
    );
  }
}

class _RelatedCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;
  const _RelatedCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: _productImage(product.imageUrl, 120),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (product.tag.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        product.tag,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.displayPrice,
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    product.unit,
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
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

Map<String, dynamic> _favoritePayload(ProductModel product) {
  return {
    'id': product.id,
    'title': product.title,
    'img': product.imageUrl,
    'price': product.displayPrice,
    'unit': product.unit,
    'tag': product.tag,
    'subCategory': product.subCategory,
  };
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

bool _isNumericId(String id) {
  return RegExp(r'^\d+$').hasMatch(id);
}

void _trackView(ProductModel product) {
  final price = double.tryParse(
    product.price.replaceAll(RegExp(r'[^0-9.]'), ''),
  );
  AnalyticsService.trackProductViewed(
    id: product.id,
    name: product.title,
    price: price,
  );
}
