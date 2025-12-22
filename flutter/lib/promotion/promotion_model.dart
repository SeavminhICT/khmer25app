class ProductModel {
  final String title;
  final String imageUrl;
  final String newPrice;
  final String oldPrice;
  final String unit;
  final String category;
  final String discount;
  bool isSelected;

  ProductModel({
    required this.title,
    required this.imageUrl,
    required this.newPrice,
    required this.oldPrice,
    required this.unit,
    required this.category,
    required this.discount,
    this.isSelected = false,
  });
}
