import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  String? _accessToken;
  DateTime? _expiredAt;

  String? get accessToken => _accessToken;
  DateTime? get expiredAt => _expiredAt;

  bool get isLoggedIn {
    if (_accessToken == null || _expiredAt == null) return false;
    return DateTime.now().isBefore(_expiredAt!);
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final expiryStr = prefs.getString('access_token_expiry');
    if (token != null && expiryStr != null) {
      final expiry = DateTime.tryParse(expiryStr);
      if (expiry != null && DateTime.now().isBefore(expiry)) {
        _accessToken = token;
        _expiredAt = expiry;
      } else {
        await clearAuth();
      }
    }
    notifyListeners();
  }

  Future<void> setAuth(String token, DateTime expiry) async {
    _accessToken = token;
    _expiredAt = expiry;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
    await prefs.setString('access_token_expiry', expiry.toIso8601String());
    notifyListeners();
  }

  Future<void> clearAuth() async {
    _accessToken = null;
    _expiredAt = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('access_token_expiry');
    notifyListeners();
  }
}

final authService = AuthService();