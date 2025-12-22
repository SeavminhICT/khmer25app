class Productmodel {
  final String title;
  final String imageUrl;
  bool isSelected;

  Productmodel({
    required this.title,
    required this.imageUrl,
    this.isSelected = false,
  });
}
