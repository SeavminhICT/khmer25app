import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AnalyticsService {
  AnalyticsService._();

  static FirebaseAnalytics? _analytics;
  static PackageInfo? _packageInfo;
  static String? _lastScreen;

  static final RouteObserver<PageRoute<dynamic>> routeObserver =
      _AnalyticsRouteObserver();

  static bool get enabled => _analytics != null;

  static Future<void> init() async {
    try {
      await Firebase.initializeApp();
      _analytics = FirebaseAnalytics.instance;
      _packageInfo = await PackageInfo.fromPlatform();
      await _analytics?.logAppOpen();
      await _setStaticTraits();
    } catch (e, st) {
      debugPrint('⚠️ Analytics disabled: $e');
      debugPrint('$st');
      _analytics = null;
    }
  }

  static Future<void> _setStaticTraits() async {
    final info = _packageInfo;
    if (info == null) return;
    await _analytics?.setUserProperty(name: 'app_version', value: info.version);
    await _analytics?.setUserProperty(
      name: 'platform',
      value: Platform.operatingSystem,
    );
  }

  static Future<void> identifyUser({
    required String userId,
    String? email,
    String? locale,
  }) async {
    final analytics = _analytics;
    if (analytics == null) return;

    await analytics.setUserId(id: userId);
    if (locale != null && locale.isNotEmpty) {
      await analytics.setUserProperty(name: 'locale', value: locale);
    }
    final hashedEmail = _hashEmail(email);
    if (hashedEmail != null) {
      await analytics.setUserProperty(name: 'email_hash', value: hashedEmail);
    }
  }

  static Future<void> clearUser() async {
    final analytics = _analytics;
    if (analytics == null) return;
    await analytics.setUserId(id: null);
  }

  static Future<void> trackScreen(String name) async {
    final analytics = _analytics;
    if (analytics == null) return;
    if (name == _lastScreen) return;
    _lastScreen = name;
    await analytics.logScreenView(screenName: name);
  }

  static Future<void> trackCategoryViewed({
    required String id,
    required String name,
  }) async {
    await _analytics?.logEvent(
      name: 'category_viewed',
      parameters: {
        'id': id,
        'name': name,
      },
    );
  }

  static Future<void> trackProductViewed({
    required String id,
    required String name,
    double? price,
  }) async {
    await _analytics?.logEvent(
      name: 'product_viewed',
      parameters: {
        'id': id,
        'name': name,
        if (price != null) 'price': price,
      },
    );
  }

  static Future<void> trackAddToCart({
    required String id,
    required double price,
    required int qty,
    String? name,
  }) async {
    await _analytics?.logEvent(
      name: 'add_to_cart',
      parameters: {
        'id': id,
        'price': price,
        'qty': qty,
        if (name != null && name.isNotEmpty) 'name': name,
      },
    );
  }

  static Future<void> trackCartViewed({
    required int itemCount,
    double? total,
  }) async {
    await _analytics?.logEvent(
      name: 'cart_viewed',
      parameters: {
        'items': itemCount,
        if (total != null) 'total': total,
      },
    );
  }

  static Future<void> trackCheckoutStarted({
    required double total,
    required int itemCount,
  }) async {
    await _analytics?.logEvent(
      name: 'checkout_started',
      parameters: {
        'total': total,
        'items': itemCount,
      },
    );
  }

  static Future<void> trackOrderSubmitted({
    required String orderCode,
    required double total,
    required int itemCount,
  }) async {
    await _analytics?.logEvent(
      name: 'order_submitted',
      parameters: {
        'order_code': orderCode,
        'total': total,
        'items': itemCount,
      },
    );
  }

  static Future<void> trackSearchUsed(int queryLength) async {
    await _analytics?.logEvent(
      name: 'search_used',
      parameters: {'query_length': queryLength},
    );
  }

  static Future<void> trackError({
    required String screen,
    required String code,
  }) async {
    await _analytics?.logEvent(
      name: 'error_shown',
      parameters: {
        'screen': screen,
        'code': code,
      },
    );
  }

  static Future<void> trackPaymentSelected(String method) async {
    await _analytics?.logEvent(
      name: 'payment_selected',
      parameters: {'method': method},
    );
  }

  static String? _hashEmail(String? email) {
    if (email == null || email.trim().isEmpty) return null;
    final hash = sha256.convert(utf8.encode(email.trim().toLowerCase())).toString();
    return hash.substring(0, 32); // GA4 user property value limit safety
  }
}

class _AnalyticsRouteObserver extends RouteObserver<PageRoute<dynamic>> {
  void _send(Route<dynamic>? route) {
    if (route is PageRoute) {
      final name = route.settings.name ?? route.runtimeType.toString();
      AnalyticsService.trackScreen(name);
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _send(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _send(newRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _send(previousRoute);
  }
}
