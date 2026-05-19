import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../constants/days_list.dart';
import '../../exceptions/unauthorized_exception.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/layout/layout.dart';

class TeacherClassItemPage extends StatefulWidget {
  final String classId;

  const TeacherClassItemPage({super.key, required this.classId});

  @override
  State<TeacherClassItemPage> createState() => _TeacherClassItemPageState();
}

Future<Map<String, dynamic>> _loadClassInfo(String id) async {
  var response = await ApiService.get(
    '/identity/courses/$id',
    token: authService.accessToken,
  );

  if (response.statusCode == 401) {
    final refreshResponse = await ApiService.post(
      '/identity/auth/refresh',
      body: {'token': authService.accessToken},
    );

    final refreshData = jsonDecode(refreshResponse.body);
    if (refreshData['code'] == 1000) {
      await authService.setAuth(refreshData['result']['token']);

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

class _TeacherClassItemPageState extends State<TeacherClassItemPage> {
  late final Future<Map<String, dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadClassInfo(widget.classId);
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
        tab('Lớp học', '/classes/$classId', active: true),
        tab('Học viên', '/classes/$classId/students'),
        tab('Bài tập', '/classes/$classId/exercises'),
        tab('Điểm danh', '/classes/$classId/attendances'),
      ],
    );
  }

  List<Map<String, dynamic>> _sessions(Map<String, dynamic> classInfo) {
    final raw = classInfo['classSessions'];
    if (raw is! List) return <Map<String, dynamic>>[];
    return raw
        .whereType<Map>()
        .map((item) => item.map((key, value) => MapEntry('$key', value)))
        .toList();
  }

  String _shortTime(dynamic value) {
    final text = value?.toString() ?? '';
    return text.length >= 5 ? text.substring(0, 5) : text;
  }

  String _sessionText(Map<String, dynamic> session) {
    final day = getDayShortName(session['daysOfWeek']?.toString() ?? '');
    return '$day ${_shortTime(session['startTime'])} - ${_shortTime(session['endTime'])}';
  }

  Widget _buildInfo(Map<String, dynamic> result) {
    Widget row(String label, Object? value) {
      return Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 150, child: Text(label)),
            Expanded(
              child: Text(
                value?.toString().isNotEmpty == true ? value.toString() : '-',
              ),
            ),
          ],
        ),
      );
    }

    final sessions = _sessions(result);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        row('Tên lớp', result['name']),
        row('Giáo viên', result['teacherName']),
        row('Ngày bắt đầu', result['startDate']),
        row('Ngày kết thúc', result['endDate']),
        row('Số học viên', result['numberOfStudents']),
        SizedBox(height: 12),
        Text('Buổi học', style: TextStyle(fontWeight: FontWeight.w700)),
        SizedBox(height: 8),
        if (sessions.isEmpty)
          Text('Chưa có buổi học nào')
        else
          DataTable(
            headingRowColor: WidgetStateProperty.all(Color(0xFF1E40AF)),
            columns: const [
              DataColumn(
                label: Text(
                  'Thời gian',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Chủ đề',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            rows: [
              for (final session in sessions)
                DataRow(
                  cells: [
                    DataCell(Text(_sessionText(session))),
                    DataCell(Text(session['topic']?.toString() ?? '')),
                  ],
                ),
            ],
          ),
      ],
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

        final result = snapshot.data?['result'] is Map
            ? (snapshot.data!['result'] as Map).map(
                (key, value) => MapEntry('$key', value),
              )
            : <String, dynamic>{};
        final className = result['name']?.toString() ?? '';

        return Title(
          color: Colors.black,
          title: className.isEmpty ? 'Lớp học' : 'Lớp $className',
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
                    SizedBox(height: 20),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      Center(child: CircularProgressIndicator())
                    else if (snapshot.hasError)
                      Center(child: Text('Lỗi tải thông tin lớp học'))
                    else
                      _buildInfo(result),
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
