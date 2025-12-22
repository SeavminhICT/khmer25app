import 'package:flutter/material.dart';
import 'package:khmer25/l10n/lang_store.dart';
import 'package:khmer25/login/api_service.dart';
import 'package:khmer25/product/model/product_cart.dart';
import 'package:khmer25/product/model/product_model.dart';
import 'package:khmer25/services/analytics_service.dart';

class ProductsSreen extends StatefulWidget {
  final String? initialFilter;
  const ProductsSreen({super.key, this.initialFilter});

  @override
  State<ProductsSreen> createState() => _ProductsSreenState();
}

class _ProductsSreenState extends State<ProductsSreen> {
  late String selectedSub;
  bool _isCartHovered = false;
  final ScrollController _subTabController = ScrollController();
  late Future<List<ProductModel>> _futureProducts;
  Map<String, String> _categoryNames = {};

  @override
  void initState() {
    super.initState();
    selectedSub = widget.initialFilter ?? 'All';
    _futureProducts = ApiService.fetchProducts();
    _loadCategories();
  }

  Widget _buildCartIcon() {
    return MouseRegion(
      onEnter: (_) => setState(() => _isCartHovered = true),
      onExit: (_) => setState(() => _isCartHovered = false),
      child: AnimatedScale(
        scale: _isCartHovered ? 1.15 : 1.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isCartHovered ? Colors.green.withOpacity(0.12) : Colors.transparent,
          ),
          child: const Icon(Icons.shopping_cart),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _subTabController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await ApiService.fetchCategories();
      setState(() {
        _categoryNames = {
          for (final c in cats) c.id.toString(): c.titleEn,
        };
      });
    } catch (_) {
      // keep map empty on failure; products will still show their own names
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: SafeArea(
        child: FutureBuilder<List<ProductModel>>(
          future: _futureProducts,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                AnalyticsService.trackError(
                  screen: 'Products',
                  code: 'fetch_products_failed',
                );
              });
              return Center(child: Text('Failed to load products: ${snapshot.error}'));
            }
            final products = snapshot.data ?? [];
            final categories = _categories(products, selectedSub);
            final lowered = selectedSub.toLowerCase();
            final filtered = selectedSub == 'All'
                ? products
                : products.where((p) {
                    final label = _labelForProduct(p).toLowerCase();
                    return label == lowered;
                  }).toList();
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---------------- SUB CATEGORY BUTTONS ----------------
                  Scrollbar(
                    controller: _subTabController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _subTabController,
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: categories.map((tab) {
                          final isActive = selectedSub == tab;
                          return GestureDetector(
                            onTap: () => setState(() => selectedSub = tab),
                            child: Container(
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                              decoration: BoxDecoration(
                                color: isActive ? Colors.green.shade700 : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.green.shade700,
                                  width: 1.2,
                                ),
                              ),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 160),
                                child: Text(
                                  tab == 'All' ? LangStore.t('sectiontitle.viewall') : tab,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: TextStyle(
                                    color: isActive ? Colors.white : Colors.green.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ---------------- PRODUCT GRID ----------------
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final crossAxisCount = _computeCrossAxisCount(width);
                      const spacing = 16.0;
                      final cardWidth = (width - spacing * (crossAxisCount - 1)) / crossAxisCount;
                      double mainAxisExtent = cardWidth * 1.05 + 90;
                      if (mainAxisExtent < 260) mainAxisExtent = 260;
                      if (mainAxisExtent > 300) mainAxisExtent = 300;
                      double imageHeight = mainAxisExtent * 0.52;
                      if (imageHeight < 130) imageHeight = 130;
                      if (imageHeight > 180) imageHeight = 180;

                      return GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: filtered.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: spacing,
                          crossAxisSpacing: spacing,
                          mainAxisExtent: mainAxisExtent,
                        ),
                        itemBuilder: (_, index) {
                          final p = filtered[index];
                          return ProductCard(product: p, imageHeight: imageHeight);
                        },
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  int _computeCrossAxisCount(double width) {
    if (width >= 1200) return 5; // web/desktop
    if (width >= 900) return 4;  // tablets landscape
    if (width >= 650) return 3;  // tablets portrait
    return 3;                     // phones
  }

  List<String> _categories(List<ProductModel> products, String current) {
    final set = <String>{};
    for (final p in products) {
      final label = _labelForProduct(p);
      if (label.isNotEmpty) set.add(label);
    }
    final list = ['All', ...set.toList()];
    if (current != 'All' && !list.contains(current)) {
      list.add(current);
    }
    if (list.length == 1) return ['All'];
    return list;
  }

  String _labelForProduct(ProductModel p) {
    final first = _labelFromValue(p.displayTag);
    if (first.isNotEmpty) return first;
    final second = _labelFromValue(p.displaySubCategory);
    if (second.isNotEmpty) return second;
    return p.displayTag.isNotEmpty ? p.displayTag : p.displaySubCategory;
  }

  String _labelFromValue(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';
    if (!_isNumeric(trimmed)) return trimmed;
    // numeric: try mapping to category name
    final mapped = _categoryNames[trimmed] ?? '';
    return mapped.isNotEmpty ? mapped : trimmed;
  }

  bool _isNumeric(String s) => RegExp(r'^\d+$').hasMatch(s);
}
