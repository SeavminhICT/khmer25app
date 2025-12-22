import 'package:flutter/material.dart';
import 'package:khmer25/models/category_item.dart';

class ListCategoryTile extends StatelessWidget {
  final CategoryItem category;
  final bool isFavorite;
  final VoidCallback? onTap; // added
  final VoidCallback? onFavoriteTap;
  final VoidCallback? onAddToCart;

  const ListCategoryTile({
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
      borderRadius: BorderRadius.circular(14),
      onTap: onTap, // use callback
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 3,
              offset: Offset(0, 1),
            )
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(14)),
              child: _CategoryImage(imagePath: category.resolvedImage),
            ),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.titleKh,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      "${category.subCount} subcategories",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Explore",
                            style:
                                TextStyle(color: Colors.green, fontSize: 13)),
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
                                size: 18,
                              ),
                              onPressed: onFavoriteTap,
                            ),
                            const SizedBox(width: 6),
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const Icon(Icons.add_shopping_cart,
                                  size: 18, color: Colors.green),
                              onPressed: onAddToCart,
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.arrow_forward,
                                size: 16, color: Colors.green),
                          ],
                        ),
                      ],
                    )
                  ],
                ),
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
    final ImageProvider<Object> provider =
        isNetwork ? NetworkImage(imagePath) : AssetImage(imagePath);

    return Image(
      image: provider,
      width: 90,
      height: 90,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: 90,
        height: 90,
        color: Colors.grey.shade200,
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image, color: Colors.grey),
      ),
    );
  }
}
