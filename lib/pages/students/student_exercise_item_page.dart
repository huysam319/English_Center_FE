import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../exceptions/unauthorized_exception.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/layout/layout.dart';

class StudentExerciseItemPage extends StatefulWidget {
  final String exerciseId;

  const StudentExerciseItemPage({super.key, required this.exerciseId});

  @override
  State<StudentExerciseItemPage> createState() => _StudentExerciseItemPageState();
}

class _StudentExerciseItemPageState extends State<StudentExerciseItemPage> {
  late final Future<Map<String, dynamic>> _exerciseDataFuture;
  late final Future<Map<String, dynamic>> _attemptsDataFuture;

  @override
  void initState() {
    super.initState();
    _exerciseDataFuture = _loadExerciseInfo(widget.exerciseId);
    _attemptsDataFuture = _loadAttemptsInfo(widget.exerciseId);
  }

  Future<Map<String, dynamic>> _loadExerciseInfo(String exerciseId) async {
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

  Future<Map<String, dynamic>> _loadAttemptsInfo(String exerciseId) async {
    var response = await ApiService.get(
      '/identity/attempts/my/$exerciseId',
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
          '/identity/attempts/my/$exerciseId',
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
      future: _exerciseDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: Text('No data available'));
        }

        final exerciseData = snapshot.data!['result'];

        return Title(
          color: Colors.black,
          title: exerciseData['title'] ?? "",
          child: SiteLayout(
            menuNo: 5,
            content: SelectionArea( 
              child: Container(
                color: Colors.white,
                child: ListView(
                  padding: EdgeInsets.all(16),
                  children: [
                    Text('${exerciseData['title'] ?? ""}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),

                    SizedBox(height: 20),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () {
                          showDialog<bool>(
                            context: context,
                            barrierDismissible: true,
                            builder: (context) {
                              return AlertDialog(
                                title: Text("Bắt đầu làm bài"),
                                content: Text("Bạn đã sẵn sàng làm bài chưa?"),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    style: ButtonStyle(
                                      backgroundColor: WidgetStateProperty.all(
                                        Color(0xFFF1F3F4),
                                      ),
                                      foregroundColor: WidgetStateProperty.all(
                                        Colors.black,
                                      ),
                                      overlayColor: WidgetStateProperty.all(
                                        Colors.transparent,
                                      ),
                                      minimumSize: WidgetStateProperty.all(
                                        Size(75, 35),
                                      ),
                                      elevation: WidgetStateProperty.all(0),
                                      shape: WidgetStateProperty.all(
                                        RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                    child: Text("Hủy"),
                                  ),
                                  ElevatedButton(
                                    onPressed: () async {
                                      Navigator.pop(context, true);

                                      final router = GoRouter.of(context);

                                      var response = await ApiService.post(
                                        '/identity/attempts/start',
                                        token: authService.accessToken,
                                        body: {
                                          'assessmentId': widget.exerciseId,
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
                                            '/identity/attempts/start',
                                            token: authService.accessToken,
                                            body: {
                                              'assessmentId': widget.exerciseId,
                                            },
                                          );
                                        } else {
                                          await authService.clearAuth();
                                          throw UnauthorizedException();
                                        }
                                      }

                                      final data = jsonDecode(response.body);

                                      if (data != null && data['code'] == 1000) {
                                        router.go(
                                          Uri(
                                            path: '/exercise/${widget.exerciseId}',
                                            queryParameters: {'attemptId': data['result']['id']},
                                          ).toString(),
                                        );
                                      } else {
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Hiện tại chưa thể làm bài được.')),
                                        );
                                      }
                                    },
                                    style: ButtonStyle(
                                      backgroundColor: WidgetStateProperty.all(
                                        Color(0xFF1E40AF),
                                      ),
                                      foregroundColor: WidgetStateProperty.all(
                                        Colors.white,
                                      ),
                                      overlayColor: WidgetStateProperty.all(
                                        Colors.transparent,
                                      ),
                                      minimumSize: WidgetStateProperty.all(
                                        Size(75, 35),
                                      ),
                                      elevation: WidgetStateProperty.all(0),
                                      shape: WidgetStateProperty.all(
                                        RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                    child: Text("Bắt đầu"),
                                  ),
                                ],
                              );
                            },
                          );
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
                        child: const Text('Thực hiện bài tập'),
                      ),
                    ),

                    SizedBox(height: 20),

                    Text(
                      'Tổng quan các lần làm bài trước',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    FutureBuilder(
                      future: _attemptsDataFuture, 
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return const Center(child: Text('Lỗi tải thông tin các lần làm bài'));
                        } else if (snapshot.hasData) {
                          final attempts = snapshot.data!['result'] as List;
                          if (attempts.isEmpty) {
                            return const Text('Chưa có lần làm bài nào');
                          }
                          return ListView.separated(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: attempts.length,
                            separatorBuilder: (context, index) => Divider(),
                            itemBuilder: (context, index) {
                              final attempt = attempts[index];
                              return ListTile(
                                title: Text('Lần làm bài ${attempt['attemptNo']}'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Trạng thái: ${
                                        attempt['status'] == 'COMPLETED' ? 'Đã nộp' : 
                                        attempt['status'] == 'IN_PROGRESS' ? 'Đang làm' : attempt['status']
                                      }',
                                    ),
                                    Text('Thời gian bắt đầu: ${DateTime.parse(attempt['startTime']).toLocal()}'),
                                    Text('Thời gian nộp bài: ${attempt['status'] == 'COMPLETED' ? DateTime.parse(attempt['endTime']).toLocal() : 'Chưa nộp'}'),
                                  ],
                                ),
                                onTap: () {
                                  context.go('/exercise/${widget.exerciseId}/attempt/${attempt['id']}');
                                },
                              );
                            },
                          );
                        } else {
                          return const Center(child: Text('Không có dữ liệu'));
                        }
                      },
                    ),
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