import 'dart:convert';

import 'package:english_center_fe/controllers/text_input_controller.dart';
import 'package:english_center_fe/widgets/login/password_field.dart';
import 'package:english_center_fe/widgets/login/role_selector.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Title(
      color: Colors.black,
      title: "Đăng nhập",
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                SizedBox(height: 16),

                PasswordField(),

                SizedBox(height: 16),

                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async { 
                      final response = await ApiService.post(
                        '/identity/auth/token',
                        {
                          'username': usernameController.text,
                          'password': passwordController.text,
                        },
                      );

                      final data = jsonDecode(response.body);
                      authService.accessToken = data['result']['token'];
                      authService.expiredAt = DateTime.now().add(Duration(seconds: 3600));
                      if (!context.mounted) return;
                      context.go('/'); 
                    },
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
    );
  }
}