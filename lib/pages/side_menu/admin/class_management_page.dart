import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../exceptions/unauthorized_exception.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/layout/layout.dart';

class ClassManagementPage extends StatefulWidget {
  const ClassManagementPage({super.key});

  @override
  State<ClassManagementPage> createState() => _ClassManagementPageState();
}

Future<Map<String, dynamic>> _loadAllClasses() async {
  var response = await ApiService.get(
    '/identity/courses/allcourses',
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
        '/identity/courses/allcourses',
        token: authService.accessToken,
      );
    } else {
      await authService.clearAuth();
      throw UnauthorizedException();
    }
  }

  return jsonDecode(response.body);
}

class _ClassManagementPageState extends State<ClassManagementPage> {
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
    _dataFuture = _loadAllClasses();
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
      title: "Quản lý lớp học",
      child: SiteLayout(
        menuNo: 14,
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
                          context.go('/class-management/create');
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
                            Text('Thêm lớp học'),
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
                                                    "Tên lớp",
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
                                                    "Ngày bắt đầu",
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
                                                    "Ngày kết thúc",
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
                                                    "Số lượng học viên",
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
                                              for (final classItem in classes)
                                              DataRow(
                                                cells: [
                                                  DataCell(
                                                    InkWell(
                                                      child: Text(
                                                        _asCellText(classItem['name']),
                                                        maxLines: 2,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                      onTap: () {
                                                        context.go('/class-management/${classItem['id']}');
                                                      },
                                                    ),
                                                  ),
                                                  DataCell(
                                                    Text(
                                                      _asCellText(classItem['startDate']),
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  DataCell(
                                                    Text(
                                                      _asCellText(classItem['endDate']),
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  DataCell(
                                                    Text(
                                                      _asCellText(classItem['numberOfStudents']),
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