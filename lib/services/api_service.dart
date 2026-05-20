import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:universal_html/html.dart' as html;

class ApiService {
  static const _buildBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const _fallbackBaseUrl =
      'https://identical-size-pork-seas.trycloudflare.com';

  static String get baseUrl {
    final fromBuild = _normalizeBaseUrl(_buildBaseUrl);
    if (fromBuild != null) return fromBuild;

    final fromHtml = _normalizeBaseUrl(
      html.document
          .querySelector('meta[name="api-base-url"]')
          ?.getAttribute('content'),
    );
    if (fromHtml != null) return fromHtml;

    return _fallbackBaseUrl;
  }

  static Future<http.Response> get(String path, {String? token}) {
    return http.get(Uri.parse('$baseUrl$path'), headers: _headers(token));
  }

  static Future<http.Response> post(
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) {
    return http.post(
      Uri.parse('$baseUrl$path'),
      headers: _headers(token),
      body: body == null ? null : jsonEncode(body),
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
      body: body == null ? null : jsonEncode(body),
    );
  }

  static Future<http.Response> delete(String path, {String? token}) {
    return http.delete(Uri.parse('$baseUrl$path'), headers: _headers(token));
  }

  static Map<String, String> _headers(String? token) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static String? _normalizeBaseUrl(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed.replaceFirst(RegExp(r'/+$'), '');
  }
}
