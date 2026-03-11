import 'dart:convert';

import 'package:english_center_fe/widgets/layout/layout.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../constants/days_list.dart';
import '../../exceptions/unauthorized_exception.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

class TeacherClassStudentsPage extends StatefulWidget {
  final String classId;

  const TeacherClassStudentsPage({super.key, required this.classId});

  @override
  State<TeacherClassStudentsPage> createState() => _TeacherClassStudentsPageState();
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

Future<Map<String, dynamic>> _loadStudentsByClassSessionId(String classSessionId) async {
  var response = await ApiService.get(
    '/identity/class_sessions/$classSessionId',
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
        '/identity/class_sessions/$classSessionId',
        token: authService.accessToken,
      );
    } else {
      await authService.clearAuth();
      throw UnauthorizedException();
    }
  }

  return jsonDecode(response.body);
}

class _TeacherClassStudentsPageState extends State<TeacherClassStudentsPage> {
  late final Future<Map<String, dynamic>> _classDataFuture;
  late final Future<Map<String, dynamic>> _classSessionsFuture;
  Future<Map<String, dynamic>>? _studentsDataFuture;
  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();

  String? _selectedSessionId;

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

                    final classSessions = result
                        .whereType<Map>()
                        .map(
                          (e) => e.map((k, v) => MapEntry(k.toString(), v)),
                        )
                        .toList();

                    if (classSessions.isEmpty) {
                      return Center(
                        child: Text('Chưa có buổi học nào'),
                      );
                    }

                    if (_selectedSessionId == null && classSessions.isNotEmpty) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() {
                            _selectedSessionId = classSessions[0]['id'].toString();
                            _studentsDataFuture = _loadStudentsByClassSessionId(_selectedSessionId!);
                          });
                        }
                      });
                    }
                    return Row(
                      children: [
                        for (final classSession in classSessions)
                          Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _selectedSessionId = classSession['id'].toString();
                                  _studentsDataFuture = _loadStudentsByClassSessionId(_selectedSessionId!);
                                });
                              },
                              style: ButtonStyle(
                                backgroundColor: WidgetStateProperty.all(
                                  _selectedSessionId == classSession['id'].toString()
                                      ? Color(0xFF1E40AF)   // xanh
                                      : Colors.grey.shade300 // xám
                                ),
                                foregroundColor: WidgetStateProperty.all(
                                  _selectedSessionId == classSession['id'].toString()
                                      ? Colors.white
                                      : Colors.black
                                ),
                                overlayColor: WidgetStateProperty.all(Colors.transparent),
                                minimumSize: WidgetStateProperty.all(Size(100, 40)),
                                elevation: WidgetStateProperty.all(0),
                                shape: WidgetStateProperty.all(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                              ),
                              child: Text(
                                '${getDayShortName(classSession['daysOfWeek'])} ${classSession['startTime']} - ${classSession['endTime']}',
                              ),
                            ),
                          ),
                      ],
                    );
                  } else {
                    return Center(child: Text('No data available'));
                  }
                }
              ),

              SizedBox(height: 20,),

              FutureBuilder<Map<String, dynamic>>(  // FutureBuilder theo class session
                future: _studentsDataFuture, 
                builder: (context, snapshot) {
                  // Nếu chưa có future (đang đợi chọn session)
                  if (_studentsDataFuture == null) {
                    return Center(child: CircularProgressIndicator());
                  }
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
                                            "ID học viên",
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
                                            "Tên đăng nhập",
                                            selectionColor: Color(0xFF60A5FA),
                                          ),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      // DataColumn(
                                      //   label: DefaultTextStyle.merge(
                                      //     child: Text(
                                      //       "ID buổi học",
                                      //       selectionColor: Color(0xFF60A5FA),
                                      //     ),
                                      //     style: TextStyle(
                                      //       color: Colors.white,
                                      //       fontWeight: FontWeight.bold,
                                      //     ),
                                      //   ),
                                      // ),
                                    ],
                                    rows: [
                                      for (final studentItem in students)
                                      DataRow(
                                        cells: [
                                          DataCell(
                                            InkWell(
                                              child: Text(
                                                _asCellText(studentItem['studentId']),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              onTap: () {
                                                // context.go('/class-management/${studentItem['id']}');
                                              },
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              _asCellText('${studentItem['lastName']} ${studentItem['firstName']}'),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              _asCellText(studentItem['username']),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          // DataCell(
                                          //   Text(
                                          //     _asCellText(studentItem['classSessionId']),
                                          //     maxLines: 2,
                                          //     overflow: TextOverflow.ellipsis,
                                          //   ),
                                          // ),
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
                }
              ),
            ],
          );
        }

        return Title(
          color: Colors.black,
          title: "Học viên | Lớp $className",
          child: SiteLayout(
            menuNo: 13,
            content: SelectionArea(
              child: Container(
                color: Colors.white,
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Lớp $className',
                          style: TextStyle(
                            color: Color(0xFF1E40AF),
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),

                      SizedBox(height: 20,),

                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              context.go('/classes/${widget.classId}');
                            }, 
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.all(Color(0xFFF1F3F4)),
                              foregroundColor: WidgetStateProperty.all(Color(0xFF1E40AF)),
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
                            child: Text("Lớp học"),
                          ),
                          SizedBox(width: 2,),
                          ElevatedButton(
                            onPressed: () {
                              context.go('/classes/${widget.classId}/students');
                            }, 
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.all(Color(0xFF1E40AF)),
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
                            child: Text("Học viên"),
                          ),
                          SizedBox(width: 2,),
                          ElevatedButton(
                            onPressed: () {
                              context.go('/classes/${widget.classId}/attendances');
                            }, 
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.all(Color(0xFFF1F3F4)),
                              foregroundColor: WidgetStateProperty.all(Color(0xFF1E40AF)),
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
                            child: Text("Điểm danh"),
                          ),
                        ],
                      ),

                      SizedBox(height: 40,),

                      content,
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