import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;
import 'package:khmer25/models/category_item.dart';
import 'package:khmer25/login/news_item.dart';
import 'package:khmer25/product/model/product_model.dart';

class ApiService {
  static const String baseUrl = "http://127.0.0.1:8000";
  static const Map<String, String> _jsonHeaders = {
    "Content-Type": "application/json",
  };

  // ---------------- USERS ----------------
  static Future<List<NewsItem>> fetchUsers() async {
    final res = await http.get(Uri.parse("$baseUrl/api/users/"));
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => NewsItem.fromJson(e)).toList();
    }
    throw Exception("Failed to load users (${res.statusCode}): ${res.body}");
  }

  static Future<Map<String, dynamic>> fetchUser({
    int? id,
    String? phone,
  }) async {
    if (id != null && id != 0) {
      final res = await http.get(
        Uri.parse("$baseUrl/api/user/$id"),
        headers: _jsonHeaders,
      );
      if (res.statusCode == 200) return jsonDecode(res.body);
      throw Exception("Failed to load user (${res.statusCode}): ${res.body}");
    }

    if (phone != null && phone.isNotEmpty) {
      final uri = Uri.parse(
        "$baseUrl/api/user",
      ).replace(queryParameters: {"phone": phone});
      final res = await http.get(uri, headers: _jsonHeaders);
      if (res.statusCode == 200) return jsonDecode(res.body);
      throw Exception("Failed to load user (${res.statusCode}): ${res.body}");
    }

    throw Exception("fetchUser requires id or phone");
  }

  // ---------------- AUTH ----------------
  static Future<Map<String, dynamic>> registerUser({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/api/register"),
      headers: _jsonHeaders,
      body: jsonEncode({
        "username": "$firstName $lastName",
        "first_name": firstName,
        "last_name": lastName,
        "email": email,
        "phone": phone,
        "password": password,
      }),
    );

    if (res.statusCode == 201 || res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    throw Exception("Registration failed (${res.statusCode}): ${res.body}");
  }

  static Future<Map<String, dynamic>> loginUser({
    required String phone,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/api/login"),
      headers: _jsonHeaders,
      body: jsonEncode({"phone": phone, "password": password}),
    );

    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception("Login failed (${res.statusCode}): ${res.body}");
  }

  // ---------------- CATEGORIES ----------------
  static Future<List<CategoryItem>> fetchCategories() async {
    final res = await http.get(Uri.parse("$baseUrl/api/categories/"));
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => CategoryItem.fromJson(e)).toList();
    }
    throw Exception(
      "Failed to load categories (${res.statusCode}): ${res.body}",
    );
  }

  // ---------------- PRODUCTS ----------------
  static Future<List<ProductModel>> fetchProducts() async {
    final res = await http.get(Uri.parse("$baseUrl/api/products/"));
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => ProductModel.fromJson(e)).toList();
    }
    throw Exception("Failed to load products (${res.statusCode}): ${res.body}");
  }

  static Future<ProductModel> fetchProductDetail(String id) async {
    final res = await http.get(Uri.parse("$baseUrl/api/products/$id/"));
    if (res.statusCode == 200) {
      return ProductModel.fromJson(jsonDecode(res.body));
    }
    throw Exception("Failed to load product (${res.statusCode}): ${res.body}");
  }

  // ---------------- ORDERS (History) ----------------
  static Future<List<Map<String, dynamic>>> fetchOrders({
    int? userId,
    String? phone,
  }) async {
    final params = <String, String>{};
    if (userId != null && userId != 0) {
      params["user_id"] = "$userId";
    } else if (phone != null && phone.isNotEmpty) {
      params["phone"] = phone;
    }
    final uri = Uri.parse(
      "$baseUrl/api/orders/",
    ).replace(queryParameters: params);
    final res = await http.get(uri, headers: _jsonHeaders);
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      if (body is List) {
        return body
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList();
      }
      throw Exception("Unexpected orders response: $body");
    }
    throw Exception("Failed to load orders (${res.statusCode}): ${res.body}");
  }

  // ---------------- BANNERS ----------------
  static Future<List<String>> fetchBanners() async {
    final res = await http.get(Uri.parse("$baseUrl/api/banner"));
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);

      final List<dynamic> items;
      if (body is List) {
        items = body;
      } else if (body is Map && body["banners"] is List) {
        items = body["banners"] as List;
      } else {
        throw Exception("Unexpected banner response: $body");
      }

      final urls = <String>[];
      for (final item in items) {
        final u = _extractBannerUrl(item);
        if (u != null && u.trim().isNotEmpty) urls.add(u.trim());
      }
      return urls;
    }
    throw Exception("Failed to load banners (${res.statusCode}): ${res.body}");
  }

  static String? _extractBannerUrl(dynamic item) {
    if (item is Map) {
      for (final key in ["image", "img", "url", "path"]) {
        final v = item[key];
        if (v == null) continue;
        final s = v.toString().trim();
        if (s.isNotEmpty) return s;
      }
      return null;
    }
    if (item is String) {
      final decoded = Uri.decodeComponent(item);
      final startHttp = decoded.indexOf("http");
      if (startHttp != -1) return decoded.substring(startHttp);
      if (decoded.startsWith("/")) return decoded;
      return decoded;
    }
    return null;
  }

  // ---------------- ORDER + PAYMENT ----------------
  // Receipt optional, send JSON payload in "payload" field
  static Future<Map<String, dynamic>> createOrderWithReceipt(
    Map<String, dynamic> payload, {
    File? receipt,
    Uint8List? receiptBytes,
    String? receiptName,
  }) async {
    final req = http.MultipartRequest(
      "POST",
      Uri.parse("$baseUrl/api/orders/"),
    );

    req.fields["payload"] = jsonEncode(payload);

    if (receipt != null && !kIsWeb) {
      req.files.add(await http.MultipartFile.fromPath("receipt", receipt.path));
    } else if (receiptBytes != null && receiptBytes.isNotEmpty) {
      req.files.add(
        http.MultipartFile.fromBytes(
          "receipt",
          receiptBytes,
          filename: receiptName ?? "receipt.jpg",
        ),
      );
    }

    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body);
    }
    throw Exception("Order failed (${res.statusCode}): ${res.body}");
  }

  // ---------------- PROFILE ----------------
  static Future<Map<String, dynamic>> updateProfile({
    required int userId,
    String? username,
    String? email,
    String? phone,
    String? password,
    File? avatarFile,
    Uint8List? avatarBytes,
    String? avatarName,
  }) async {
    final uri = Uri.parse("$baseUrl/api/users/$userId/");
    final req = http.MultipartRequest("PATCH", uri);

    if (username != null) req.fields["username"] = username;
    if (email != null) req.fields["email"] = email;
    if (phone != null) req.fields["phone"] = phone;
    if (password != null && password.isNotEmpty) {
      req.fields["password"] = password;
    }

    if (avatarFile != null && !kIsWeb) {
      req.files.add(
        await http.MultipartFile.fromPath("avatar", avatarFile.path),
      );
    } else if (avatarBytes != null && avatarBytes.isNotEmpty) {
      req.files.add(
        http.MultipartFile.fromBytes(
          "avatar",
          avatarBytes,
          filename: avatarName ?? "avatar.jpg",
        ),
      );
    }

    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body);
    }
    throw Exception("Profile update failed (${res.statusCode}): ${res.body}");
  }
}
