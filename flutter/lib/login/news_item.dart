class NewsItem {
  final int id;
  final String username;
  final String email;
  final String phone;
  final String address;

  NewsItem({
    required this.id,
    required this.username,
    required this.email,
    required this.phone,
    required this.address,
  });

  factory NewsItem.fromJson(Map<String, dynamic> json) {
    return NewsItem(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      phone: json['phone'] ?? "",
      address: json['address'] ?? "",
    );
  }
}
