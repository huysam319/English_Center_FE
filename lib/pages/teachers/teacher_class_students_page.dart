import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../exceptions/unauthorized_exception.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/layout/layout.dart';

class TeacherClassStudentsPage extends StatefulWidget {
  final String classId;

  const TeacherClassStudentsPage({super.key, required this.classId});

  @override
  State<TeacherClassStudentsPage> createState() =>
      _TeacherClassStudentsPageState();
}

class _TeacherClassStudentsPageState extends State<TeacherClassStudentsPage> {
  late Future<Map<String, dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  Future<Map<String, dynamic>> _loadData() async {
    final classData = await _getWithRefresh(
      '/identity/courses/${widget.classId}',
    );
    final studentsData = await _getWithRefresh(
      '/identity/enrolls/${widget.classId}',
    );
    final studentsResult = studentsData['result'];
    final students = studentsResult is List
        ? studentsResult
              .whereType<Map>()
              .map((item) => item.map((key, value) => MapEntry('$key', value)))
              .toList()
        : <Map<String, dynamic>>[];

    return {
      'class': classData['result'] ?? <String, dynamic>{},
      'students': students,
    };
  }

  Future<Map<String, dynamic>> _getWithRefresh(String path) async {
    var response = await ApiService.get(path, token: authService.accessToken);
    if (response.statusCode == 401) {
      final refreshResponse = await ApiService.post(
        '/identity/auth/refresh',
        body: {'token': authService.accessToken},
      );
      final refreshData = jsonDecode(refreshResponse.body);
      if (refreshData['code'] == 1000) {
        await authService.setAuth(refreshData['result']['token']);
        response = await ApiService.get(path, token: authService.accessToken);
      } else {
        await authService.clearAuth();
        throw UnauthorizedException();
      }
    }
    return jsonDecode(response.body);
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

  Widget _buildClassTabs() {
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

    final classId = widget.classId;
    return Row(
      children: [
        tab('Lớp học', '/classes/$classId'),
        tab('Học viên', '/classes/$classId/students', active: true),
        tab('Bài tập', '/classes/$classId/exercises'),
        tab('Điểm danh', '/classes/$classId/attendances'),
      ],
    );
  }

  Widget _buildStudents(List<Map<String, dynamic>> students) {
    if (students.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(18),
        decoration: BoxDecoration(
          border: Border.all(color: Color(0xFFE0E0E0)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text('Chưa có học viên nào trong lớp'),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(Color(0xFF1E40AF)),
        columns: const [
          DataColumn(
            label: Text(
              'Tên đăng nhập',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Họ và tên',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'ID học viên',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
        rows: students.map((student) {
          final name =
              '${student['lastName'] ?? ''} ${student['firstName'] ?? ''}'
                  .trim();
          return DataRow(
            cells: [
              DataCell(Text(student['username']?.toString() ?? '')),
              DataCell(Text(name)),
              DataCell(Text(student['studentId']?.toString() ?? '')),
            ],
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError && snapshot.error is UnauthorizedException) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.go('/login');
          });
        }

        final classInfo = snapshot.data?['class'];
        final className = classInfo is Map
            ? classInfo['name']?.toString() ?? ''
            : '';
        final students = snapshot.data?['students'] is List
            ? (snapshot.data!['students'] as List)
                  .whereType<Map<String, dynamic>>()
                  .toList()
            : <Map<String, dynamic>>[];

        return Title(
          color: Colors.black,
          title: className.isEmpty ? 'Học viên' : 'Học viên | Lớp $className',
          child: SiteLayout(
            menuNo: 13,
            content: SelectionArea(
              child: Container(
                color: Colors.white,
                child: ListView(
                  padding: EdgeInsets.all(30),
                  children: [
                    Text(
                      className.isEmpty ? 'Lớp học' : 'Lớp $className',
                      style: TextStyle(
                        color: Color(0xFF1E40AF),
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    SizedBox(height: 20),
                    _buildClassTabs(),
                    SizedBox(height: 24),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      Center(child: CircularProgressIndicator())
                    else if (snapshot.hasError)
                      Center(child: Text('Lỗi tải danh sách học viên'))
                    else
                      _buildStudents(students),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
