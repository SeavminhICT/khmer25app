// ignore_for_file: unused_local_variable
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:khmer25/cart/cart_screen.dart';
import 'package:khmer25/cart/cart_store.dart';
import 'package:khmer25/categories/categories_screen.dart';
import 'package:khmer25/favorite/favorite_screen.dart';
import 'package:khmer25/l10n/lang_store.dart';
import 'package:khmer25/account/account_screen.dart';
import 'package:khmer25/account/order_screen.dart';
import 'package:khmer25/login/api_service.dart';
import 'package:khmer25/models/category_item.dart';
import 'package:khmer25/product/model/product_model.dart';
import 'package:khmer25/product/product_detail_screen.dart';
import 'package:khmer25/product/products_sreen.dart';
import 'package:khmer25/promotion/promotion_screen.dart';
import 'package:khmer25/services/analytics_service.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Lang>(
      valueListenable: LangStore.current,
      builder: (_, __, ___) {
        return MaterialApp(
          title: 'Khmer25',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            fontFamily: 'Khmer',
          ),
          home: const HomePage(),
        );
      },
    );
  }
}

/* --------------------------------------------------------------- */
/*                         HOME PAGE                               */
/* --------------------------------------------------------------- */
class HomePage extends StatefulWidget {
  final int initialIndex;
  const HomePage({super.key, this.initialIndex = 0});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late int _selectedIndex;
  late int _drawerIndex;
  late Lang _selectedLang;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _drawerIndex = widget.initialIndex;
    _selectedLang = LangStore.current.value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _trackTab(_selectedIndex);
    });
  }

  final List<Map<String, dynamic>> _drawerMenu = [
    {'icon': Icons.person, 'label': 'drawer.profile', 'index': 6},
    {'icon': Icons.favorite, 'label': 'drawer.favorite', 'index': 4},
    {'icon': Icons.delivery_dining, 'label': 'drawer.delivery', 'index': 3},
    {'icon': Icons.call, 'label': 'drawer.contact', 'index': 0},
    {'icon': Icons.login, 'label': 'drawer.signin', 'index': 6},
  ];

  void _onDrawerTap(int index) {
    setState(() {
      _drawerIndex = index;
      _selectedIndex = index;
    });
    _trackTab(index);
    Navigator.pop(context);
  }

  void _toggleLanguage() {
    setState(() {
      _selectedLang = _selectedLang == Lang.en ? Lang.km : Lang.en;
      LangStore.toggle();
    });
  }

  void _trackTab(int index) {
    const names = [
      'Home',
      'Categories',
      'Promotions',
      'Products',
      'Favorite',
      'Orders',
      'Account',
    ];
    if (index < 0 || index >= names.length) return;
    AnalyticsService.trackScreen(names[index]);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isTablet = screenWidth > 600;
    final drawerPages = [
      const HomeBody(),
      const CategoriesScreen(),
      const PromotionScreen(),
      const ProductsSreen(),
      const FavoriteScreen(),
      const OrderScreen(),
      const AccountScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.jpg',
              width: isTablet ? 50 : 40,
              height: isTablet ? 50 : 40,
            ),
            const SizedBox(width: 8),
            const Text('Khmer25', style: TextStyle(color: Colors.orange)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {},
          ),
          ValueListenableBuilder(
            valueListenable: CartStore.items,
            builder: (context, cartItems, _) {
              final count = cartItems.length;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.shopping_cart_outlined,
                      color: Colors.black,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CartScreen(),
                          settings: const RouteSettings(name: '/cart'),
                        ),
                      );
                    },
                  ),
                  if (count > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.black),
            onPressed: () {
              setState(() {
                _selectedIndex = 6;
                _drawerIndex = 6;
              });
              _trackTab(6);
            },
          ),
        ],
      ),

      // -------------------------- DRAWER --------------------------
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.green),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundImage: AssetImage('assets/images/logo.jpg'),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Khmer25',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        LangStore.t('drawer.welcome'),
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView.builder(
                itemCount: _drawerMenu.length,
                itemBuilder: (ctx, i) {
                  final item = _drawerMenu[i];
                  final bool isSelected = _drawerIndex == item['index'];
                  return ListTile(
                    leading: Icon(
                      item['icon'],
                      color: isSelected ? Colors.green : Colors.grey[700],
                    ),
                    title: Text(
                      LangStore.t(item['label']),
                      style: TextStyle(
                        color: isSelected ? Colors.green : Colors.black87,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    selectedTileColor: Colors.green.withOpacity(0.1),
                    onTap: () => _onDrawerTap(item['index']),
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  _langButton(LangStore.t('lang.en'), _selectedLang == Lang.en),
                  const SizedBox(width: 8),
                  _langButton(LangStore.t('lang.km'), _selectedLang == Lang.km),
                ],
              ),
            ),
          ],
        ),
      ),

      body: drawerPages[_drawerIndex],

      

      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: LangStore.t('nav.home'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.category),
            label: LangStore.t('nav.categories'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.local_offer),
            label: LangStore.t('nav.promotions'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.inventory),
            label: LangStore.t('nav.products'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.favorite_outline),
            label: LangStore.t('nav.favorite'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.receipt_long),
            label: LangStore.t('nav.orders'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: LangStore.t('nav.account'),
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (i) {
          setState(() {
            _selectedIndex = i;
            _drawerIndex = i;
          });
          _trackTab(i);
        },
      ),
    );
  }

  Widget _langButton(String text, bool selected) {
    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: selected ? Colors.green : Colors.grey[300],
          foregroundColor: selected ? Colors.white : Colors.black,
        ),
        onPressed: _toggleLanguage,
        child: Text(text, style: const TextStyle(fontSize: 13)),
      ),
    );
  }
}

/* --------------------------------------------------------------- */
/*                         HOME BODY (FIXED)                       */
/* --------------------------------------------------------------- */

class HomeBody extends StatelessWidget {
  const HomeBody({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isTablet = screenWidth > 600;
    final bool isDesktop = screenWidth > 1024;
    final EdgeInsets horizontalPadding =
        EdgeInsets.symmetric(horizontal: isTablet ? 20 : 14);
    final double sectionGap = isTablet ? 18 : 12;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF6F8F5), Color(0xFFFFFBF3)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: isTablet ? 16 : 10),
            Padding(
              padding: horizontalPadding,
              child: BannerCarousel(height: screenWidth * 0.38),
            ),
            SizedBox(height: sectionGap),
            Padding(
              padding: horizontalPadding,
              child: SectionTitle(title: LangStore.t('sectiontitle.type')),
            ),
            SectionShell(
              margin: horizontalPadding,
              child: CategoryGrid(isTablet: isTablet),
            ),
            SizedBox(height: sectionGap),
            Padding(
              padding: horizontalPadding,
              child: SectionTitle(
                title: LangStore.t('sectiontitle.products'),
                trailing: LangStore.t('sectiontitle.viewall'),
              ),
            ),
            SizedBox(height: isTablet ? 8 : 6),
            SectionShell(
              margin: horizontalPadding,
              child: ProductHorizontalList(
                section: 'hot',
                itemWidth: isDesktop ? 280 : (isTablet ? 200 : 150),
              ),
            ),
            SizedBox(height: sectionGap),
            Padding(
              padding: horizontalPadding,
              child: SectionTitle(
                title: LangStore.t('sectiontitle.discount'),
                trailing: LangStore.t('sectiontitle.viewall'),
              ),
            ),
            SizedBox(height: isTablet ? 8 : 6),
            SectionShell(
              margin: horizontalPadding,
              child: ProductHorizontalList(
                section: 'discount',
                itemWidth: isDesktop ? 280 : (isTablet ? 200 : 150),
              ),
            ),
            SizedBox(height: sectionGap),
            Padding(
              padding: horizontalPadding,
              child: const SpecialOfferCard(),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}

/* --------------------------------------------------------------- */
/*                    RE-USABLE WIDGETS (unchanged)                */
/* --------------------------------------------------------------- */

class BannerCarousel extends StatelessWidget {
  final double height;
  const BannerCarousel({super.key, this.height = 180});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: ApiService.fetchBanners(),
      builder: (context, snapshot) {
        final banners = snapshot.data;
        final paths = (banners ?? []).where((e) => e.trim().isNotEmpty).toList();
        if (paths.isEmpty) {
          return const SizedBox.shrink();
        }

        return CarouselSlider(
          options: CarouselOptions(
            height: height,
            autoPlay: true,
            enlargeCenterPage: true,
            viewportFraction: MediaQuery.of(context).size.width > 600 ? 0.7 : 0.9,
          ),
          items: paths
              .map(
                (path) => ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: _bannerImage(path),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _bannerImage(String path) {
    final trimmed = path.trim();
    if (trimmed.isEmpty) {
      return _placeholder();
    }
    if (trimmed.startsWith('http')) {
      return Image.network(
        trimmed,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    if (trimmed.startsWith('/')) {
      return Image.network(
        '${ApiService.baseUrl}$trimmed',
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return Image.asset(
      trimmed,
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (_, __, ___) => _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      color: Colors.grey.shade200,
      child: const Icon(Icons.image_not_supported, color: Colors.grey),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String? trailing;
  const SectionTitle({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2A24),
          ),
        ),
        if (trailing != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE6F3ED),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              trailing!,
              style: const TextStyle(
                color: Color(0xFF0E7A5F),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

class SectionShell extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry margin;

  const SectionShell({super.key, required this.child, required this.margin});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class CategoryGrid extends StatefulWidget {
  final bool isTablet;
  const CategoryGrid({super.key, this.isTablet = false});

  @override
  State<CategoryGrid> createState() => _CategoryGridState();
}

class _CategoryGridState extends State<CategoryGrid> {
  static const List<Map<String, String>> _fallbackCats = [
    
  ];

  late Future<List<CategoryItem>> _futureCategories;

  @override
  void initState() {
    super.initState();
    _futureCategories = ApiService.fetchCategories();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 1024 ? 8 : (screenWidth > 600 ? 6 : 4);

    return FutureBuilder<List<CategoryItem>>(
      future: _futureCategories,
      builder: (context, snapshot) {
        final items = snapshot.data;
        final hasData = items != null && items.isNotEmpty;
        final cats = hasData ? items! : null;

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          padding: EdgeInsets.all(widget.isTablet ? 12 : 8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.95,
            mainAxisSpacing: widget.isTablet ? 12 : 8,
            crossAxisSpacing: widget.isTablet ? 12 : 8,
          ),
          itemCount: hasData ? cats!.length : _fallbackCats.length,
          itemBuilder: (_, i) {
            if (hasData) {
              final cat = cats![i];
              final name = cat.titleEn.isNotEmpty ? cat.titleEn : cat.titleKh;
              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _openCategory(context, name),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7FAF7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E9E4)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _categoryImage(cat.resolvedImage),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2E3B34),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            } else {
              final cat = _fallbackCats[i];
              final name = cat['label'] ?? '';
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _openCategory(context, name),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7FAF7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E9E4)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          cat['icon']!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2E3B34),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }

  Widget _categoryImage(String path) {
    if (path.isEmpty) {
      return Container(
        width: 56,
        height: 56,
        color: const Color(0xFFEFF3F1),
        alignment: Alignment.center,
        child: const Icon(
          Icons.image_not_supported,
          size: 22,
          color: Colors.grey,
        ),
      );
    }
    if (path.startsWith('http')) {
      return Image.network(
        path,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 56,
          height: 56,
          color: const Color(0xFFEFF3F1),
          alignment: Alignment.center,
          child: const Icon(
            Icons.image_not_supported,
            size: 22,
            color: Colors.grey,
          ),
        ),
      );
    }
    return Image.asset(
      path,
      width: 56,
      height: 56,
      fit: BoxFit.cover,
    );
  }

  void _openCategory(BuildContext context, String name) {
    if (name.isEmpty) return;
    AnalyticsService.trackCategoryViewed(id: name, name: name);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductsSreen(initialFilter: name),
        settings: RouteSettings(name: '/products'),
      ),
    );
  }
}

class ProductHorizontalList extends StatefulWidget {
  final String section;
  final double itemWidth;

  const ProductHorizontalList({
    super.key,
    required this.section,
    this.itemWidth = 150,
  });

  @override
  State<ProductHorizontalList> createState() => _ProductHorizontalListState();
}

class _ProductHorizontalListState extends State<ProductHorizontalList> {
  late Future<List<ProductModel>> _futureProducts;

  @override
  void initState() {
    super.initState();
    _futureProducts = ApiService.fetchProducts();
  }

  List<ProductModel> _filterBySection(List<ProductModel> products) {
    final key = widget.section.trim().toLowerCase();
    if (key.isEmpty) return products;
    return products.where((p) => _matchesSection(p, key)).toList();
  }

  bool _matchesSection(ProductModel product, String key) {
    final tags = [
      product.tag,
      product.categoryName,
      product.subCategoryName,
      product.displayTag,
    ];
    for (final tag in tags) {
      final normalized = tag.trim().toLowerCase();
      if (normalized.isEmpty) continue;
      if (normalized == key) return true;
      if (normalized.contains(key) || key.contains(normalized)) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return SizedBox(
      height: isTablet ? 260 : 210,
      child: FutureBuilder<List<ProductModel>>(
        future: _futureProducts,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final products = _filterBySection(snapshot.data ?? []);
          if (products.isEmpty) {
            return const SizedBox.shrink();
          }
          return _buildApiList(products, isTablet);
        },
      ),
    );
  }

  Widget _buildApiList(List<ProductModel> products, bool isTablet) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      primary: false,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 6 : 2),
      itemCount: products.length,
      itemBuilder: (_, i) {
        final p = products[i];
        final priceText = p.displayPrice.isNotEmpty ? p.displayPrice : p.price;

        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductDetailScreen(product: p),
                settings: RouteSettings(name: '/product/${p.id}'),
              ),
            );
          },
          child: Container(
            width: widget.itemWidth,
            margin: EdgeInsets.only(right: isTablet ? 12 : 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFBFA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5EAE6)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: _productImage(
                    p.imageUrl,
                    isTablet ? 140 : 100,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2A24),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDFF3EA),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          priceText,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0E7A5F),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _productImage(String url, double height) {
    final normalized = _normalizeImageUrl(url);
    if (normalized == null) {
      return _placeholder(height);
    }
    if (normalized.startsWith('assets/')) {
      return Image.asset(
        normalized,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(height),
      );
    }
    return Image.network(
      normalized,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _placeholder(height),
    );
  }

  Widget _placeholder(double height) {
    return Container(
      height: height,
      width: double.infinity,
      color: Colors.grey.shade100,
      child: const Icon(Icons.image_not_supported, size: 32, color: Colors.grey),
    );
  }

  String? _normalizeImageUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('http')) return trimmed;
    if (trimmed.startsWith('assets/')) return trimmed;
    if (trimmed.startsWith('/')) return '${ApiService.baseUrl}$trimmed';
    if (trimmed.startsWith('media/')) return '${ApiService.baseUrl}/$trimmed';
    if (trimmed.startsWith('static/')) return '${ApiService.baseUrl}/$trimmed';
    if (trimmed.startsWith('https:/') && !trimmed.startsWith('https://')) {
      return trimmed.replaceFirst('https:/', 'https://');
    }
    return trimmed;
  }
}



class SpecialOfferCard extends StatelessWidget {
  const SpecialOfferCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Container(
      padding: EdgeInsets.all(isTablet ? 30 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0E7A5F), Color(0xFF2C9E6C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),

      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              LangStore.t('special.title'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            Text(
              LangStore.t('special.desc'),
              style: const TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: () {},
              child: Text(
                LangStore.t('special.cta'),
                style: const TextStyle(
                  color: Color(0xFF0E7A5F),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
