// favorite_screen.dart
import 'package:flutter/material.dart';
import 'package:khmer25/favorite/favorite_store.dart';
import 'package:khmer25/l10n/lang_store.dart';
import 'package:khmer25/product/product_detail_screen.dart';
import 'package:khmer25/product/model/product_model.dart';

class FavoriteScreen extends StatelessWidget {
  const FavoriteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          LangStore.t('favorite.title'),
          style: const TextStyle(color: Colors.green),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: ValueListenableBuilder<List<Map<String, dynamic>>>(
        valueListenable: FavoriteStore.favoriteProducts,
        builder: (context, productFavs, _) {
          return ValueListenableBuilder<List<Map<String, dynamic>>>(
            valueListenable: FavoriteStore.favoriteGroups,
            builder: (context, groupFavs, __) {
              if (productFavs.isEmpty && groupFavs.isEmpty) {
                return Center(
                  child: Text(
                    LangStore.t('favorite.empty'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (productFavs.isNotEmpty) ...[
                      Text(
                        LangStore.t('nav.products'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: productFavs.length,
                        itemBuilder: (_, index) {
                          final item = productFavs[index];
                          return _FavoriteProductCard(
                            product: item,
                            onRemove: () => FavoriteStore.toggleProductFavorite(item),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                    if (groupFavs.isNotEmpty) ...[
                      Text(
                        LangStore.t('favorite.groups'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.72,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: groupFavs.length,
                        itemBuilder: (_, index) {
                          final item = groupFavs[index];
                          return _FavoriteGroupPortrait(
                            title: item['title'] ?? '',
                            count: item['count'] ?? '',
                            image: item['image'] ?? '',
                            onRemove: () => FavoriteStore.toggleFavorite(item),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _FavoriteProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onRemove;
  const _FavoriteProductCard({required this.product, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final model = _mapToModel(product);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: model),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with heart overlay
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                  child: _FavoriteImage(
                    imagePath: product["img"] ?? model.imageUrl,
                    height: 130,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.favorite, color: Colors.red, size: 20),
                      onPressed: onRemove,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                model.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                model.displayPrice,
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Text(
                model.unit,
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}

class _FavoriteGroupPortrait extends StatelessWidget {
  final String title;
  final String count;
  final String image;
  final VoidCallback onRemove;

  const _FavoriteGroupPortrait({
    required this.title,
    required this.count,
    required this.image,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with heart overlay
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                child: _FavoriteImage(imagePath: image, height: 130),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.favorite, color: Colors.red, size: 20),
                    onPressed: onRemove,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              count,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _FavoriteImage extends StatelessWidget {
  final String imagePath;
  final double height;

  const _FavoriteImage({required this.imagePath, required this.height});

  @override
  Widget build(BuildContext context) {
    final path = imagePath.trim();
    if (path.isEmpty) {
      return Container(
        height: height,
        width: double.infinity,
        color: Colors.grey.shade200,
        alignment: Alignment.center,
        child: const Icon(Icons.image_not_supported, color: Colors.grey),
      );
    }

    final resolved = path.startsWith('/') ? 'http://127.0.0.1:8000$path' : path;
    final isNetwork = resolved.startsWith('http');
    final ImageProvider<Object> provider =
        isNetwork ? NetworkImage(resolved) : AssetImage(resolved);

    return Image(
      image: provider,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        height: height,
        width: double.infinity,
        color: Colors.grey.shade200,
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image, color: Colors.grey),
      ),
    );
  }
}

ProductModel _mapToModel(Map<String, dynamic> product) {
  String normalizePrice(String value) {
    return value.replaceAll(RegExp(r'[^0-9.]'), '');
  }

  final rawPrice = (product['price'] ?? '').toString();
  final price = normalizePrice(rawPrice);
  final currency = rawPrice.contains('៛') ? 'KHR' : 'USD';

  return ProductModel(
    id: (product['id'] ?? product['title'] ?? '').toString(),
    title: (product['title'] ?? '').toString(),
    price: price,
    currency: currency,
    unit: (product['unit'] ?? '').toString(),
    tag: (product['tag'] ?? product['subCategory'] ?? '').toString(),
    subCategory: (product['subCategory'] ?? '').toString(),
    categoryName: (product['categoryName'] ?? product['category_name'] ?? '').toString(),
    subCategoryName: (product['subCategoryName'] ?? product['subcategory_name'] ?? '').toString(),
    imageUrl: (product['img'] ?? '').toString(),
  );
}
