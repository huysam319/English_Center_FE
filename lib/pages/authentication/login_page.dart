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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(normalizedMessage)),
    );
  }

  Widget _buildLoginCard(BuildContext context) {
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300),
    );

    return Container(
      width: 520,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(6),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/icons/logo.jpg',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thanh Quang English Center',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Đăng nhập để tiếp tục',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            'Đăng nhập',
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sử dụng tài khoản trung tâm hoặc đăng nhập bằng Google.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF64748B),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Semantics(
            label: 'username_text_field',
            textField: true,
            child: TextField(
              controller: usernameController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Username',
                hintText: 'Nhập tên đăng nhập',
                errorText: _usernameError ? 'Vui lòng nhập tên đăng nhập' : null,
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                labelStyle: const TextStyle(color: Color(0xFF475569)),
                hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                border: inputBorder,
                enabledBorder: inputBorder,
                focusedBorder: inputBorder.copyWith(
                  borderSide: const BorderSide(
                    color: Color(0xFF1E40AF),
                    width: 1.5,
                  ),
                ),
                errorBorder: inputBorder.copyWith(
                  borderSide: const BorderSide(color: Colors.red),
                ),
                focusedErrorBorder: inputBorder.copyWith(
                  borderSide: const BorderSide(color: Colors.red, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Semantics(
            label: 'password_text_field',
            textField: true,
            child: PasswordField(
              controller: passwordController,
              showError: _passwordError,
              labelText: 'Password',
              errorText: 'Vui lòng nhập mật khẩu',
              hintText: 'Nhập mật khẩu',
              textInputAction: TextInputAction.done,
            ),
          ),
          const SizedBox(height: 18),
          Semantics(
            label: 'login_button',
            button: true,
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E40AF),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Đăng nhập',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Divider(thickness: 1, color: Colors.grey.shade300),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'Hoặc',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: Divider(thickness: 1, color: Colors.grey.shade300),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 44,
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
                foregroundColor: Colors.black,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(width: 1, color: Colors.grey.shade300),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/icons/google.png', width: 18),
                  const SizedBox(width: 12),
                  Text(
                    'Đăng nhập bằng Google',
                    style: GoogleFonts.inter(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideDecoration({bool left = true}) {
    return SizedBox(
      width: 160,
      child: Stack(
        children: [
          Positioned(
            top: left ? 8 : 40,
            left: left ? 6 : null,
            right: left ? null : 6,
            child: Container(
              width: 120,
              height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                gradient: RadialGradient(
                  center: Alignment.topLeft,
                  radius: 1.0,
                  colors: [
                    Color(0xFF1E40AF).withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: left ? 18 : 8,
            left: left ? 24 : null,
            right: left ? null : 24,
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: Color(0xFF1E40AF).withOpacity(0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: left ? 140 : 120,
            left: left ? 40 : null,
            right: left ? null : 40,
            child: Transform.rotate(
              angle: left ? -0.4 : 0.4,
              child: Container(
                width: 58,
                height: 28,
                decoration: BoxDecoration(
                  color: Color(0xFF1E40AF).withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1100;

    return Title(
      color: Colors.black,
      title: 'Đăng nhập',
      child: Shortcuts(
        shortcuts: {LogicalKeySet(LogicalKeyboardKey.enter): ActivateIntent()},
        child: Actions(
          actions: {
            ActivateIntent: CallbackAction(onInvoke: (_) => _handleLogin()),
          },
          child: Scaffold(
            backgroundColor: const Color(0xFFF1F5F9),
            body: Stack(
              children: [
                Positioned(
                  top: -140,
                  left: -120,
                  child: Container(
                    width: 340,
                    height: 340,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF1E40AF).withValues(alpha: 0.10),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -130,
                  right: -100,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.36),
                    ),
                  ),
                ),
                SafeArea(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1280),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 24,
                        ),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 240),
                          curve: Curves.easeOut,
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 12 * (1 - value)),
                                child: child,
                              ),
                            );
                          },
                          child: isDesktop
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    _buildSideDecoration(left: true),
                                    const SizedBox(width: 12),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 24),
                                      child: _buildLoginCard(context),
                                    ),
                                    const SizedBox(width: 12),
                                    _buildSideDecoration(left: false),
                                  ],
                                )
                              : SingleChildScrollView(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _buildLoginCard(context),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
