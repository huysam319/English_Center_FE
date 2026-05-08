import 'dart:convert';

import 'package:flutter/material.dart';
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
      '/identity/assessments/$exerciseId',
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
          '/identity/assessments/$exerciseId',
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
              child: Column(
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
                      FutureBuilder<Map<String, dynamic>>(
                        future: _exerciseDataFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return Center(child: Text('Lỗi tải danh sách bài tập'));
                          } else if (snapshot.hasData) {
                            final result = snapshot.data!['result'];
                            return Text(
                              "Bài tập ${result['title']}",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          } else {
                            return Text(
                              "Bài tập",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),

                  SizedBox(height: 20),



                  TextButton(
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
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}