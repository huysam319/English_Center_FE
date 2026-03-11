import 'dart:convert';

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../constants/days_list.dart';
import '../../exceptions/unauthorized_exception.dart';
import '../../router/app_router.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/layout/layout.dart';

class TeacherClassAttendancesPage extends StatefulWidget {
  final String classId;

  const TeacherClassAttendancesPage({super.key, required this.classId});

  @override
  State<TeacherClassAttendancesPage> createState() => _TeacherClassAttendancesPageState();
}

class _TeacherClassAttendancesPageState extends State<TeacherClassAttendancesPage> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedClassSessionId;
  Map<String, dynamic>? _selectedClassSession;
  Future<Map<String, dynamic>>? _studentsDataFuture;
  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();
  final Map<String, bool> _attendanceMap = {};
  late final Future<Map<String, dynamic>> _classDataFuture;

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

  Future<List<Map<String, dynamic>>> _loadAllClassSessions(String classId, String filter, int skip, int take) async {
    final page = skip ~/ take;
    try {
      var response = await ApiService.get(
        "/identity/class_sessions/allclasssessions/$classId?page=$page&size=$take",
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
            '/identity/class_sessions/allclasssessions/$classId?page=$page&size=$take',
            token: authService.accessToken,
          );
        } else {
          await authService.clearAuth();
          throw UnauthorizedException();
        }
      }

      final data = jsonDecode(response.body);
      if (data != null && data['result'] != null && data['result']['content'] != null) {
        return List<Map<String, dynamic>>.from(data['result']['content']);
      }
      return [];
    } on UnauthorizedException {
      await authService.clearAuth();
      appRouter.go('/login');
      return <Map<String, dynamic>>[];
    } catch (e) {
      return <Map<String, dynamic>>[];
    }
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

          content = Form(
            key: _formKey,
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 50, right: 50),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: DropdownSearch<Map<String, dynamic>>(
                          items: (filter, loadProps) => _loadAllClassSessions(widget.classId, filter, loadProps!.skip, loadProps.take),
                          itemAsString: (item) => '${getDayShortName(item['daysOfWeek'])} ${item['startTime']} - ${item['endTime']}',
                          compareFn: (a, b) => a['id'] == b['id'],
                          popupProps: PopupProps.menu(
                            disableFilter: true,
                            showSearchBox: false,
                            infiniteScrollProps: InfiniteScrollProps(
                              loadProps: LoadProps(skip: 0, take: 10),
                            ),
                            constraints: BoxConstraints(maxHeight: 150),
                            scrollbarProps: ScrollbarProps(
                              thumbVisibility: true,
                            ),
                            containerBuilder: (context, popupWidget) => Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.white,
                              ),
                              child: popupWidget,
                            ),
                            itemBuilder: (context, item, isDisabled, isSelected) => Container(
                              height: 40,
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '${getDayShortName(item['daysOfWeek'])} ${item['startTime']} - ${item['endTime']}',
                                style: TextStyle(
                                  color: isSelected ? Color(0xFF1E40AF) : Colors.black,
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                          autoValidateMode: AutovalidateMode.onUserInteraction,
                          decoratorProps: DropDownDecoratorProps(
                            decoration: InputDecoration(
                              labelText: 'Buổi học',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.red),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.red,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                          selectedItem: _selectedClassSession,
                          onChanged: (value) {
                            setState(() {
                              _selectedClassSession = value;
                              _selectedClassSessionId = value?['id']?.toString();
                              _studentsDataFuture = _loadStudentsByClassSessionId(_selectedClassSessionId!);
                            });
                          },
                          validator: (value) => value == null ? 'Vui lòng chọn buổi học' : null,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(child: Container()),
                      SizedBox(width: 12),
                      Expanded(child: Container()),
                    ],
                  ),
                ),

                SizedBox(height: 20,),

                FutureBuilder<Map<String, dynamic>>(  // FutureBuilder theo class session
                  future: _studentsDataFuture, 
                  builder: (context, snapshot) {
                    // Nếu chưa có future (đang đợi chọn session) - ẩn DataTable
                    if (_studentsDataFuture == null) {
                      return SizedBox.shrink(); // Hoặc có thể dùng Container() để ẩn hoàn toàn
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
                                        DataColumn(
                                          label: DefaultTextStyle.merge(
                                            child: Text(
                                              "Vắng",
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
                                            DataCell(
                                              Checkbox(
                                                value: _attendanceMap[studentItem['studentId']?.toString()] ?? false,
                                                onChanged: (bool? value) {
                                                  setState(() {
                                                    _attendanceMap[studentItem['studentId']?.toString() ?? ''] = value ?? false;
                                                  });
                                                },
                                                activeColor: Color(0xFF1E40AF),
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
                  }
                ),
                    
                SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(child: Container()),
                    ElevatedButton(
                      onPressed: () async {
                        if (!_formKey.currentState!.validate()) {
                          return;
                        }

                        List<String> absentStudentIds = _attendanceMap.entries
                            .where((entry) => entry.value == true)
                            .map((entry) => entry.key)
                            .toList();
                        var response = await ApiService.post(
                          '/identity/attendances',
                          token: authService.accessToken,
                          body: {
                            'classSessionId': _selectedClassSessionId,
                            'studentId': absentStudentIds,
                            'note': "",
                          },
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

                            response = await ApiService.post(
                              '/identity/attendances',
                              token: authService.accessToken,
                              body: {
                                'classSessionId': _selectedClassSessionId,
                                'studentId': absentStudentIds,
                                'note': "",
                              },
                            );
                          } else {
                            await authService.clearAuth();
                            throw UnauthorizedException();
                          }
                        }

                        final data = jsonDecode(response.body);
                        if (data != null && data['code'] == 1000) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Điểm danh thành công')),
                          );
                          context.go('/classes/${widget.classId}');
                        } else {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Điểm danh thất bại')),
                          );
                        }
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
                      child: Text('Điểm danh'),
                    ),
                    Expanded(child: Container()),
                  ],
                ),
              ],
            ),
          );
        }

        return Title(
          color: Colors.black,
          title: "Điểm danh | Lớp $className",
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
                            child: Text("Học viên"),
                          ),
                          SizedBox(width: 2,),
                          ElevatedButton(
                            onPressed: () {
                              context.go('/classes/${widget.classId}/attendances');
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