// ignore_for_file: unused_local_variable
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:khmer25/cart/cart_screen.dart';
import 'package:khmer25/cart/cart_store.dart';
import 'package:khmer25/categories/categories_screen.dart';
import 'package:khmer25/favorite/favorite_screen.dart';
import 'package:khmer25/favorite/favorite_store.dart';
import 'package:khmer25/l10n/lang_store.dart';
import 'package:khmer25/account/account_screen.dart';
import 'package:khmer25/account/order_screen.dart';
import 'package:khmer25/login/api_service.dart';
import 'package:khmer25/models/category_item.dart';
import 'package:khmer25/product/model/product_model.dart';
import 'package:khmer25/product/product_detail_screen.dart';
import 'package:khmer25/product/products_sreen.dart';
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
              width: isTablet ? 42 : 34,
              height: isTablet ? 42 : 34,
            ),
            const SizedBox(width: 8),
            const Text(
              'Khmer25',
              style: TextStyle(
                color: Color(0xFF1F2A24),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
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
          const SizedBox(width: 6),
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

class HomeBody extends StatefulWidget {
  const HomeBody({super.key});

  @override
  State<HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<HomeBody> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isTablet = MediaQuery.of(context).size.width > 600;
    void openCategory(String name) {
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

    return Container(
      color: const Color(0xFFF7F8FA),
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 90),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _SearchBar(
                controller: _searchController,
                isTablet: isTablet,
                onChanged: (value) => setState(() => _query = value),
                onClear: () {
                  _searchController.clear();
                  setState(() => _query = '');
                },
              ),
            ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: HeroBanner(
                    height: isTablet ? 200 : 170,
                  ),
                ),
                if (_query.trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: _SectionHeader(title: 'Search Results'),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _SearchResultsGrid(query: _query),
                  ),
                  const SizedBox(height: 24),
                ] else ...[
                  const SizedBox(height: 16),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: _SectionHeader(title: 'Categories'),
                  ),
                  const SizedBox(height: 10),
                  CategoryRail(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    onCategoryTap: openCategory,
                  ),
                  const SizedBox(height: 18),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: _SectionHeader(
                      title: '🔥 Hot Products',
                      action: 'View All',
                    ),
                  ),
                  const SizedBox(height: 10),
                  _HotProductsRow(query: _query),
                  const SizedBox(height: 18),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: _SectionHeader(
                      title: '💸 Discount Deals',
                      action: 'View All',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _DiscountGrid(query: _query),
                  ),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
          const _CartActionBar(),
        ],
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

class HeroBanner extends StatelessWidget {
  final double height;
  const HeroBanner({super.key, this.height = 180});

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
            viewportFraction: MediaQuery.of(context).size.width > 600 ? 0.86 : 0.96,
          ),
          items: paths
              .map(
                (path) => ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _bannerImage(path),
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xAA0E7A5F),
                              Color(0x000E7A5F),
                            ],
                            begin: Alignment.bottomLeft,
                            end: Alignment.topRight,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: const [
                            Text(
                              'Flash Sale',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Save up to 50% today',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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

class _SearchBar extends StatelessWidget {
  final bool isTablet;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.isTablet,
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: isTablet ? 48 : 44,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F4),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E6E3)),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Search products...',
          hintStyle: const TextStyle(color: Color(0xFF9AA7A0), fontSize: 14),
          prefixIcon:
              const Icon(Icons.search, color: Color(0xFF9AA7A0), size: 20),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onClear,
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

class _HeroPromoCard extends StatelessWidget {
  const _HeroPromoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF5B62F0), Color(0xFFE24A96)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: 10,
            child: Icon(
              Icons.shopping_bag_rounded,
              size: 96,
              color: Colors.white.withOpacity(0.18),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Flash Sale',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Up to 70% off on electronics',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF5B62F0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {},
                  child: const Text('Shop Now'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? action;

  const _SectionHeader({required this.title, this.action});

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
        if (action != null)
          Text(
            action!,
            style: const TextStyle(
              color: Color(0xFF5B62F0),
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

class _HotProductsRow extends StatefulWidget {
  final String query;

  const _HotProductsRow({required this.query});

  @override
  State<_HotProductsRow> createState() => _HotProductsRowState();
}

class _HotProductsRowState extends State<_HotProductsRow> {
  late Future<List<ProductModel>> _futureProducts;

  @override
  void initState() {
    super.initState();
    _futureProducts = ApiService.fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 270,
      child: FutureBuilder<List<ProductModel>>(
        future: _futureProducts,
        builder: (context, snapshot) {
          final products = _filterBySearch(
            _filterByTag(snapshot.data ?? [], 'hot'),
            widget.query,
          );
          if (products.isEmpty) {
            return const SizedBox.shrink();
          }
          final count = products.length > 10 ? 10 : products.length;
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            primary: false,
            physics: const BouncingScrollPhysics(),
            itemCount: count,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _ProductCard(product: products[i]),
          );
        },
      ),
    );
  }
}

class _DiscountGrid extends StatefulWidget {
  final String query;

  const _DiscountGrid({required this.query});

  @override
  State<_DiscountGrid> createState() => _DiscountGridState();
}

class _DiscountGridState extends State<_DiscountGrid> {
  late Future<List<ProductModel>> _futureProducts;

  @override
  void initState() {
    super.initState();
    _futureProducts = ApiService.fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ProductModel>>(
      future: _futureProducts,
      builder: (context, snapshot) {
        final products = _filterBySearch(
          _filterByTag(snapshot.data ?? [], 'discount'),
          widget.query,
        );
        if (products.isEmpty) {
          return const SizedBox.shrink();
        }
        final count = products.length > 6 ? 6 : products.length;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.64,
          ),
          itemCount: count,
          itemBuilder: (_, i) => _DiscountCard(product: products[i]),
        );
      },
    );
  }
}

class _SearchResultsGrid extends StatefulWidget {
  final String query;

  const _SearchResultsGrid({required this.query});

  @override
  State<_SearchResultsGrid> createState() => _SearchResultsGridState();
}

class _SearchResultsGridState extends State<_SearchResultsGrid> {
  late Future<List<ProductModel>> _futureProducts;

  @override
  void initState() {
    super.initState();
    _futureProducts = ApiService.fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ProductModel>>(
      future: _futureProducts,
      builder: (context, snapshot) {
        final products = _filterBySearch(snapshot.data ?? [], widget.query);
        if (products.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No products found.',
              style: TextStyle(color: Color(0xFF7A8680)),
            ),
          );
        }
        final count = products.length > 10 ? 10 : products.length;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.64,
          ),
          itemCount: count,
          itemBuilder: (_, i) => _DiscountCard(product: products[i]),
        );
      },
    );
  }
}

class _CartActionBar extends StatelessWidget {
  const _CartActionBar();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: CartStore.items,
      builder: (context, items, _) {
        final count = items.length;
        final show = count > 0;
        final total = CartStore.subtotal();
        final currency = items.isNotEmpty ? items.first.currency : 'USD';

        return AnimatedPositioned(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          left: 16,
          right: 16,
          bottom: show ? 16 : -100,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: show ? 1 : 0,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CartScreen(),
                    settings: const RouteSettings(name: '/cart'),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shopping_cart, color: Color(0xFFF5B301)),
                    const SizedBox(width: 10),
                    Text(
                      'View Cart ($count item${count == 1 ? '' : 's'})',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2A24),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatCurrency(currency, total),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2A24),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.chevron_right, color: Color(0xFF9AA7A0)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final rating = _ratingFor(product.id);
    return InkWell(
      borderRadius: BorderRadius.circular(18),
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
        width: 170,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: Stack(
                children: [
                  _productImage(product.imageUrl, 130),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: ValueListenableBuilder<List<Map<String, dynamic>>>(
                      valueListenable: FavoriteStore.favoriteProducts,
                      builder: (context, favorites, _) {
                        final isFavorite =
                            FavoriteStore.isProductFavorite(product.id);
                        return IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            size: 16,
                            color: isFavorite
                                ? const Color(0xFFE0566D)
                                : const Color(0xFF5B62F0),
                          ),
                          onPressed: () {
                            FavoriteStore.toggleProductFavorite(
                              _favoriteMap(product),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _RatingRow(rating: rating),
                  const SizedBox(height: 6),
                Text(
                  product.displayPrice,
                  style: const TextStyle(
                    color: Color(0xFF5B62F0),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 34,
                        child: OutlinedButton(
                          onPressed: () {
                            CartStore.addItem(product.toCartMap());
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF5B62F0),
                            side: const BorderSide(color: Color(0xFF5B62F0)),
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Add to Cart',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 34,
                        child: ElevatedButton(
                          onPressed: () {
                            CartStore.addItem(product.toCartMap());
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CartScreen(),
                                settings: const RouteSettings(name: '/cart'),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5B62F0),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Buy Now',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ),
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

class _DiscountCard extends StatelessWidget {
  final ProductModel product;

  const _DiscountCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final rating = _ratingFor(product.id);
    final original = _originalPrice(product.displayPrice);
    return InkWell(
      borderRadius: BorderRadius.circular(18),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: Stack(
                children: [
                  _productImage(product.imageUrl, 120),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBE8E8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '-30%',
                      style: TextStyle(
                        color: Color(0xFFD64B4B),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: ValueListenableBuilder<List<Map<String, dynamic>>>(
                      valueListenable: FavoriteStore.favoriteProducts,
                      builder: (context, favorites, _) {
                        final isFavorite =
                            FavoriteStore.isProductFavorite(product.id);
                        return IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            size: 16,
                            color: isFavorite
                                ? const Color(0xFFE0566D)
                                : const Color(0xFF5B62F0),
                          ),
                          onPressed: () {
                            FavoriteStore.toggleProductFavorite(
                              _favoriteMap(product),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Text(
                  product.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  original,
                  style: const TextStyle(
                    color: Color(0xFF9AA7A0),
                    fontSize: 12,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  product.displayPrice,
                  style: const TextStyle(
                    color: Color(0xFF5B62F0),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                _RatingRow(rating: rating),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 32,
                        child: OutlinedButton(
                          onPressed: () {
                            CartStore.addItem(product.toCartMap());
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF5B62F0),
                            side: const BorderSide(color: Color(0xFF5B62F0)),
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Add to Cart',
                              style: TextStyle(fontSize: 11),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 32,
                        child: ElevatedButton(
                          onPressed: () {
                            CartStore.addItem(product.toCartMap());
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CartScreen(),
                                settings: const RouteSettings(name: '/cart'),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5B62F0),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Buy Now',
                              style: TextStyle(fontSize: 11),
                            ),
                          ),
                        ),
                      ),
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

class _RatingRow extends StatelessWidget {
  final double rating;

  const _RatingRow({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Row(
          children: List.generate(
            5,
            (index) => Icon(
              index < rating.floor() ? Icons.star : Icons.star_border,
              size: 14,
              color: const Color(0xFFF5B301),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '(${rating.toStringAsFixed(1)})',
          style: const TextStyle(fontSize: 11, color: Color(0xFF7A8680)),
        ),
      ],
    );
  }
}

double _ratingFor(String seed) {
  final code = seed.codeUnits.fold<int>(0, (sum, unit) => sum + unit);
  final value = 3.8 + (code % 12) / 10;
  return value.clamp(3.8, 4.9);
}

List<ProductModel> _filterByTag(List<ProductModel> products, String target) {
  final key = target.trim().toLowerCase();
  if (key.isEmpty) return products;
  final List<ProductModel> filtered = [];
  for (final product in products) {
    final tag = product.tag.trim().toLowerCase();
    final displayTag = product.displayTag.trim().toLowerCase();
    final category = product.categoryName.trim().toLowerCase();
    final subCategory = product.subCategoryName.trim().toLowerCase();
    if (_matchesTag(tag, key) ||
        _matchesTag(displayTag, key) ||
        _matchesTag(category, key) ||
        _matchesTag(subCategory, key)) {
      filtered.add(product);
    }
  }
  return filtered;
}

List<ProductModel> _filterBySearch(List<ProductModel> products, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return products;
  return products.where((p) {
    final title = p.title.toLowerCase();
    final category = p.displayTag.toLowerCase();
    final subCategory = p.displaySubCategory.toLowerCase();
    return title.contains(q) ||
        category.contains(q) ||
        subCategory.contains(q);
  }).toList();
}

bool _matchesTag(String value, String key) {
  if (value.isEmpty) return false;
  if (value == key) return true;
  if (key == 'discount' && (value == 'disscount' || value == 'sale')) {
    return true;
  }
  if (key == 'hot' && (value == 'trending' || value == 'popular')) {
    return true;
  }
  return false;
}

String _originalPrice(String priceText) {
  final match = RegExp(r'([^\d]*)([0-9]+(?:\.[0-9]+)?)').firstMatch(priceText);
  if (match == null) return priceText;
  final symbol = (match.group(1) ?? '').trim();
  final value = double.tryParse(match.group(2) ?? '') ?? 0;
  final original = (value * 1.3);
  return '$symbol${original.toStringAsFixed(2)}';
}

Map<String, dynamic> _favoriteMap(ProductModel product) => {
      'id': product.id,
      'title': product.title,
      'img': product.imageUrl,
      'price': product.displayPrice,
      'currency': product.currency,
      'unit': product.unit,
      'tag': product.tag,
      'subCategory': product.subCategory,
      'categoryName': product.categoryName,
      'subCategoryName': product.subCategoryName,
    };

String _formatCurrency(String currency, double value) {
  final symbol = currency.toUpperCase() == 'KHR' ? '៛' : '\$';
  return '$symbol${value.toStringAsFixed(2)}';
}

Widget _productImage(String url, double height) {
  final normalized = _normalizeHomeImageUrl(url);
  if (normalized == null) {
    return _imagePlaceholder(height);
  }
  if (normalized.startsWith('assets/')) {
    return Image.asset(
      normalized,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _imagePlaceholder(height),
    );
  }
  return Image.network(
    normalized,
    height: height,
    width: double.infinity,
    fit: BoxFit.cover,
    errorBuilder: (_, __, ___) => _imagePlaceholder(height),
  );
}

Widget _imagePlaceholder(double height) {
  return Container(
    height: height,
    width: double.infinity,
    color: const Color(0xFFF0F2F4),
    alignment: Alignment.center,
    child: const Icon(Icons.image_not_supported, size: 28, color: Colors.grey),
  );
}

String? _normalizeHomeImageUrl(String url) {
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

class CategoryRail extends StatefulWidget {
  final EdgeInsetsGeometry padding;
  final ValueChanged<String> onCategoryTap;

  const CategoryRail({
    super.key,
    required this.padding,
    required this.onCategoryTap,
  });

  @override
  State<CategoryRail> createState() => _CategoryRailState();
}

class _CategoryRailState extends State<CategoryRail> {
  late Future<List<CategoryItem>> _futureCategories;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _futureCategories = ApiService.fetchCategories();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CategoryItem>>(
      future: _futureCategories,
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const SizedBox.shrink();
        }
        return SizedBox(
          height: 108,
          child: ListView.separated(
            padding: widget.padding,
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final cat = items[index];
              final name = cat.titleEn.isNotEmpty ? cat.titleEn : cat.titleKh;
              final isActive = index == _selectedIndex;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedIndex = index);
                  widget.onCategoryTap(name);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 90,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFFE8F6F0)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isActive
                          ? const Color(0xFF2C9E6C)
                          : const Color(0xFFE5EAE6),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _categoryImage(cat.resolvedImage),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isActive
                              ? const Color(0xFF1F2A24)
                              : const Color(0xFF6D7A72),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _categoryImage(String path) {
    if (path.isEmpty) {
      return Container(
        width: 44,
        height: 44,
        color: const Color(0xFFEFF3F1),
        alignment: Alignment.center,
        child: const Icon(Icons.image_not_supported, size: 18, color: Colors.grey),
      );
    }
    if (path.startsWith('http')) {
      return Image.network(
        path,
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 44,
          height: 44,
          color: const Color(0xFFEFF3F1),
          alignment: Alignment.center,
          child:
              const Icon(Icons.image_not_supported, size: 18, color: Colors.grey),
        ),
      );
    }
    return Image.asset(
      path,
      width: 44,
      height: 44,
      fit: BoxFit.cover,
    );
  }
}

class ProductHorizontalList extends StatefulWidget {
  final String section;
  final double itemWidth;
  final bool showFavorite;
  final bool showDiscount;

  const ProductHorizontalList({
    super.key,
    required this.section,
    this.itemWidth = 150,
    this.showFavorite = false,
    this.showDiscount = false,
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE8ECE9)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
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
                  child: Stack(
                    children: [
                      _productImage(
                        p.imageUrl,
                        isTablet ? 140 : 100,
                      ),
                      if (widget.showDiscount)
                        Positioned(
                          left: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFBE8E8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              '-20%',
                              style: TextStyle(
                                color: Color(0xFFD64B4B),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      if (widget.showFavorite)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.95),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.favorite_border,
                              size: 16,
                              color: Color(0xFF8A9690),
                            ),
                          ),
                        ),
                    ],
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
                      if (widget.showDiscount)
                        _DiscountPrice(priceText: priceText)
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F4F2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            priceText,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2F3A34),
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

class _DiscountPrice extends StatelessWidget {
  final String priceText;

  const _DiscountPrice({required this.priceText});

  @override
  Widget build(BuildContext context) {
    final parsed = _parsePrice(priceText);
    if (parsed == null) {
      return Text(
        priceText,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF0E7A5F),
        ),
      );
    }
    final original = (parsed.value * 1.2);
    final formattedOriginal = original.toStringAsFixed(2);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${parsed.symbol}$formattedOriginal',
          style: const TextStyle(
            color: Color(0xFF9AA7A0),
            fontSize: 12,
            decoration: TextDecoration.lineThrough,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F4F2),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            priceText,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF2F3A34),
            ),
          ),
        ),
      ],
    );
  }

  _ParsedPrice? _parsePrice(String text) {
    final match = RegExp(r'([^\d]*)([0-9]+(?:\.[0-9]+)?)').firstMatch(text);
    if (match == null) return null;
    final symbol = (match.group(1) ?? '').trim();
    final value = double.tryParse(match.group(2) ?? '');
    if (value == null) return null;
    return _ParsedPrice(symbol: symbol, value: value);
  }
}

class _ParsedPrice {
  final String symbol;
  final double value;

  _ParsedPrice({required this.symbol, required this.value});
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
