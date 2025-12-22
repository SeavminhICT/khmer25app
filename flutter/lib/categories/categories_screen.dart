import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:khmer25/cart/cart_screen.dart';
import 'package:khmer25/cart/cart_store.dart';
import 'package:khmer25/data/category_data.dart';
import 'package:khmer25/favorite/favorite_screen.dart';
import 'package:khmer25/favorite/favorite_store.dart';
import 'package:khmer25/models/category_item.dart';
import 'package:khmer25/login/api_service.dart';
import 'package:khmer25/product/products_sreen.dart';
import 'package:khmer25/services/analytics_service.dart';
import 'widgets/grid_category_card.dart';
import 'widgets/list_category_tile.dart';
import 'widgets/view_toggle_button.dart';
// import 'khmer_rice_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  bool _isGrid = true;
  String _searchText = '';
  bool _isLoading = false;
  String? _errorMessage;
  List<CategoryItem> _categories = const [];
  int _lastSearchLength = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsService.trackScreen('Categories');
    });
    _fetchCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _buildBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchCategories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await ApiService.fetchCategories();
      setState(() {
        _categories = items.isNotEmpty ? items : kCategories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _categories = kCategories;
        _isLoading = false;
      });
      AnalyticsService.trackError(
        screen: 'Categories',
        code: 'fetch_categories_failed',
      );
    }
  }

  List<CategoryItem> _filteredCategories() {
    if (_searchText.isEmpty) return _categories;
    final query = _searchText.toLowerCase();
    return _categories.where((item) {
      return item.titleEn.toLowerCase().contains(query) ||
          item.titleKh.toLowerCase().contains(query);
    }).toList();
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filtered = _filteredCategories();

    if (filtered.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchCategories,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 80),
            const Icon(Icons.search_off, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Center(child: Text('No categories found')),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: _fetchCategories,
                  child: const Text('Retry'),
                ),
              ),
            ],
          ],
        ),
      );
    }

    final content = _isGrid ? _buildGrid(filtered) : _buildList(filtered);

    return Column(
      children: [
        if (_errorMessage != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.info, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.orange),
                  ),
                ),
                TextButton(
                  onPressed: _fetchCategories,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchCategories,
            child: content,
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFDF7F7),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              children: [
                ViewToggleButton(
                  icon: Icons.grid_view_rounded,
                  isActive: _isGrid,
                  onTap: () => setState(() => _isGrid = true),
                ),
                const SizedBox(width: 8),
                ViewToggleButton(
                  icon: Icons.view_list,
                  isActive: !_isGrid,
                  onTap: () => setState(() => _isGrid = false),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Search categories...",
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) {
                      setState(() => _searchText = val);
                      final len = val.length;
                      if (len != _lastSearchLength && len > 0) {
                        _lastSearchLength = len;
                        AnalyticsService.trackSearchUsed(len);
                      } else if (len == 0) {
                        _lastSearchLength = 0;
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${_categories.length} categories available",
                  style: TextStyle(color: Colors.green.shade600),
                ),
                Row(
                  children: [
                    _ActionIconBadge(
                      icon: Icons.favorite,
                      color: Colors.red,
                      listenable: FavoriteStore.favoriteGroups,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FavoriteScreen(),
                          settings: const RouteSettings(name: '/favorite'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _ActionIconBadge(
                      icon: Icons.shopping_cart_outlined,
                      color: Colors.green,
                      listenable: CartStore.items,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CartScreen(),
                          settings: const RouteSettings(name: '/cart'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.payment, color: Colors.green),
                label: const Text(
                  "Go to checkout",
                  style: TextStyle(color: Colors.green),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.green.shade200),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CartScreen(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(List<CategoryItem> items) {
    return GridView.builder(
      itemCount: items.length,
      physics: const AlwaysScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.78,
      ),
      itemBuilder: (_, i) {
        final category = items[i];
        final isFavorite =
            FavoriteStore.isFavorite(category.id.toString());
        return GridCategoryCard(
          category: category,
          isFavorite: isFavorite,
          onFavoriteTap: () {
            setState(() {
              FavoriteStore.toggleFavorite({
                'id': category.id.toString(),
                'title': category.titleEn,
                'image': category.resolvedImage,
              });
            });
          },
          onAddToCart: () => _addCategoryToCart(category),
          onTap: () => _openCategory(category),
        );
      },
    );
  }

  Widget _buildList(List<CategoryItem> items) {
    return ListView.separated(
      itemCount: items.length,
      physics: const AlwaysScrollableScrollPhysics(),
      separatorBuilder: (_, __) => const SizedBox(height: 13),
      itemBuilder: (_, i) {
        final category = items[i];
        final isFavorite =
            FavoriteStore.isFavorite(category.id.toString());
        return ListCategoryTile(
          category: category,
          isFavorite: isFavorite,
          onFavoriteTap: () {
            setState(() {
              FavoriteStore.toggleFavorite({
                'id': category.id.toString(),
                'title': category.titleEn,
                'image': category.resolvedImage,
              });
            });
          },
          onAddToCart: () => _addCategoryToCart(category),
          onTap: () => _openCategory(category),
        );
      },
    );
  }

  void _addCategoryToCart(CategoryItem category) {
    CartStore.addItem({
      'id': 'cat-${category.id}',
      'title': category.titleEn,
      'img': category.resolvedImage,
      'unit': 'category',
      'price': 0,
    });
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${category.titleEn} added to cart'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openCategory(CategoryItem category) {
    final filterName = category.titleEn.isNotEmpty ? category.titleEn : category.titleKh;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductsSreen(initialFilter: filterName),
        settings: const RouteSettings(name: '/products'),
      ),
    );
    AnalyticsService.trackCategoryViewed(
      id: category.id.toString(),
      name: filterName,
    );
  }

}

class _ActionIconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final ValueListenable<List<dynamic>> listenable;
  final VoidCallback onTap;

  const _ActionIconBadge({
    required this.icon,
    required this.color,
    required this.listenable,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<dynamic>>(
      valueListenable: listenable,
      builder: (_, list, __) {
        final count = list.length;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(icon, color: color),
              onPressed: onTap,
            ),
            if (count > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
