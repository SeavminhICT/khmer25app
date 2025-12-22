class FavoriteModel {
  final String title;
  final String imageUrl;
  final String newPrice;
  final String oldPrice;
  final String unit;
  final String tag;
  final String discount;
  bool isFavorite; // can toggle

  FavoriteModel({
    required this.title,
    required this.imageUrl,
    required this.newPrice,
    required this.oldPrice,
    required this.unit,
    required this.tag,
    required this.discount,
    this.isFavorite = true,
  });
}
