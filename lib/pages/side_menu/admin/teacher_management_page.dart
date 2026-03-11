import 'dart:convert';

import 'package:english_center_fe/services/api_service.dart';
import 'package:english_center_fe/widgets/layout/layout.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:number_pagination/number_pagination.dart';

import '../../../exceptions/unauthorized_exception.dart';
import '../../../services/auth_service.dart';

class TeacherManagementPage extends StatefulWidget {
  const TeacherManagementPage({super.key});

  @override
  State<TeacherManagementPage> createState() => _TeacherManagementPageState();
}

Future<Map<String, dynamic>> _loadAllTeachers(int page, int size) async {
  var response = await ApiService.get(
    '/identity/users/teachers?page=$page&size=$size',
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
        '/identity/users/teachers?page=$page&size=$size',
        token: authService.accessToken,
      );
    } else {
      await authService.clearAuth();
      throw UnauthorizedException();
    }
  }

  return jsonDecode(response.body);
}

class _TeacherManagementPageState extends State<TeacherManagementPage> {
  late final Future<Map<String, dynamic>> _dataFuture;
  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();

  int _currentPage = 1;

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
    _dataFuture = _loadAllTeachers(0, 10);
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
      title: "Quản lý giáo viên",
      child: SiteLayout(
        menuNo: 15,
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
                          context.go('/teacher-management/create');
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
                            Text('Thêm giáo viên'),
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
                            child: Text('Lỗi tải thông tin giáo viên'),
                          );
                        } else if (snapshot.hasData) {
                          final result = snapshot.data!['result']['content'];
                          if (result is! List) {
                            return Center(
                              child: Text('Dữ liệu giáo viên không hợp lệ'),
                            );
                          }

                          final teachers = result
                              .whereType<Map>()
                              .map(
                                (e) => e.map((k, v) => MapEntry(k.toString(), v)),
                              )
                              .toList();

                          if (teachers.isEmpty) {
                            return Center(
                              child: Text('Chưa có giáo viên nào'),
                            );
                          }

                          return Column(
                            children: [
                              LayoutBuilder(
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
                                                for (final teacher in teachers)
                                                  DataRow(
                                                    cells: [
                                                      DataCell(
                                                        InkWell(
                                                          child: Text(
                                                            _asCellText(teacher['username']),
                                                            maxLines: 2,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                          onTap: () {
                                                            context.go('/teacher-management/${teacher['id']}');
                                                          },
                                                        ),
                                                      ),
                                                      DataCell(
                                                        Text(
                                                          _asCellText('${teacher['lastName']} ${teacher['firstName']}'),
                                                          maxLines: 2,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                      DataCell(
                                                        Text(
                                                          _asCellText(teacher['dob']),
                                                          maxLines: 2,
                                                          overflow: TextOverflow.ellipsis,
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

                              SizedBox(height: 8),

                              Padding(
                                padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: NumberPagination(
                                        onPageChanged: (value) => setState(() {
                                          _dataFuture = _loadAllTeachers(value - 1, 10);
                                          _currentPage = value;
                                        }),
                                        totalPages: (snapshot.data!['result']['totalElements'] / snapshot.data!['result']['size'] as double).ceil(),
                                        currentPage: _currentPage,
                                        visiblePagesCount: 10,
                                        buttonElevation: 0,
                                        buttonRadius: 5,
                                        controlButtonSize: Size(40, 40),
                                        numberButtonSize: Size(40, 40),
                                        selectedButtonColor: Color(0xFF1E40AF),
                                      ),
                                    ),

                                    SizedBox(width: 5,),

                                    Text(
                                      '${(_currentPage - 1) * 10 + 1} - ${_currentPage * 10 > snapshot.data!['result']['totalElements'] ? snapshot.data!['result']['totalElements'] : _currentPage * 10} của ${snapshot.data!['result']['totalElements']}',
                                    ),
                                  ],
                                ),
                              ),
                            ],
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