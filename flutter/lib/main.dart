import 'package:flutter/material.dart';
import 'package:khmer25/account/account_screen.dart';
import 'package:khmer25/cart/cart_screen.dart';
import 'package:khmer25/cart/checkout_screen.dart';
import 'package:khmer25/categories/categories_screen.dart';
import 'package:khmer25/favorite/favorite_screen.dart';
import 'package:khmer25/homePage.dart';
import 'package:khmer25/l10n/lang_store.dart';
import 'package:khmer25/login/auth_store.dart';
import 'package:khmer25/product/model/product_model.dart';
import 'package:khmer25/product/product_detail_screen.dart';
import 'package:khmer25/product/products_sreen.dart';
import 'package:khmer25/promotion/promotion_screen.dart';
import 'package:khmer25/screen/onboarding_screen.dart';
import 'package:khmer25/screen/slashscreen.dart';
import 'package:khmer25/services/analytics_service.dart';
import 'login/login_page.dart';
import 'login/signup_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthStore.init();
  await AnalyticsService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Lang>(
      valueListenable: LangStore.current,
      builder: (_, __, ___) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          initialRoute: '/splash',
          navigatorObservers: [AnalyticsService.routeObserver],

          routes: {
            '/splash': (context) => const SplashScreen(),
            '/home': (context) => const HomePage(),
            '/login': (context) => const LoginPage(),
            '/signup': (context) => const SignUpPage(),
            '/onboarding': (context) => const OnboardingPage(),
          },
          onGenerateRoute: _onGenerateRoute,
          onUnknownRoute: (settings) => _pageRoute(const HomePage(), settings),
        );
      },
    );
  }
}

Route<dynamic> _pageRoute(Widget page, RouteSettings settings) {
  return MaterialPageRoute(builder: (_) => page, settings: settings);
}

Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
  final name = settings.name ?? '';

  switch (name) {
    case '/':
    case '/home':
      return _pageRoute(const HomePage(), settings);
    case '/cart':
      return _pageRoute(const CartScreen(), settings);
    case '/checkout':
      return _pageRoute(const CheckoutScreen(), settings);
    case '/favorite':
      return _pageRoute(const FavoriteScreen(), settings);
    case '/products':
      return _pageRoute(const ProductsSreen(), settings);
    case '/categories':
      return _pageRoute(const CategoriesScreen(), settings);
    case '/promotions':
      return _pageRoute(const PromotionScreen(), settings);
    case '/account':
      return _pageRoute(const AccountScreen(), settings);
  }

  if (name.startsWith('/home/')) {
    final index = int.tryParse(name.split('/').last) ?? 0;
    return _pageRoute(HomePage(initialIndex: index), settings);
  }

  if (name.startsWith('/product/')) {
    final id = name.substring('/product/'.length);
    // When landing directly on a product route (e.g. browser refresh),
    // rebuild the page with a minimal product; the screen will fetch details.
    final product = ProductModel(
      id: id,
      title: '',
      price: '',
      currency: 'USD',
      unit: '',
      tag: '',
      subCategory: '',
      categoryName: '',
      subCategoryName: '',
      imageUrl: '',
    );
    return _pageRoute(ProductDetailScreen(product: product), settings);
  }

  return null;
}
