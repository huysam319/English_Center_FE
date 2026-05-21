import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html/flutter_html.dart' as html;
import 'package:go_router/go_router.dart';

import '../../exceptions/unauthorized_exception.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/layout/layout.dart';

class TeacherClassExerciseDetailPage extends StatefulWidget {
  final String classId;
  final String exerciseId;

  const TeacherClassExerciseDetailPage({super.key, required this.classId, required this.exerciseId});

  @override
  State<TeacherClassExerciseDetailPage> createState() => _TeacherClassExerciseDetailPageState();
}

class _TeacherClassExerciseDetailPageState extends State<TeacherClassExerciseDetailPage> {
  late final Future<Map<String, dynamic>> _exerciseDataFuture;

  Future<Map<String, dynamic>> _loadExerciseData(String exerciseId) async {
    var response = await ApiService.get(
      '/identity/writing-assessments/$exerciseId/summary',
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
          '/identity/writing-assessments/$exerciseId/summary',
          token: authService.accessToken,
        );
      } else {
        await authService.clearAuth();
        throw UnauthorizedException();
      }
    }

    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> _loadPartInfo(String exerciseId, int partNumber) async {
    var response = await ApiService.get(
      '/identity/writing-assessments/$exerciseId?partNumber=$partNumber',
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
          '/identity/writing-assessments/$exerciseId?partNumber=$partNumber',
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
  void initState() {
    super.initState();
    _exerciseDataFuture = _loadExerciseData(widget.exerciseId);
  }

  @override
  Widget build(BuildContext context) {
    return Title(
      color: Colors.black,
      title: "Bài tập",
      child: SiteLayout(
        menuNo: 13,
        content: SelectionArea(
          child: Container(
            color: Colors.white,
            child: Padding(
              padding: EdgeInsets.all(30),
              child: FutureBuilder<Map<String, dynamic>>(
                future: _exerciseDataFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Lỗi tải danh sách bài tập'));
                  } else if (snapshot.hasData) {
                    final result = snapshot.data!['result'];
                    return ListView(
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.arrow_circle_left_outlined,
                                size: 32,
                              ),
                              onPressed: () {
                                context.go('/classes/${widget.classId}/exercises');
                              },
                            ),
                            
                            Text(
                              "Bài tập ${result['title']}",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 20),

                        Row(
                          children: [
                            SizedBox(
                              width: 225,
                              child: Text('Số lượng task:')
                            ),
                            Text(result['numberOfTasks'].toString())
                          ],
                        ),
                        Row(
                          children: [
                            SizedBox(
                              width: 225,
                              child: Text('Tổng số lượt làm bài:')
                            ),
                            Text(result['numberOfAttempts'].toString())
                          ],
                        ),
                        Row(
                          children: [
                            SizedBox(
                              width: 225,
                              child: Text('Số lượng học sinh làm bài:')
                            ),
                            Text(result['numberOfSubmittedStudents'].toString())
                          ],
                        ),
                        Row(
                          children: [
                            SizedBox(
                              width: 225,
                              child: Text('Số lượng học sinh đã chấm điểm:')
                            ),
                            Text(result['numberOfGradedAttempts'].toString())
                          ],
                        ),

                        Align(
                          alignment: Alignment.center,
                          child: TextButton(
                            onPressed: () {
                              context.go('/classes/${widget.classId}/exercises/${widget.exerciseId}/grading');
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
                            child: Text('Chấm bài'),
                          ),
                        ),

                        SizedBox(height: 20),

                        Column(
                          children: List.generate(result['numberOfTasks'], (index) {
                            return FutureBuilder<Map<String, dynamic>>(
                              future: _loadPartInfo(widget.exerciseId, index + 1),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return Center(child: CircularProgressIndicator());
                                } else if (snapshot.hasError) {
                                  return Center(child: Text('Lỗi tải thông tin task'));
                                } else if (snapshot.hasData) {
                                  final result = snapshot.data!['result'];
                                  return Column(
                                    children: [
                                      Text(
                                        'Task ${result['partNumber']}',
                                        style: TextStyle(
                                          fontSize: 20, 
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1E40AF),
                                        ),
                                      ),

                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          'Đề bài',
                                          style: TextStyle(
                                            fontSize: 16, 
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),

                                      Html(
                                        data: result['text'] ?? 'No title available',
                                        style: {
                                          "body": html.Style(fontSize: FontSize(16.0)),
                                        },
                                      ),

                                      if (result['imageUrl'] != null) Image.network(result['imageUrl']),

                                      const SizedBox(height: 10)
                                    ],
                                  );
                                }
                                else {
                                  return Center(child: Text('Không có dữ liệu'));
                                }
                              }
                            );
                          }),
                        ),
                      ],
                    );
                  }
                  else {
                    return Center(child: Text('Không có dữ liệu'));
                  }
                }
              ),
            ),
          ),
        ),
      ),
    );
  }
}