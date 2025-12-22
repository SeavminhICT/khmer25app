import 'package:flutter/material.dart';
import 'package:khmer25/models/category_item.dart';

class GridCategoryCard extends StatelessWidget {
  final CategoryItem category;
  final bool isFavorite;
  final VoidCallback? onTap; // added
  final VoidCallback? onFavoriteTap;
  final VoidCallback? onAddToCart;

  const GridCategoryCard({
    super.key,
    required this.category,
    this.onTap,
    this.onFavoriteTap,
    this.onAddToCart,
    this.isFavorite = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap, // use callback
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------------- IMAGE (bigger like your screenshot)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: SizedBox(
                height: 125,
                width: double.infinity,
                child: _CategoryImage(imagePath: category.resolvedImage),
              ),
            ),

            // ---------------- TEXT AREA (tighter)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Title
                  Text(
                    category.titleEn,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 6),

                  // Subcategories text
                  Text(
                    '${category.subCount} subcategories',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 10,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Bottom row: Explore + Heart icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Text(
                            "Explore",
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward,
                              size: 17, color: Colors.green),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(
                              isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isFavorite ? Colors.red : Colors.grey,
                              size: 20,
                            ),
                            onPressed: onFavoriteTap,
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.add_shopping_cart,
                                size: 20, color: Colors.green),
                            onPressed: onAddToCart,
                          ),
                        ],
                      ),
                    ],
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

class _CategoryImage extends StatelessWidget {
  final String imagePath;

  const _CategoryImage({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    final isNetwork = imagePath.startsWith('http');
    final ImageProvider<Object> imageProvider =
        isNetwork ? NetworkImage(imagePath) : AssetImage(imagePath);

    return Image(
      image: imageProvider,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey.shade200,
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image, color: Colors.grey),
      ),
    );
  }
}
