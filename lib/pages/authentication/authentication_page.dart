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
  @override
  void initState() {
    super.initState();

    Future.microtask(_handleAuthentication);
  }

  Future<void> _handleAuthentication() async {
    final uri = Uri.base;
    final authCode = uri.queryParameters['code'];

    if (authCode == null) return;

    final response = await ApiService.post(
      '/identity/auth/outbound/authentication?code=$authCode',
    );

    final data = jsonDecode(response.body);

    if (data['code'] == 1000) {
      final token = data['result']['token'];
      authService.setAuth(token);

      final myInfoResponse = await ApiService.get(
        '/identity/users/my-info',
        token: authService.accessToken,
      );
      final myInfoData = jsonDecode(myInfoResponse.body);
      if (myInfoData['result']['noPassword'] == true) {
        context.go('/update-account');
      }
      else {
        context.go('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}