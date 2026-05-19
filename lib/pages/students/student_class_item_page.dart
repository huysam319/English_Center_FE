import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../constants/days_list.dart';
import '../../exceptions/unauthorized_exception.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/layout/layout.dart';

class StudentClassItemPage extends StatefulWidget {
  final String classId;

  const StudentClassItemPage({super.key, required this.classId});

  @override
  State<StudentClassItemPage> createState() => _StudentClassItemPageState();
}

class _StudentClassItemPageState extends State<StudentClassItemPage> {
  late final Future<Map<String, dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  Future<Map<String, dynamic>> _loadData() async {
    final classData = await _getWithRefresh(
      '/identity/courses/${widget.classId}',
    );
    final exerciseData = await _getWithRefresh(
      '/identity/assessments/class/${widget.classId}',
    );

    return {
      'class': _extractMap(classData['result']) ?? <String, dynamic>{},
      'exercises': _extractList(exerciseData['result']),
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

  Map<String, dynamic>? _extractMap(dynamic value) {
    if (value is Map) {
      return value.map((key, value) => MapEntry('$key', value));
    }
    return null;
  }

  List<Map<String, dynamic>> _extractList(dynamic value) {
    final rawList = value is Map ? value['content'] : value;
    if (rawList is! List) return <Map<String, dynamic>>[];
    return rawList
        .whereType<Map>()
        .map((item) => item.map((key, value) => MapEntry('$key', value)))
        .toList();
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
    final start = _shortTime(session['startTime']);
    final end = _shortTime(session['endTime']);
    return '$day $start - $end'.trim();
  }

  Widget _buildClassInfo(Map<String, dynamic> classInfo) {
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

    final sessions = _sessions(classInfo);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        row('Tên lớp', classInfo['name']),
        row('Giáo viên', classInfo['teacherName']),
        row('Ngày bắt đầu', classInfo['startDate']),
        row('Ngày kết thúc', classInfo['endDate']),
        SizedBox(height: 8),
        Text('Buổi học', style: TextStyle(fontWeight: FontWeight.w700)),
        SizedBox(height: 8),
        if (sessions.isEmpty)
          Text('Chưa có buổi học nào')
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final session in sessions)
                Chip(
                  label: Text(
                    '${_sessionText(session)}'
                    '${(session['topic']?.toString() ?? '').isEmpty ? '' : ' - ${session['topic']}'}',
                  ),
                  backgroundColor: Color(0xFFEFF6FF),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildExercises(List<Map<String, dynamic>> exercises) {
    if (exercises.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(18),
        decoration: BoxDecoration(
          border: Border.all(color: Color(0xFFE0E0E0)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text('Chưa có bài tập thường nào trong lớp'),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: exercises.length,
      separatorBuilder: (context, index) => SizedBox(height: 10),
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        final id = exercise['id']?.toString() ?? '';
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Color(0xFFE0E0E0)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            title: Text(
              exercise['title']?.toString() ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text('Loại: ${exercise['type'] ?? 'EXERCISE'}'),
            trailing: Icon(Icons.chevron_right),
            onTap: id.isEmpty ? null : () => context.go('/exercise/$id'),
          ),
        );
      },
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

        final classInfo = snapshot.data?['class'] is Map<String, dynamic>
            ? snapshot.data!['class'] as Map<String, dynamic>
            : <String, dynamic>{};
        final className = classInfo['name']?.toString() ?? '';
        final exercises = snapshot.data?['exercises'] is List
            ? (snapshot.data!['exercises'] as List)
                  .whereType<Map<String, dynamic>>()
                  .toList()
            : <Map<String, dynamic>>[];

        return Title(
          color: Colors.black,
          title: className.isEmpty ? 'Lớp học' : 'Lớp $className',
          child: SiteLayout(
            menuNo: 3,
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
                    if (snapshot.connectionState == ConnectionState.waiting)
                      Center(child: CircularProgressIndicator())
                    else if (snapshot.hasError)
                      Center(child: Text('Lỗi tải thông tin lớp học'))
                    else ...[
                      _buildClassInfo(classInfo),
                      SizedBox(height: 24),
                      Row(
                        children: [
                          Text(
                            'Danh sách bài tập',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Spacer(),
                          OutlinedButton.icon(
                            onPressed: () => context.go('/class/exercise'),
                            icon: Icon(Icons.auto_awesome_outlined),
                            label: Text('Bài đọc AI được giao'),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      _buildExercises(exercises),
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