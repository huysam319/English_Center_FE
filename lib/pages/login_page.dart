import 'dart:convert';

import 'package:english_center_fe/controllers/text_input_controller.dart';
import 'package:english_center_fe/widgets/login/password_field.dart';
import 'package:english_center_fe/widgets/login/role_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
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

      final response = await ApiService.post(
        '/identity/auth/token',
        {
          'username': usernameController.text,
          'password': passwordController.text,
        },
      );

      final data = jsonDecode(response.body);

      if (data != null && data['code'] == 1009) {
        usernameController.clear();
        passwordController.clear();

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tên đăng nhập hoặc mật khẩu không đúng')),
        );
        return;
      }

      String token = data['result']['token'];
      DateTime expiry = DateTime.now().add(Duration(seconds: 3600));
      authService.setAuth(token, expiry);
      
      if (!context.mounted) return;
      context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Title(
      color: Colors.black,
      title: "Đăng nhập",
      child: Shortcuts(
        shortcuts: {
          LogicalKeySet(LogicalKeyboardKey.enter): ActivateIntent(),
        },
        child: Actions(
          actions: {
            ActivateIntent: CallbackAction(
              onInvoke: (_) => _handleLogin(),
            ),
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
                      color: Colors.black.withValues(alpha: 0.05,),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text("Đăng nhập",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),

                    SizedBox(height: 24,),

                    RoleSelector(),

                    SizedBox(height: 24),

                    TextField(
                      controller: usernameController,
                      decoration: InputDecoration(
                        labelText: "Username",
                        errorText: _usernameError ? 'Vui lòng nhập tên đăng nhập' : null,
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

                    SizedBox(height: 16),

                    PasswordField(showError: _passwordError),

                    SizedBox(height: 16),

                    SizedBox(
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

                    SizedBox(height: 20),

                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Divider(
                          thickness: 1,
                          color: Color(0xFF8E8D8D),
                        ),
                        Container(
                          color: Colors.white, // màu nền box
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
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              width: 1,
                              color: Colors.black,
                            )
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset("assets/icons/google.png", width: 18,),
                            SizedBox(width: 12,),
                            Text("Đăng nhập bằng Google",
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