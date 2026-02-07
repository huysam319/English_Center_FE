import 'dart:convert';

import 'package:english_center_fe/services/auth_service.dart';
import 'package:english_center_fe/widgets/layout/layout.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../exceptions/unauthorized_exception.dart';
import '../../../services/api_service.dart';

class StudentManagementPage extends StatefulWidget {
  const StudentManagementPage({super.key});

  @override
  State<StudentManagementPage> createState() => _StudentManagementPageState();
}

Future<Map<String, dynamic>> _loadAllStudents() async {
  var response = await ApiService.get(
    '/identity/users/students',
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
        '/identity/users/students',
        token: authService.accessToken,
      );
    } else {
      await authService.clearAuth();
      throw UnauthorizedException();
    }
  }

  return jsonDecode(response.body);
}

class _StudentManagementPageState extends State<StudentManagementPage> {
  late final Future<Map<String, dynamic>> _dataFuture;
  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();

  static String _asCellText(Object? value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is num || value is bool) return value.toString();
    if (value is DateTime) return value.toIso8601String();
    return jsonEncode(value);
  }

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadAllStudents();
  }

  @override
  void dispose() {
    _verticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Title(
      color: Colors.black,
      title: "Quản lý học viên",
      child: SiteLayout(
        menuNo: 16,
        content: SelectionArea(
          child: Container(
            color: Colors.white,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: Container()),
                      ElevatedButton(
                        onPressed: () {
                          context.go('/student-management/create');
                        },
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all(
                            Color(0xFF1E40AF),
                          ),
                          foregroundColor: WidgetStateProperty.all(Colors.white),
                          overlayColor: WidgetStateProperty.all(
                            Colors.transparent,
                          ),
                          minimumSize: WidgetStateProperty.all(Size(150, 50)),
                          elevation: WidgetStateProperty.all(0),
                          shape: WidgetStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.add_outlined, size: 20),
                            SizedBox(width: 4),
                            Text('Thêm học viên'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
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
                            child: Text('Lỗi tải thông tin học viên'),
                          );
                        } else if (snapshot.hasData) {
                          final result = snapshot.data!['result'];
                          if (result is! List) {
                            return Center(
                              child: Text('Dữ liệu học viên không hợp lệ'),
                            );
                          }

                          final students = result
                              .whereType<Map>()
                              .map(
                                (e) => e.map((k, v) => MapEntry(k.toString(), v)),
                              )
                              .toList();

                          if (students.isEmpty) {
                            return Center(
                              child: Text('Chưa có học viên nào'),
                            );
                          }

                          return SizedBox(
                            width: double.infinity,
                            height: double.infinity,
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return Scrollbar(
                                  controller: _verticalController,
                                  thumbVisibility: true,
                                  interactive: true,
                                  child: SingleChildScrollView(
                                    controller: _verticalController,
                                    padding: EdgeInsets.all(16),
                                    child: Scrollbar(
                                      controller: _horizontalController,
                                      thumbVisibility: true,
                                      interactive: true,
                                      notificationPredicate: (notification) =>
                                          notification.metrics.axis == Axis.horizontal,
                                      scrollbarOrientation: ScrollbarOrientation.bottom,
                                      child: SingleChildScrollView(
                                        controller: _horizontalController,
                                        scrollDirection: Axis.horizontal,
                                        child: ConstrainedBox(
                                          constraints: BoxConstraints(
                                            minWidth: constraints.maxWidth - 32,
                                          ),
                                          child: DataTable(
                                            headingRowColor: WidgetStateProperty.all(
                                              Color(0xFF1E40AF),
                                            ),
                                            headingRowHeight: 45,
                                            dataRowMinHeight: 40,
                                            dataRowMaxHeight: 40,
                                            columns: [
                                              DataColumn(
                                                label: DefaultTextStyle.merge(
                                                  child: Text(
                                                    "Tên đăng nhập",
                                                    selectionColor: Color(0xFF60A5FA),
                                                  ),
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              DataColumn(
                                                label: DefaultTextStyle.merge(
                                                  child: Text(
                                                    "Họ và tên",
                                                    selectionColor: Color(0xFF60A5FA),
                                                  ),
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              DataColumn(
                                                label: DefaultTextStyle.merge(
                                                  child: Text(
                                                    "Ngày sinh",
                                                    selectionColor: Color(0xFF60A5FA),
                                                  ),
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                            rows: [
                                              for (final student in students)
                                                DataRow(
                                                  cells: [
                                                    DataCell(
                                                      InkWell(
                                                        child: Text(
                                                          _asCellText(student['username']),
                                                          maxLines: 2,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: TextStyle(color: Colors.black),
                                                        ),
                                                        onTap: () {
                                                          context.go('/student-management/${student['id']}');
                                                        }
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Text(
                                                        _asCellText('${student['lastName']} ${student['firstName']}'),
                                                        maxLines: 2,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: TextStyle(color: Colors.black),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Text(
                                                        _asCellText(student['dob']),
                                                        maxLines: 2,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: TextStyle(color: Colors.black),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        } else {
                          return Center(child: Text('No data available'));
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
