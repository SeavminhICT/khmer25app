import 'package:flutter/foundation.dart';
import 'package:khmer25/services/analytics_service.dart';

class CartItem {
  final String id;
  final String title;
  final String img;
  final String unit;
  final double price;
  final String currency;
  final int quantity;
  final String paywayLink;

  const CartItem({
    required this.id,
    required this.title,
    required this.img,
    required this.unit,
    required this.price,
    required this.currency,
    required this.quantity,
    this.paywayLink = "",
  });

  CartItem copyWith({int? quantity}) {
    return CartItem(
      id: id,
      title: title,
      img: img,
      unit: unit,
      price: price,
      currency: currency,
      quantity: quantity ?? this.quantity,
      paywayLink: paywayLink,
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "title": title,
        "img": img,
        "unit": unit,
        "price": price,
        "currency": currency,
        "qty": quantity,
        if (paywayLink.isNotEmpty) "payway_link": paywayLink,
      };
}

class CartStore {
  static final ValueNotifier<List<CartItem>> items =
      ValueNotifier<List<CartItem>>([]);

  static void addItem(Map<String, dynamic> product, {int qty = 1}) {
    if (qty <= 0) return;

    final updated = List<CartItem>.from(items.value);
    final id = (product['id'] ?? product['title'] ?? '').toString();

    final price = _toPrice(product['price']);
    final title = (product['title'] ?? '').toString();
    final img = (product['img'] ?? '').toString();
    final unit = (product['unit'] ?? '').toString();
    final currency = _toCurrency(product['currency'], product['price']);
    final paywayLink = (product['payway_link'] ?? '').toString();

    final idx = updated.indexWhere((x) => x.id == id);

    if (idx >= 0) {
      final current = updated[idx];
      updated[idx] = current.copyWith(quantity: current.quantity + qty);
    } else {
      updated.add(
        CartItem(
          id: id,
          title: title,
          img: img,
          unit: unit,
          price: price,
          currency: currency,
          quantity: qty,
          paywayLink: paywayLink,
        ),
      );
    }

    items.value = updated;
    AnalyticsService.trackAddToCart(
      id: id,
      price: price,
      qty: qty,
      name: title,
    );
  }

  static void updateQuantity(String id, int quantity) {
    final updated = List<CartItem>.from(items.value);
    final idx = updated.indexWhere((x) => x.id == id);
    if (idx == -1) return;

    if (quantity <= 0) {
      updated.removeAt(idx);
    } else {
      updated[idx] = updated[idx].copyWith(quantity: quantity);
    }

    items.value = updated;
  }

  static void remove(String id) {
    items.value = List<CartItem>.from(items.value)
      ..removeWhere((x) => x.id == id);
  }

  static void clear() {
    items.value = [];
  }

  static double subtotal() {
    return items.value.fold(0, (t, x) => t + (x.price * x.quantity));
  }

  static List<Map<String, dynamic>> toPayloadItems() {
    return items.value.map((e) => e.toJson()).toList();
  }

  static double _toPrice(dynamic price) {
    if (price is num) return price.toDouble();
    final s = (price ?? '').toString();
    final cleaned = s.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleaned) ?? 0;
  }

  static String _toCurrency(dynamic currency, dynamic price) {
    final c = (currency ?? '').toString().toUpperCase();
    if (c == 'KHR' || c == 'USD') return c;
    final s = (price ?? '').toString();
    return s.contains('៛') ? 'KHR' : 'USD';
  }
}
