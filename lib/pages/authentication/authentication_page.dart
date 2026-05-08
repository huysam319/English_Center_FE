import 'dart:convert';

import 'package:english_center_fe/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/auth_service.dart';

class AuthenticationPage extends StatefulWidget {
  const AuthenticationPage({super.key});

  @override
  State<AuthenticationPage> createState() => _AuthenticationPageState();
}

class _AuthenticationPageState extends State<AuthenticationPage> {
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    Future.microtask(_handleAuthentication);
  }

  Future<void> _handleAuthentication() async {
    final uri = Uri.base;
    final authCode = uri.queryParameters['code'];

    if (authCode == null || authCode.isEmpty) {
      setState(() {
        _errorMessage = 'Không tìm thấy mã xác thực từ Google.';
      });
      return;
    }

    try {
      final response = await ApiService.post(
        '/identity/auth/outbound/authentication?code=${Uri.encodeQueryComponent(authCode)}',
      );

      final data = jsonDecode(response.body);

      if (data['code'] == 1000) {
        final token = data['result']['token'];
        await authService.setAuth(token);

        final myInfoResponse = await ApiService.get(
          '/identity/users/my-info',
          token: authService.accessToken,
        );
        final myInfoData = jsonDecode(myInfoResponse.body);

        if (!mounted) return;
        if (myInfoData['result']['noPassword'] == true) {
          context.go('/update-account');
        } else {
          context.go('/');
        }
        return;
      }

      setState(() {
        _errorMessage = data['message'] ?? 'Đăng nhập Google thất bại.';
      });
    } catch (error) {
      setState(() {
        _errorMessage = 'Không thể hoàn tất đăng nhập Google: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _errorMessage == null
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Quay lại đăng nhập'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
