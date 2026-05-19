import 'dart:convert';

import 'package:english_center_fe/widgets/layout/layout.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../exceptions/unauthorized_exception.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

Future<Map<String, dynamic>> _loadUserProfile() async {
  var response = await ApiService.get(
    '/identity/users/my-info',
    token: authService.accessToken,
  );

  if (response.statusCode == 401) {
    var refreshResponse = await ApiService.post(
      '/identity/auth/refresh',
      body: { 'token': authService.accessToken },
    );

    var refreshData = jsonDecode(refreshResponse.body);
    if (refreshData['code'] == 1000) {
      final newToken = refreshData['result']['token'];
      await authService.setAuth(newToken);

      response = await ApiService.get(
        '/identity/users/my-info',
        token: authService.accessToken,
      );
    } else {
      await authService.clearAuth();
      throw UnauthorizedException();
    }
  }

  return jsonDecode(response.body);
}

class _ProfilePageState extends State<ProfilePage> {
  late final Future<Map<String, dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadUserProfile();
  }

  ButtonStyle _tabStyle(bool active) {
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.all(
        active ? Color(0xFF1E40AF) : Color(0xFFF1F3F4),
      ),
      foregroundColor: WidgetStateProperty.all(
        active ? Colors.white : Color(0xFF1E40AF),
      ),
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      minimumSize: WidgetStateProperty.all(Size(150, 50)),
      elevation: WidgetStateProperty.all(0),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    );
  }

  Widget tab(String label, String path, {bool active = false}) {
    return Padding(
      padding: EdgeInsets.only(right: 2),
      child: ElevatedButton(
        onPressed: () => context.go(path),
        style: _tabStyle(active),
        child: Text(label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Title(
      color: Colors.black,
      title: "Thông tin người dùng",
      child: SiteLayout(
        menuNo: 0, 
        title: "Thông tin người dùng",
        content: FutureBuilder<Map<String, dynamic>>(
          future: _dataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              final err = snapshot.error;
              if (err is UnauthorizedException) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) context.go('/login');
                });
                return SizedBox.shrink();
              }
              return Center(child: Text('Lỗi tải thông tin người dùng'));
            }
            final data = snapshot.data!;
            return Container(
              color: Colors.white,
              padding: EdgeInsets.all(50),
              child: Column(
                children: [
                  if ((data['result']['roles'] as List).any((role) => role['name'] == 'STUDENT'))
                    Row(
                      children: [
                        tab('Thông tin cá nhân', '/profile', active: true),
                        tab('Hồ sơ học viên', '/learning-profile'),
                      ],
                    ),
                  
                  SizedBox(height: 30,),

                  Row(
                    children: [
                      SizedBox(width: 150, child: Text("Tên đăng nhập:")),
                      Text('${data['result']['username'] ?? ''}'),
                    ],
                  ),
                  Row(
                    children: [
                      SizedBox(width: 150, child: Text("Họ và tên:")),
                      Text('${data['result']['lastName'] ?? ''} ${data['result']['firstName'] ?? ''}'),
                    ],
                  ),
                  Row(
                    children: [
                      SizedBox(width: 150, child: Text("Ngày sinh:")),
                      Text(data['result']['dob'] != null
                        ? DateFormat('dd/MM/yyyy').format(DateTime.parse(data['result']['dob']))
                        : ''
                      ),
                    ],
                  )
                ],
              ),
            );
          },
        ),
      ), 
    );
  }
}