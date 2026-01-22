import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  String? _accessToken;

  String? get accessToken => _accessToken;

  bool get isLoggedIn {
    if (_accessToken == null) return false;
    return true;
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token != null) {
      _accessToken = token;
    }
    notifyListeners();
  }

  Future<void> setAuth(String token) async {
    _accessToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
    notifyListeners();
  }

  Future<void> clearAuth() async {
    _accessToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    notifyListeners();
  }
}

final authService = AuthService();