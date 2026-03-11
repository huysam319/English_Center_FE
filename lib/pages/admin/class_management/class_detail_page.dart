import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/days_list.dart';
import '../../../exceptions/unauthorized_exception.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/layout/layout.dart';

class ClassDetailPage extends StatefulWidget {
  final String classId;

  const ClassDetailPage({super.key, required this.classId});

  @override
  State<ClassDetailPage> createState() => _ClassDetailPageState();
}

Future<Map<String, dynamic>> _loadClassInfo(String id) async {
  var response = await ApiService.get(
    '/identity/courses/$id',
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
        '/identity/courses/$id',
        token: authService.accessToken,
      );
    } else {
      await authService.clearAuth();
      throw UnauthorizedException();
    }
  }

  return jsonDecode(response.body);
}

Future<Map<String, dynamic>> _loadClassSessions(String classId, int page, int size) async {
  var response = await ApiService.get(
    '/identity/class_sessions/allclasssessions/$classId?page=$page&size=$size',
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
        '/identity/class_sessions/allclasssessions/$classId?page=$page&size=$size',
        token: authService.accessToken,
      );
    } else {
      await authService.clearAuth();
      throw UnauthorizedException();
    }
  }

  return jsonDecode(response.body);
}

class _ClassDetailPageState extends State<ClassDetailPage> {
  late final Future<Map<String, dynamic>> _classDataFuture;
  late final Future<Map<String, dynamic>> _classSessionsFuture;

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
    _classDataFuture = _loadClassInfo(widget.classId);
    _classSessionsFuture = _loadClassSessions(widget.classId, 0, 10);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _classDataFuture,
      builder: (context, snapshot) {
        Widget content = Container();
        String className = "";
        if (snapshot.connectionState == ConnectionState.waiting) {
          content = Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          final err = snapshot.error;
          if (err is UnauthorizedException) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) context.go('/login');
            });
            content = SizedBox.shrink();
          }
          content = Center(
            child: Text('Lỗi tải thông tin lớp học'),
          );
        } else if (snapshot.hasData) {
          final result = snapshot.data!['result'];
          className = result['name'];

          content = Column(
            children: [
              Row(
                children: [
                  SizedBox(width: 150, child: Text('Tên lớp'),),
                  Text('${result['name']}'),
                ],
              ),
              Row(
                children: [
                  SizedBox(width: 150, child: Text('Ngày bắt đầu'),),
                  Text('${result['startDate']}'),
                ],
              ),
              Row(
                children: [
                  SizedBox(width: 150, child: Text('Ngày kết thúc'),),
                  Text('${result['endDate']}'),
                ],
              ),

              SizedBox(height: 20,),

              Text(
                'Danh sách buổi học',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 12,),
              FutureBuilder<Map<String, dynamic>>(
                future: _classSessionsFuture,
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
                      child: Text('Lỗi tải thông tin buổi học'),
                    );
                  } else if (snapshot.hasData) {
                    final result = snapshot.data!['result']['content'];
                    if (result is! List) {
                      return Center(
                        child: Text('Dữ liệu buổi học không hợp lệ'),
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
                        child: Text('Chưa có buổi học nào'),
                      );
                    }

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        return Scrollbar(
                          controller: _verticalController,
                          thumbVisibility: true,
                          interactive: true,
                          child: SingleChildScrollView(
                            controller: _verticalController,
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
                                    minWidth: constraints.maxWidth,
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
                                            "Thời gian bắt đầu",
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
                                            "Thời gian kết thúc",
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
                                            "Ngày trong tuần",
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
                                            "Chủ đề",
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
                                            Text(
                                              _asCellText(classItem['startTime']),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              _asCellText(classItem['endTime']),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              days.firstWhere(
                                                (d) => d['id'] == classItem['daysOfWeek'],
                                                orElse: () => {'id': '', 'name': _asCellText(classItem['daysOfWeek'])},
                                              )['name'] ?? '',
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              _asCellText(classItem['topic']),
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
                    );
                  } else {
                    return Center(child: Text('No data available'));
                  }
                },
              ),
            ],
          );
        }

        return Title(
          color: Colors.black,
          title: "Lớp học $className",
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
                          IconButton(
                            icon: Icon(Icons.arrow_circle_left_outlined, size: 32),
                            onPressed: () {
                              context.go('/class-management');
                            },
                          ),
                          Text(
                            "Thông tin lớp học: $className",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      Row(
                        children: [
                          Expanded(child: Container(),),
                          ElevatedButton(
                            onPressed: () {
                              context.go('/class-management/${widget.classId}/add-class-session');
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
                                Text('Thêm buổi học'),
                              ],
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 20,),

                      Padding(
                        padding: EdgeInsets.fromLTRB(30, 0, 30, 0),
                        child: content,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }
    );
  }
}