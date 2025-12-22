// ignore_for_file: unused_local_variable
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:khmer25/cart/cart_screen.dart';
import 'package:khmer25/cart/cart_store.dart';
import 'package:khmer25/categories/categories_screen.dart';
import 'package:khmer25/favorite/favorite_screen.dart';
import 'package:khmer25/l10n/lang_store.dart';
import 'package:khmer25/account/account_screen.dart';
import 'package:khmer25/login/api_service.dart';
import 'package:khmer25/models/category_item.dart';
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
    {'icon': Icons.person, 'label': 'drawer.profile', 'index': 5},
    {'icon': Icons.favorite, 'label': 'drawer.favorite', 'index': 4},
    {'icon': Icons.delivery_dining, 'label': 'drawer.delivery', 'index': 3},
    {'icon': Icons.call, 'label': 'drawer.contact', 'index': 0},
    {'icon': Icons.login, 'label': 'drawer.signin', 'index': 5},
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
                _selectedIndex = 5;
                _drawerIndex = 5;
              });
              _trackTab(5);
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

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        child: const Icon(Icons.chat, color: Colors.white),
        onPressed: () {},
      ),

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

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BannerCarousel(height: screenWidth * 0.40),

          SizedBox(height: isTablet ? 24 : 16),
          SectionTitle(title: LangStore.t('sectiontitle.type')),
          CategoryGrid(isTablet: isTablet),

          SizedBox(height: isTablet ? 24 : 16),
          SectionTitle(
            title: LangStore.t('sectiontitle.products'),
            trailing: LangStore.t('sectiontitle.viewall'),
          ),
          ProductHorizontalList(
            section: 'hot',
            itemWidth: isDesktop ? 280 : (isTablet ? 200 : 150),
          ),

          SizedBox(height: isTablet ? 24 : 16),
          SectionTitle(
            title: LangStore.t('sectiontitle.discount'),
            trailing: LangStore.t('sectiontitle.viewall'),
          ),
          ProductHorizontalList(
            section: 'discount',
            itemWidth: isDesktop ? 280 : (isTablet ? 200 : 150),
          ),

          SizedBox(height: isTablet ? 24 : 16),
          SpecialOfferCard(),
          const SizedBox(height: 80),
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
                  borderRadius: BorderRadius.circular(12),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (trailing != null)
            Text(
              trailing!,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
        ],
      ),
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
          padding: EdgeInsets.all(widget.isTablet ? 24 : 16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.85,
            mainAxisSpacing: widget.isTablet ? 16 : 12,
            crossAxisSpacing: widget.isTablet ? 16 : 12,
          ),
          itemCount: hasData ? cats!.length : _fallbackCats.length,
          itemBuilder: (_, i) {
            if (hasData) {
              final cat = cats![i];
              final name = cat.titleEn.isNotEmpty ? cat.titleEn : cat.titleKh;
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _openCategory(context, name),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _categoryImage(cat.resolvedImage),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            } else {
              final cat = _fallbackCats[i];
              final name = cat['label'] ?? '';
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _openCategory(context, name),
                child: Column(
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
                    const SizedBox(height: 4),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
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
        color: Colors.grey.shade200,
        alignment: Alignment.center,
        child: const Icon(Icons.image_not_supported, size: 22, color: Colors.grey),
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
          color: Colors.grey.shade200,
          alignment: Alignment.center,
          child: const Icon(Icons.image_not_supported, size: 22, color: Colors.grey),
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

class ProductHorizontalList extends StatelessWidget {
  final String section;
  final double itemWidth;

  const ProductHorizontalList({
    super.key,
    required this.section,
    this.itemWidth = 150,
  });

  List<Map<String, dynamic>> get _items {
    if (section == 'hot') {
      return [
        {
          'img': 'assets/images/products/honey1.jpg',
          'title': 'ទឹកឃ្មុំក្តៅ 150ml',
          'price': '3.25',
        },
        {
          'img': 'assets/images/products/honey2.jpg',
          'title': 'ទឹកឃ្មុំក្តៅ 500ml',
          'price': '6.5',
        },
        {
          'img': 'assets/images/products/honey3.jpg',
          'title': 'ទឹកឃ្មុំក្តៅ 1000ml',
          'price': '0.88',
        },
        {
          'img': 'assets/images/products/honey2.jpg',
          'title': 'ទឹកឃ្មុំក្តៅ 500ml',
          'price': '6.5',
        },
        {
          'img': 'assets/images/products/honey3.jpg',
          'title': 'ទឹកឃ្មុំក្តៅ 1000ml',
          'price': '0.88',
        },
      ];
    } else {
      return [
        {
          'img': 'assets/images/products/pumpkin.jpg',
          'title': 'ក្រូចថ្លុង',
          'price': '1.90',
          'old': '2.50',
          'discount': '-31%',
        },
        {
          'img': 'assets/images/products/tomato.jpg',
          'title': 'ដំឡូង',
          'price': '2.50',
          'old': '3.00',
          'discount': '-30.6%',
        },
        {
          'img': 'assets/images/products/vegetable.jpg',
          'title': 'បន្លែស្រស់',
          'price': '1.90',
          'old': '2.50',
          'discount': '-24%',
        },
        {
          'img': 'assets/images/products/tomato.jpg',
          'title': 'ដំឡូង',
          'price': '2.50',
          'old': '3.00',
          'discount': '-30.6%',
        },
        {
          'img': 'assets/images/products/vegetable.jpg',
          'title': 'បន្លែស្រស់',
          'price': '1.90',
          'old': '2.50',
          'discount': '-24%',
        },
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return SizedBox(
      height: isTablet ? 280 : 230,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,

        // ⭐ Important — allows scrolling inside SingleChildScrollView
        primary: false,
        physics: const BouncingScrollPhysics(),

        padding: EdgeInsets.symmetric(horizontal: isTablet ? 16 : 12),
        itemCount: _items.length,
        itemBuilder: (_, i) {
          final p = _items[i];

          return Container(
            width: itemWidth,
            margin: EdgeInsets.only(right: isTablet ? 16 : 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
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
                  child: Image.asset(
                    p['img'],
                    height: isTablet ? 140 : 100,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        p['title'],
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 4),

                      // Price + Old Price
                      Row(
                        children: [
                          Text(
                            '\$${p['price']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (p['old'] != null) ...[
                            const SizedBox(width: 4),
                            Text(
                              '\$${p['old']}',
                              style: const TextStyle(
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),

                      // Discount Badge
                      if (p['discount'] != null)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            p['discount'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}



class SpecialOfferCard extends StatelessWidget {
  const SpecialOfferCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 16),
      padding: EdgeInsets.all(isTablet ? 30 : 20),
      decoration: BoxDecoration(
        color: Colors.green.shade700,
        borderRadius: BorderRadius.circular(16),
      ),

      // ⭐ Center the entire content in the middle
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,                 // ⭐ keeps content tight & centered
          crossAxisAlignment: CrossAxisAlignment.center,  // ⭐ horizontal center
          children: [
            Text(LangStore.t('special.title'),
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,               // ⭐ center text
            ),

            const SizedBox(height: 8),

            Text(LangStore.t('special.desc'),
              style: TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,               // ⭐ center text
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
              ),
              onPressed: () {},
              child: Text(
                LangStore.t('special.cta'),
                style: const TextStyle(color: Colors.green),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
