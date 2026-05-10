import 'dart:convert';

import 'package:english_center_fe/widgets/layout/layout.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../exceptions/unauthorized_exception.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';

class ClassPage extends StatefulWidget {
  const ClassPage({super.key});

  @override
  State<ClassPage> createState() => _ClassPageState();
}

class _ClassPageState extends State<ClassPage> {
  late final Future<Map<String, dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadClassesData();
  }

  Future<Map<String, dynamic>> _loadClassesData() async {
    var response = await ApiService.get(
      '/identity/courses/student/me',
      token: authService.accessToken,
    );
    
    if (response.statusCode == 401) {
      var refreshResponse = await ApiService.post(
        '/identity/auth/refresh',
        body: {'token': authService.accessToken},
      );

      var refreshData = jsonDecode(refreshResponse.body);
      if (refreshData['code'] == 1000) {
        final newToken = refreshData['result']['token'];
        await authService.setAuth(newToken);

        response = await ApiService.get(
          '/identity/courses/student/me',
          token: authService.accessToken,
        );
      } else {
        await authService.clearAuth();
        throw UnauthorizedException();
      }
    }

    return jsonDecode(response.body);
  }

  @override
  Widget build(BuildContext context) {
    return Title(
      color: Colors.black,
      title: "Lớp của tôi",
      child: SiteLayout(
        menuNo: 3,
        content: Container(
          color: Colors.white,
          child: Padding(
            padding: EdgeInsets.fromLTRB(50, 16, 50, 16),
            child: Column(
              children: [
                Expanded(
                  child: FutureBuilder<Map<String, dynamic>>(
                    future: _dataFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        final err = snapshot.error;
                        if (err is UnauthorizedException) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) context.go('/login');
                          });
                          return SizedBox.shrink();
                        }
                        return Center(
                          child: Text('Lỗi tải thông tin lớp học'),
                        );
                      } else if (snapshot.hasData) {
                        final result = snapshot.data!['result'];
                        if (result is! List) {
                          return Center(
                            child: Text('Dữ liệu lớp học không hợp lệ'),
                          );
                        }

                        final classes = result
                            .whereType<Map>()
                            .map(
                              (e) => e.map((k, v) => MapEntry(k.toString(), v)),
                            )
                            .toList();

                        if (classes.isEmpty) {
                          return Center(
                            child: Text('Chưa có lớp học nào'),
                          );
                        }

                        return GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.5,
                          ),
                          itemCount: classes.length,
                          itemBuilder: (context, index) {
                            final classItem = classes[index];
                            return Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () {
                                  context.go('/class/${classItem['id']}');
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.blue.shade300,
                                              Colors.blue.shade500,
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            classItem['name'] ?? '',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      } else {
                        return Center(child: Text('Không có dữ liệu'));
                      }
                    },
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