class ProductModel {
  final String id;
  final String title;
  final String price;
  final String currency;
  final String unit;
  final String tag; // may be id or name
  final String subCategory; // may be id or name
  final String categoryName; // human-friendly name if provided
  final String subCategoryName; // human-friendly name if provided
  final String imageUrl;
  final String paywayLink;

  ProductModel({
    required this.id,
    required this.title,
    required this.price,
    required this.currency,
    required this.unit,
    required this.tag,
    required this.subCategory,
    required this.categoryName,
    required this.subCategoryName,
    required this.imageUrl,
    this.paywayLink = '',
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final rawPrice = json['price'];
    final rawCurrency = (json['currency'] ?? '').toString().toUpperCase();
    String displayPrice;
    if (rawPrice == null) {
      displayPrice = '';
    } else if (rawPrice is num) {
      displayPrice = rawPrice.toString();
    } else {
      displayPrice = rawPrice.toString();
    }
    final inferredCurrency = rawCurrency.isNotEmpty
        ? rawCurrency
        : (displayPrice.contains('៛') ? 'KHR' : 'USD');
    displayPrice = displayPrice.replaceAll(RegExp(r'[^0-9.]'), '');

    return ProductModel(
      id: (json['id'] ?? json['pk'] ?? '').toString(),
      title: (json['name'] ?? json['title'] ?? '').toString(),
      price: displayPrice,
      currency: inferredCurrency,
      unit: (json['unit'] ?? json['quantity']?.toString() ?? '').toString(),
      tag: (json['tag'] ?? json['category'] ?? '').toString(),
      subCategory: (json['subCategory'] ?? json['subcategory'] ?? '').toString(),
      categoryName: (json['category_name'] ?? json['categoryName'] ?? '').toString(),
      subCategoryName: (json['subcategory_name'] ?? json['subCategoryName'] ?? '').toString(),
      imageUrl: (json['image'] ?? json['image_url'] ?? '').toString(),
      paywayLink: (json['payway_link'] ?? '').toString(),
    );
  }

  String get displayPrice =>
      price.isEmpty ? '' : '${_currencySymbol(currency)}$price';
  String get displayTag => categoryName.isNotEmpty ? categoryName : tag;
  String get displaySubCategory =>
      subCategoryName.isNotEmpty ? subCategoryName : subCategory;

  static String _currencySymbol(String currencyCode) {
    return currencyCode.toUpperCase() == 'KHR' ? '៛' : '\$';
  }

  Map<String, dynamic> toCartMap() => {
        'id': id,
        'title': title,
        'img': imageUrl,
        'price': displayPrice,
        'currency': currency,
        'unit': unit,
        'tag': tag,
        'subCategory': subCategory,
        'payway_link': paywayLink,
      };
}
