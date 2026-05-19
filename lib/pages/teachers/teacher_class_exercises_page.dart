import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../exceptions/unauthorized_exception.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/layout/layout.dart';

class TeacherClassExercisesPage extends StatefulWidget {
  const TeacherClassExercisesPage({super.key, required this.classId});

  final String classId;

  @override
  State<TeacherClassExercisesPage> createState() =>
      _TeacherClassExercisesPageState();
}

class _TeacherClassExercisesPageState extends State<TeacherClassExercisesPage> {
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
    final exerciseData = await _getWithRefresh(
      '/identity/assessments/class/${widget.classId}',
    );
    final aiData = await _getWithRefresh(
      '/identity/ai-reading-assignments/teacher',
    );

    final exercisesResult = exerciseData['result'];
    final exercises = exercisesResult is List
        ? exercisesResult
              .whereType<Map>()
              .map((item) => item.map((key, value) => MapEntry('$key', value)))
              .toList()
        : <Map<String, dynamic>>[];
    final aiResult = aiData['result'];
    final aiAssignments = aiResult is List
        ? aiResult
              .whereType<Map>()
              .map((item) => item.map((key, value) => MapEntry('$key', value)))
              .where((item) => item['classId']?.toString() == widget.classId)
              .toList()
        : <Map<String, dynamic>>[];
    final aiSubmissions = <String, List<Map<String, dynamic>>>{};
    await Future.wait(
      aiAssignments.map((assignment) async {
        final id = assignment['id']?.toString();
        if (id == null) return;
        aiSubmissions[id] = await _loadAiSubmissions(id);
      }),
    );

    return {
      'class': classData['result'] ?? <String, dynamic>{},
      'exercises': exercises,
      'aiAssignments': aiAssignments,
      'aiSubmissions': aiSubmissions,
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

  Future<List<Map<String, dynamic>>> _loadAiSubmissions(
    String assignmentId,
  ) async {
    final data = await _getWithRefresh(
      '/identity/ai-reading-assignments/$assignmentId/submissions',
    );
    final result = data['result'];
    if (result is! List) return <Map<String, dynamic>>[];
    return result
        .whereType<Map>()
        .map((item) => item.map((key, value) => MapEntry('$key', value)))
        .toList();
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
        tab('Học viên', '/classes/$classId/students'),
        tab('Bài tập', '/classes/$classId/exercises', active: true),
        tab('Điểm danh', '/classes/$classId/attendances'),
      ],
    );
  }

  Widget _buildContent(
    List<Map<String, dynamic>> exercises,
    List<Map<String, dynamic>> aiAssignments,
    Map<String, List<Map<String, dynamic>>> aiSubmissions,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Bài tập thường',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            Spacer(),
            OutlinedButton.icon(
              onPressed: () =>
                  context.go('/classes/${widget.classId}/ai-reading'),
              icon: Icon(Icons.auto_awesome_outlined),
              label: Text('Bài đọc AI'),
            ),
            SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () =>
                  context.go('/classes/${widget.classId}/exercises/create'),
              icon: Icon(Icons.add),
              label: Text('Tạo bài tập'),
            ),
          ],
        ),
        SizedBox(height: 14),
        if (exercises.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(18),
            decoration: BoxDecoration(
              border: Border.all(color: Color(0xFFE0E0E0)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('Chưa có bài tập thường nào'),
          )
        else
          ListView.separated(
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
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Loại: ${exercise['type'] ?? 'EXERCISE'}'),
                      if (exercise['skill'] != null)
                        Text('Kỹ năng: ${exercise['skill']}'),
                    ],
                  ),
                  trailing: Icon(Icons.chevron_right),
                  onTap: id.isEmpty
                      ? null
                      : () => context.go(
                          '/classes/${widget.classId}/exercises/$id',
                        ),
                ),
              );
            },
          ),
        SizedBox(height: 24),
        Row(
          children: [
            Text(
              'Bài đọc AI đã giao',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            Spacer(),
            TextButton.icon(
              onPressed: () =>
                  context.go('/classes/${widget.classId}/ai-reading'),
              icon: Icon(Icons.visibility_outlined),
              label: Text('Xem chi tiết'),
            ),
          ],
        ),
        SizedBox(height: 10),
        if (aiAssignments.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(18),
            decoration: BoxDecoration(
              border: Border.all(color: Color(0xFFE0E0E0)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('Chưa có bài đọc AI nào'),
          )
        else
          ...aiAssignments.map((assignment) {
            final id = assignment['id']?.toString() ?? '';
            final submissions = aiSubmissions[id] ?? <Map<String, dynamic>>[];
            return Container(
              margin: EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                border: Border.all(color: Color(0xFFE0E0E0)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ExpansionTile(
                title: Text(
                  assignment['title']?.toString() ?? '',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  'Bài nộp: ${submissions.length} - Đã chấm: ${submissions.where((s) => s['score'] != null).length}',
                ),
                childrenPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  if (submissions.isEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Chưa có học viên nộp bài'),
                    )
                  else
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Học viên')),
                          DataColumn(label: Text('Tên đăng nhập')),
                          DataColumn(label: Text('Điểm')),
                          DataColumn(label: Text('Trạng thái')),
                        ],
                        rows: submissions.map((submission) {
                          final name =
                              '${submission['lastName'] ?? ''} ${submission['firstName'] ?? ''}'
                                  .trim();
                          return DataRow(
                            cells: [
                              DataCell(Text(name)),
                              DataCell(
                                Text(submission['username']?.toString() ?? ''),
                              ),
                              DataCell(
                                Text(submission['score']?.toString() ?? '-'),
                              ),
                              DataCell(
                                Text(submission['status']?.toString() ?? '-'),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            );
          }),
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

        final classInfo = snapshot.data?['class'];
        final className = classInfo is Map
            ? classInfo['name']?.toString() ?? ''
            : '';
        final exercises = snapshot.data?['exercises'] is List
            ? (snapshot.data!['exercises'] as List)
                  .whereType<Map<String, dynamic>>()
                  .toList()
            : <Map<String, dynamic>>[];
        final aiAssignments = snapshot.data?['aiAssignments'] is List
            ? (snapshot.data!['aiAssignments'] as List)
                  .whereType<Map<String, dynamic>>()
                  .toList()
            : <Map<String, dynamic>>[];
        final aiSubmissions =
            snapshot.data?['aiSubmissions']
                is Map<String, List<Map<String, dynamic>>>
            ? snapshot.data!['aiSubmissions']
                  as Map<String, List<Map<String, dynamic>>>
            : <String, List<Map<String, dynamic>>>{};

        return Title(
          color: Colors.black,
          title: className.isEmpty ? 'Bài tập' : 'Bài tập | Lớp $className',
          child: SiteLayout(
            menuNo: 13,
            content: SelectionArea(
              child: Container(
                color: Colors.white,
                child: ListView(
                  padding: EdgeInsets.all(30),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        className.isEmpty ? 'Lớp học' : 'Lớp $className',
                        style: TextStyle(
                          color: Color(0xFF1E40AF),
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    _buildClassTabs(),
                    SizedBox(height: 24),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      Center(child: CircularProgressIndicator())
                    else if (snapshot.hasError)
                      Center(child: Text('Lỗi tải danh sách bài tập'))
                    else
                      _buildContent(exercises, aiAssignments, aiSubmissions),
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
