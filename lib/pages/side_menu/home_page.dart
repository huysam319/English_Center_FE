import 'dart:convert';

import 'package:english_center_fe/widgets/layout/layout.dart';
import 'package:flutter/material.dart';

import '../../exceptions/unauthorized_exception.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final Future<Map<String, dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadUserProfile();
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

  String _formatVietnameseDate() {
    final now = DateTime.now();
    const weekdayNames = [
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
      'Chủ Nhật',
    ];
    final weekday = weekdayNames[now.weekday - 1];
    return '$weekday, ngày ${now.day} tháng ${now.month} năm ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Title(
      color: Colors.black,
      title: "Trang chủ",
      child: SiteLayout(
        menuNo: 1,
        content: Container(
          color: const Color(0xFFF1F5F9),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: FutureBuilder<Map<String, dynamic>>(
                              future: _dataFuture,
                              builder: (context, snapshot) {
                                final fullName = snapshot.hasData
                                  ? "${snapshot.data!['result']['lastName']} ${snapshot.data!['result']['firstName']}"
                                  : '...';
                                return Text(
                                  'Xin chào, $fullName',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E40AF),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _formatVietnameseDate(),
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF1E40AF),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 100),
                    // Hero banner
                    LayoutBuilder(builder: (context, constraints) {
                      final isDesktop = constraints.maxWidth >= 800;
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          height: isDesktop ? 300 : 200,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 12,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Center(
                                child: Image.asset(
                                  'assets/icons/banner.jpg',
                                  fit: BoxFit.contain,
                                  width: isDesktop ? 1000 : double.infinity,
                                  alignment: Alignment.center,
                                ),
                              ),
                              // subtle gradient overlay for polish
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      const Color(0xFF1E40AF).withOpacity(0.06),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                    // Decorative strip below banner
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1E40AF), Color(0xFF60A5FA)],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
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