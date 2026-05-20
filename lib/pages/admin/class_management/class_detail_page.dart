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

class _ClassDetailPageState extends State<ClassDetailPage> {
  late Future<Map<String, dynamic>> _dataFuture;
  final _studentUsernameController = TextEditingController();
  bool _addingStudent = false;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  @override
  void dispose() {
    _studentUsernameController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _loadData() async {
    final classData = await _getWithRefresh(
      '/identity/courses/${widget.classId}',
    );
    final sessionsData = await _getWithRefresh(
      '/identity/class_sessions/allclasssessions/${widget.classId}?page=0&size=100',
    );
    final studentsData = await _getWithRefresh(
      '/identity/enrolls/${widget.classId}',
    );

    return {
      'class': classData['result'] ?? <String, dynamic>{},
      'sessions': _contentList(sessionsData),
      'students': _resultList(studentsData),
    };
  }

  List<Map<String, dynamic>> _contentList(Map<String, dynamic> data) {
    final raw = data['result'] is Map ? data['result']['content'] : null;
    if (raw is! List) return <Map<String, dynamic>>[];
    return raw
        .whereType<Map>()
        .map((item) => item.map((key, value) => MapEntry('$key', value)))
        .toList();
  }

  List<Map<String, dynamic>> _resultList(Map<String, dynamic> data) {
    final raw = data['result'];
    if (raw is! List) return <Map<String, dynamic>>[];
    return raw
        .whereType<Map>()
        .map((item) => item.map((key, value) => MapEntry('$key', value)))
        .toList();
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

  Future<Map<String, dynamic>> _postWithRefresh(
    String path,
    Map<String, dynamic> body,
  ) async {
    var response = await ApiService.post(
      path,
      token: authService.accessToken,
      body: body,
    );
    if (response.statusCode == 401) {
      final refreshResponse = await ApiService.post(
        '/identity/auth/refresh',
        body: {'token': authService.accessToken},
      );
      final refreshData = jsonDecode(refreshResponse.body);
      if (refreshData['code'] == 1000) {
        await authService.setAuth(refreshData['result']['token']);
        response = await ApiService.post(
          path,
          token: authService.accessToken,
          body: body,
        );
      } else {
        await authService.clearAuth();
        throw UnauthorizedException();
      }
    }
    return jsonDecode(response.body);
  }

  Future<void> _addStudentByUsername() async {
    final username = _studentUsernameController.text.trim();
    if (username.isEmpty) {
      _showSnackBar('Vui lòng nhập tên đăng nhập học viên');
      return;
    }

    setState(() => _addingStudent = true);
    try {
      final studentId = await _findStudentIdByUsername(username);
      if (studentId == null) {
        _showSnackBar('KhÃ´ng tÃ¬m tháº¥y há»c viÃªn vá»›i tÃªn Ä‘Äƒng nháº­p nÃ y');
        return;
      }

      final data = await _postWithRefresh('/identity/enrolls', {
        'classId': widget.classId,
        'studentId': studentId,
        'studentUsername': username,
      });
      if (data['code'] == 1000) {
        _studentUsernameController.clear();
        _showSnackBar('Đã thêm học viên vào lớp');
        setState(() => _dataFuture = _loadData());
      } else {
        _showSnackBar(data['message']?.toString() ?? 'Thêm học viên thất bại');
      }
    } finally {
      if (mounted) setState(() => _addingStudent = false);
    }
  }

  Future<String?> _findStudentIdByUsername(String username) async {
    final data = await _getWithRefresh('/identity/users/students?page=0&size=1000');
    final normalizedUsername = username.toLowerCase();
    final students = _contentList(data);

    for (final student in students) {
      final candidateUsername =
          student['username']?.toString().trim().toLowerCase();
      if (candidateUsername == normalizedUsername) {
        final studentId = student['id']?.toString();
        if (studentId != null && studentId.isNotEmpty) return studentId;
      }
    }

    return null;
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _timeText(Map<String, dynamic> session) {
    final day = getDayShortName(session['daysOfWeek']?.toString() ?? '');
    return '$day ${session['startTime'] ?? ''} - ${session['endTime'] ?? ''}';
  }

  Widget _buildInfo(Map<String, dynamic> info) {
    Widget row(String label, Object? value) {
      return Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            SizedBox(width: 150, child: Text(label)),
            Expanded(child: Text(value?.toString() ?? '')),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        row('Tên lớp', info['name']),
        row('Giáo viên', info['teacherName']),
        row('Ngày bắt đầu', info['startDate']),
        row('Ngày kết thúc', info['endDate']),
      ],
    );
  }

  Widget _buildSessions(List<Map<String, dynamic>> sessions) {
    if (sessions.isEmpty) {
      return Text('Chưa có buổi học nào');
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(Color(0xFF1E40AF)),
        columns: const [
          DataColumn(
            label: Text(
              'Buổi học',
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
        rows: sessions.map((session) {
          return DataRow(
            cells: [
              DataCell(Text(_timeText(session))),
              DataCell(Text(session['topic']?.toString() ?? '')),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStudents(List<Map<String, dynamic>> students) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 360,
              child: TextField(
                controller: _studentUsernameController,
                decoration: InputDecoration(
                  labelText: 'Tên đăng nhập học viên',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _addingStudent ? null : _addStudentByUsername,
              icon: _addingStudent
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.person_add_alt_1_outlined),
              label: Text('Thêm học viên'),
            ),
          ],
        ),
        SizedBox(height: 12),
        if (students.isEmpty)
          Text('Chưa có học viên nào')
        else
          SingleChildScrollView(
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

        final info = snapshot.data?['class'];
        final classInfo = info is Map<String, dynamic>
            ? info
            : <String, dynamic>{};
        final className = classInfo['name']?.toString() ?? '';
        final sessions = snapshot.data?['sessions'] is List
            ? (snapshot.data!['sessions'] as List)
                  .whereType<Map<String, dynamic>>()
                  .toList()
            : <Map<String, dynamic>>[];
        final students = snapshot.data?['students'] is List
            ? (snapshot.data!['students'] as List)
                  .whereType<Map<String, dynamic>>()
                  .toList()
            : <Map<String, dynamic>>[];

        return Title(
          color: Colors.black,
          title: className.isEmpty ? 'Lớp học' : 'Lớp học $className',
          child: SiteLayout(
            menuNo: 14,
            content: SelectionArea(
              child: Container(
                color: Colors.white,
                child: ListView(
                  padding: EdgeInsets.all(16),
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.arrow_circle_left_outlined,
                            size: 32,
                          ),
                          onPressed: () => context.go('/class-management'),
                        ),
                        Text(
                          className.isEmpty
                              ? 'Thông tin lớp học'
                              : 'Thông tin lớp học: $className',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Spacer(),
                        ElevatedButton.icon(
                          onPressed: () => context.go(
                            '/class-management/${widget.classId}/add-class-session',
                          ),
                          icon: Icon(Icons.add_outlined, size: 20),
                          label: Text('Thêm buổi học'),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      Center(child: CircularProgressIndicator())
                    else if (snapshot.hasError)
                      Center(child: Text('Lỗi tải thông tin lớp học'))
                    else ...[
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 30),
                        child: _buildInfo(classInfo),
                      ),
                      SizedBox(height: 24),
                      Text(
                        'Danh sách buổi học',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 12),
                      _buildSessions(sessions),
                      SizedBox(height: 24),
                      Text(
                        'Danh sách học viên',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 12),
                      _buildStudents(students),
                    ],
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
