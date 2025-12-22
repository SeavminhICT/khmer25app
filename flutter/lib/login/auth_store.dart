import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:khmer25/services/analytics_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppUser {
  final int id;
  final String username;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String avatarUrl;

  const AppUser({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    this.avatarUrl = '',
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id']}') ?? 0,
      username: (json['username'] ?? '').toString(),
      firstName: (json['first_name'] ?? '').toString(),
      lastName: (json['last_name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      avatarUrl: (json['avatar_url'] ?? '').toString(),
    );
  }

  String get displayName {
    if (username.isNotEmpty) return username;
    final full = [firstName, lastName].where((e) => e.isNotEmpty).join(' ');
    return full.isNotEmpty ? full : 'Anonymous User';
  }

  String get emailDisplay => email.isNotEmpty ? email : 'No email provided';
  String get phoneDisplay => phone.isNotEmpty ? phone : 'Not Provided';

  Map<String, dynamic> toJson() => {
    "id": id,
    "username": username,
    "first_name": firstName,
    "last_name": lastName,
    "email": email,
    "phone": phone,
    "avatar_url": avatarUrl,
  };
}

class AuthStore {
  static const _userKey = 'auth_user';
  static const _tokenKey = 'auth_token';
  static SharedPreferences? _prefs;
  static String? _token;

  static final ValueNotifier<AppUser?> currentUser = ValueNotifier<AppUser?>(
    null,
  );

  static String? get token => _token;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    final saved = _prefs?.getString(_userKey);
    if (saved != null) {
      try {
        final map = jsonDecode(saved) as Map<String, dynamic>;
        currentUser.value = AppUser.fromJson(map);
      } catch (_) {}
    }
    _token = _prefs?.getString(_tokenKey);
  }

  static Future<void> setUser(AppUser? user, {String? token}) async {
    currentUser.value = user;
    if (token != null) _token = token;
    _prefs ??= await SharedPreferences.getInstance();
    if (user == null) {
      await _prefs?.remove(_userKey);
      await _prefs?.remove(_tokenKey);
      return;
    }
    await _prefs?.setString(_userKey, jsonEncode(user.toJson()));
    if (_token != null) {
      await _prefs?.setString(_tokenKey, _token!);
    }
  }

  static Future<void> clear() async {
    currentUser.value = null;
    _token = null;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.remove(_userKey);
    await _prefs?.remove(_tokenKey);
    AnalyticsService.clearUser();
  }

  static Future<void> logout() async {
    await clear();
  }
}
