import 'package:flutter/foundation.dart';

/// Simple in-memory favorites store shared between screens.
class FavoriteStore {
  static final ValueNotifier<List<Map<String, dynamic>>> favoriteGroups =
      ValueNotifier<List<Map<String, dynamic>>>([]);
  static final ValueNotifier<List<Map<String, dynamic>>> favoriteProducts =
      ValueNotifier<List<Map<String, dynamic>>>([]);

  static bool isFavorite(String id) {
    return favoriteGroups.value.any((item) => item['id'] == id);
  }

  static bool isProductFavorite(String id) {
    return favoriteProducts.value.any((item) => item['id'] == id);
  }

  static void toggleFavorite(Map<String, dynamic> group) {
    final updated = List<Map<String, dynamic>>.from(favoriteGroups.value);
    final existingIndex =
        updated.indexWhere((item) => item['id'] == group['id']);

    if (existingIndex >= 0) {
      updated.removeAt(existingIndex);
    } else {
      // store a copy to avoid accidental mutations from callers
      updated.add(Map<String, dynamic>.from(group));
    }

    favoriteGroups.value = updated;
  }

  static void toggleProductFavorite(Map<String, dynamic> product) {
    final updated = List<Map<String, dynamic>>.from(favoriteProducts.value);
    final String id = product['id'] ?? product['title'] ?? '';
    final existingIndex = updated.indexWhere((item) => item['id'] == id);

    if (existingIndex >= 0) {
      updated.removeAt(existingIndex);
    } else {
      final data = Map<String, dynamic>.from(product);
      data['id'] = id;
      updated.add(data);
    }
    favoriteProducts.value = updated;
  }
}
