class CategoryItem {
  final int id;
  final String titleEn;
  final String titleKh;
  final String image;
  final int subCount;

  const CategoryItem({
    required this.id,
    required this.titleEn,
    required this.titleKh,
    required this.image,
    this.subCount = 0,
  });

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    return CategoryItem(
      id: _parseInt(json['id']),
      titleEn: json['title_en']?.toString() ?? '',
      titleKh: json['title_kh']?.toString() ?? '',
      image: _extractImage(json),
      subCount: _parseInt(json['sub_count']),
    );
  }

  /// Provides a usable image path for asset or network sources.
  String get resolvedImage {
    String path = image.trim();
    if (path.isEmpty) return path;

    // Decode already-encoded URLs (e.g., https%3A%2F%2Fexample.com%2Fimg.jpg).
    try {
      final decoded = Uri.decodeComponent(path);
      if (decoded.startsWith('http')) return decoded;
      path = decoded;
    } catch (_) {
      // ignore decode errors and keep original
    }

    // Network and asset short-circuits.
    if (path.startsWith('http')) return path;
    if (path.contains('://')) return path;
    if (path.startsWith('assets/')) return path;

    // Prefix host for backend-served media paths.
    const host = 'http://127.0.0.1:8000';
    if (path.startsWith('/')) return '$host$path';
    return '$host/$path';
  }

  bool get isNetworkImage => resolvedImage.startsWith('http');

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  /// Tries multiple API fields to find an image value.
  static String _extractImage(Map<String, dynamic> json) {
    final candidates = [
      json['image'],
      json['img'],
      json['images'],
    ];

    for (final candidate in candidates) {
      if (candidate == null) continue;
      if (candidate is List && candidate.isNotEmpty) {
        final first = candidate.first;
        if (first != null && first.toString().trim().isNotEmpty) {
          return first.toString();
        }
      } else if (candidate is Map && candidate['url'] != null) {
        final url = candidate['url'].toString();
        if (url.trim().isNotEmpty) return url;
      } else {
        final value = candidate.toString();
        if (value.trim().isNotEmpty) return value;
      }
    }
    return '';
  }
}
