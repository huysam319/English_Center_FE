import 'dart:convert';

import 'package:english_center_fe/constants/oauth_config.dart';
import 'package:english_center_fe/widgets/login/password_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/api_service.dart';
import '../../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _usernameError = false;
  bool _passwordError = false;

  @override
  void initState() {
    super.initState();
    usernameController.addListener(_onUsernameChanged);
    passwordController.addListener(_onPasswordChanged);
  }

  void _onUsernameChanged() {
    if (_usernameError && usernameController.text.trim().isNotEmpty) {
      setState(() {
        _usernameError = false;
      });
    }
  }

  void _onPasswordChanged() {
    if (_passwordError && passwordController.text.trim().isNotEmpty) {
      setState(() {
        _passwordError = false;
      });
    }
  }

  @override
  void dispose() {
    usernameController.clear();
    passwordController.clear();

    usernameController.removeListener(_onUsernameChanged);
    passwordController.removeListener(_onPasswordChanged);
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() {
      _usernameError = usernameController.text.trim().isEmpty;
      _passwordError = passwordController.text.trim().isEmpty;
    });

    if (_usernameError || _passwordError) return;

    try {
      final response = await ApiService.post(
        '/identity/auth/token',
        body: {
          'username': usernameController.text.trim(),
          'password': passwordController.text,
        },
      );

      final data = jsonDecode(response.body);
      final result = data is Map ? data['result'] : null;
      final token = result is Map ? result['token']?.toString() : null;

      if (response.statusCode != 200 ||
          data is! Map ||
          data['code'] != 1000 ||
          token == null ||
          token.isEmpty) {
        passwordController.clear();
        _showError(
          data is Map
              ? data['message']?.toString() ?? 'Đăng nhập thất bại'
              : 'Đăng nhập thất bại',
        );
        return;
      }

      await authService.setAuth(token);

      if (!mounted) return;
      context.go('/');
    } catch (_) {
      _showError('Không thể kết nối đến máy chủ');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    final normalizedMessage = message == 'Invalid credentials, please try again.'
        ? 'Tên đăng nhập hoặc mật khẩu không đúng'
        : message;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(normalizedMessage)));
  }

  @override
  Widget build(BuildContext context) {
    return Title(
      color: Colors.black,
      title: "Đăng nhập",
      child: Shortcuts(
        shortcuts: {LogicalKeySet(LogicalKeyboardKey.enter): ActivateIntent()},
        child: Actions(
          actions: {
            ActivateIntent: CallbackAction(onInvoke: (_) => _handleLogin()),
          },
          child: Scaffold(
            backgroundColor: Color(0xFFF1F5F9),
            body: Center(
              child: Container(
                width: 600,
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "Đăng nhập",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 24),
                    Semantics(
                      label: "username_text_field",
                      textField: true,
                      child: TextField(
                        controller: usernameController,
                        decoration: InputDecoration(
                          labelText: "Username",
                          errorText: _usernameError
                              ? 'Vui lòng nhập tên đăng nhập'
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.red),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.red, width: 2),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Semantics(
                      label: "password_text_field",
                      textField: true,
                      child: PasswordField(
                        controller: passwordController,
                        showError: _passwordError,
                        labelText: "Password",
                        errorText: "Vui lòng nhập mật khẩu",
                      ),
                    ),
                    SizedBox(height: 16),
                    Semantics(
                      label: "login_button",
                      button: true,
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF1E40AF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            "Đăng nhập",
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Divider(thickness: 1, color: Color(0xFF8E8D8D)),
                        Container(
                          color: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            "Hoặc",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    SizedBox(
                      height: 36,
                      child: ElevatedButton(
                        onPressed: () async {
                          final targetUrl =
                              '${OauthConfig.authUri}?redirect_uri=${Uri.encodeComponent(OauthConfig.redirectUri)}&response_type=code&client_id=${OauthConfig.clientId}&scope=openid%20email%20profile';
                          if (!await launchUrl(
                            Uri.parse(targetUrl),
                            webOnlyWindowName: '_self',
                          )) {
                            throw Exception('Could not launch $targetUrl');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(width: 1, color: Colors.black),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset("assets/icons/google.png", width: 18),
                            SizedBox(width: 12),
                            Text(
                              "Đăng nhập bằng Google",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
