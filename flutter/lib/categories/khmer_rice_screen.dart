import 'package:flutter/material.dart';
import 'package:khmer25/cart/cart_screen.dart';
import 'package:khmer25/cart/cart_store.dart';
import 'package:khmer25/categories/product_detail_rice.dart';
import 'package:khmer25/favorite/favorite_store.dart';
import '../../homePage.dart'; // added

class KhmerRiceScreen extends StatefulWidget {
  const KhmerRiceScreen({super.key});

  @override
  State<KhmerRiceScreen> createState() => _KhmerRiceScreenState();
}

class _KhmerRiceScreenState extends State<KhmerRiceScreen> {
  int selectedMain = 0;
  int selectedSub = 0;

  // TOP MAIN CATEGORY ICONS
  final List<Map<String, String>> mainTabs = [
    {"title": "Khmer Rice", "image": "assets/images/categories/cart9.png"},
    {"title": "Kid Product", "image": "assets/images/categories/cart8.png"},
    {"title": "Khmer Product", "image": "assets/images/categories/cart1.png"},
    {"title": "Household Items", "image": "assets/images/categories/cart7.png"},
    {"title": "Cosmetics", "image": "assets/images/categories/cart10.png"},
    {"title": "Meat", "image": "assets/images/categories/cart3.png"},
    {"title": "Vegetable", "image": "assets/images/categories/cart4.png"},
    {"title": "Fruit", "image": "assets/images/categories/cart2.png"},
    {"title": "Drinks", "image": "assets/images/categories/cart6.png"},
    {"title": "Cooked Food", "image": "assets/images/categories/cart3.png"},
    {"title": "Meal Package", "image": "assets/images/categories/cart10.png"},
    {"title": "Grocery", "image": "assets/images/categories/cart5.png"},
  ];

  // SUB TABS
  final List<String> subTabs = ['Kon Khmer Rice', 'General Rice'];

  // PRODUCTS
  final List<Map<String, dynamic>> products = [
    {
      "img": "assets/images/products/honey1.jpg",
      "title": "Jasmine Rice Premium",
      "price": "25.50\$",
      "unit": "per Big Bag",
      "tag": "Rice",
      "subCategory": "Kon Khmer Rice",
    },
    {
      "img": "assets/images/products/honey2.jpg",
      "title": "Jasmine Rice Organic",
      "price": "28.50\$",
      "unit": "per Big Bag",
      "tag": "Rice",
      "subCategory": "Kon Khmer Rice",
    },
    {
      "img": "assets/images/products/honey3.jpg",
      "title": "White Rice Quality",
      "price": "22.50\$",
      "unit": "per Big Bag",
      "tag": "Rice",
      "subCategory": "Kon Khmer Rice",
    },
    {
      "img": "assets/images/products/pumpkin.jpg",
      "title": "Brown Rice Natural",
      "price": "20.50\$",
      "unit": "per Big Bag",
      "tag": "Rice",
      "subCategory": "Kon Khmer Rice",
    },
  ];

  @override
  Widget build(BuildContext context) {
    final String currentSub = subTabs[selectedSub];
    final List<Map<String, dynamic>> filteredProducts = products
        .where((p) => p["subCategory"] == currentSub)
        .toList();

    // currentIndex 1 = Categories (matches HomePage bottom nav)
    const int currentIndex = 1;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Khmer Rice',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            _buildMainTabs(),
            const SizedBox(height: 12),
            _buildSubTabs(),
            const SizedBox(height: 12),

            // ===== CONTENT (GRID OR EMPTY TEXT) =====
            Expanded(
              child: filteredProducts.isEmpty
                  ? const Center(
                      child: Text(
                        'No products found for this category.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: GridView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: filteredProducts.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.85,
                            ),
                        itemBuilder: (context, index) {
                          final prod = filteredProducts[index];
                          final isFav = FavoriteStore.isProductFavorite(
                            _productId(prod),
                          );
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ProductDetailRiceScreen(product: prod),
                                ),
                              );
                            },
                            child: _buildProductCard(
                              prod,
                              isFavorite: isFav,
                              onFavorite: () {
                                setState(() {
                                  FavoriteStore.toggleProductFavorite(
                                    _favoritePayload(prod),
                                  );
                                });
                              },
                              onAddToCart: () => _addToCart(prod),
                              onCheckout: () =>
                                  _addToCart(prod, goToCart: true),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        onTap: (i) {
          // Navigate to HomePage and open appropriate tab
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => HomePage(initialIndex: i)),
          );
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'ទំព័រដើម'),
          BottomNavigationBarItem(icon: Icon(Icons.category), label: 'ប្រភេទ'),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_offer),
            label: '% ការបញ្ចុះតម្លៃ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'ផលិតផល',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_outline),
            label: 'ចំណូលចិត្ត',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'គណនី'),
        ],
      ),
    );
  }

  // =======================
  // TOP HORIZONTAL CATEGORY ICONS
  // =======================
  Widget _buildMainTabs() {
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: mainTabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final item = mainTabs[index];
          final bool active = index == selectedMain;

          return GestureDetector(
            onTap: () => setState(() => selectedMain = index),
            child: Column(
              children: [
                Container(
                  height: 52,
                  width: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(
                      color: active ? Colors.green : Colors.grey.shade300,
                      width: 1.8,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      item["image"] as String,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 80,
                  child: Text(
                    item["title"] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: active ? Colors.green : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // =======================
  // SUB CATEGORY PILLS (chips)
  // =======================
  Widget _buildSubTabs() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: subTabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final bool active = index == selectedSub;

          return GestureDetector(
            onTap: () => setState(() => selectedSub = index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: active ? Colors.green : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: active ? Colors.green : Colors.grey.shade400,
                  width: 1.2,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                subTabs[index],
                style: TextStyle(
                  color: active ? Colors.white : Colors.black87,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // =======================
  // PRODUCT CARD (grid item)
  // =======================
  Widget _buildProductCard(
    Map<String, dynamic> product, {
    required bool isFavorite,
    required VoidCallback onFavorite,
    required VoidCallback onAddToCart,
    required VoidCallback onCheckout,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // image at top
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: Image.asset(
              product["img"] as String,
              height: 90, // reduced image height
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 90,
                color: Colors.grey.shade300,
                child: const Icon(Icons.image_not_supported),
              ),
            ),
          ),

          // content with spacing
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // tag pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    product["tag"] as String,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // title
                Text(
                  product["title"] as String,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Colors.black,
                  ),
                ),

                const SizedBox(height: 8),

                // price
                Text(
                  product["price"] as String,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),

                const SizedBox(height: 4),

                // unit
                Text(
                  product["unit"] as String,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),

                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.grey,
                        size: 20,
                      ),
                      onPressed: onFavorite,
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(
                        Icons.add_shopping_cart,
                        color: Colors.green,
                        size: 20,
                      ),
                      onPressed: onAddToCart,
                    ),
                    TextButton(
                      onPressed: onCheckout,
                      child: const Text(
                        'Buy',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _productId(Map<String, dynamic> product) =>
      (product['id'] ?? product['title'] ?? '').toString();

  Map<String, dynamic> _favoritePayload(Map<String, dynamic> product) {
    return {
      'id': _productId(product),
      'title': product['title'],
      'img': product['img'],
      'price': product['price'],
      'unit': product['unit'],
      'tag': product['tag'],
      'subCategory': product['subCategory'],
    };
  }

  Map<String, dynamic> _cartPayload(Map<String, dynamic> product) {
    return {
      'id': _productId(product),
      'title': product['title'] ?? '',
      'img': product['img'] ?? '',
      'price': product['price'] ?? '',
      'unit': product['unit'] ?? '',
      'tag': product['tag'] ?? '',
    };
  }

  void _addToCart(Map<String, dynamic> product, {bool goToCart = false}) {
    CartStore.addItem(_cartPayload(product), qty: 1);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product['title'] ?? 'Item'} added to cart'),
        duration: const Duration(seconds: 2),
      ),
    );
    if (goToCart) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CartScreen()),
      );
    }
  }
}
