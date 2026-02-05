import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const baseUrl = 'http://localhost:8080';

  static Future<http.Response> get(
    String path, {
    String? token,
  }) {
    return http.get(
      Uri.parse('$baseUrl$path'),
      headers: _headers(token),
    );
  }

  static Future<http.Response> post(
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) {
    return http.post(
      Uri.parse('$baseUrl$path'),
      headers: _headers(token),
      body: body == null? null: jsonEncode(body),
    );
  }

  static Future<http.Response> put(
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) {
    return http.put(
      Uri.parse('$baseUrl$path'),
      headers: _headers(token),
      body: body == null? null: jsonEncode(body),
    );
  }

  static Map<String, String> _headers(String? token) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}
