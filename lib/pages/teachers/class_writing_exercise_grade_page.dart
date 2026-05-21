import 'dart:convert';

import 'package:english_center_fe/models/writing_task_grade_model.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_quill/flutter_quill.dart';
import 'package:go_router/go_router.dart';

import '../../exceptions/unauthorized_exception.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/grading/writing_task_grading.dart';
import '../../widgets/layout/layout.dart';

class ClassWritingExerciseGradePage extends StatefulWidget {
  final String classId;
  final String exerciseId;

  const ClassWritingExerciseGradePage({super.key, required this.classId, required this.exerciseId});

  @override
  State<ClassWritingExerciseGradePage> createState() =>
      _ClassWritingExerciseGradePageState();
}

class _ClassWritingExerciseGradePageState extends State<ClassWritingExerciseGradePage> {
  late final Future<Map<String, dynamic>> _attemptsDataFuture;
  late final Future<Map<String, dynamic>> _studentDataFuture;

  List<WritingExerciseGrade> grades = [];
  int index = 0;

  Future<Map<String, dynamic>> _loadAttemptsData(String exerciseId) async {
    var response = await ApiService.get(
      '/identity/attempts/assessment/$exerciseId',
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
          '/identity/attempts/assessment/$exerciseId',
          token: authService.accessToken,
        );
      } else {
        await authService.clearAuth();
        throw UnauthorizedException();
      }
    }

    final data = jsonDecode(response.body);

    if (data['code'] == 1000 && (data['result'] as List).isNotEmpty) {
      _studentDataFuture = _loadStudentInfo(data['result'][0]['studentId']);
    }

    return data;
  }

  Future<Map<String, dynamic>> _loadStudentInfo(String studentId) async {
    var response = await ApiService.get(
      '/identity/users/$studentId',
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
          '/identity/users/$studentId',
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
    _attemptsDataFuture = _loadAttemptsData(widget.exerciseId);
    // _studentDataFuture = _loadStudentInfo(widget.studentId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _attemptsDataFuture, 
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Lỗi tải dữ liệu'));
        } else if (snapshot.hasData) {
          final result = snapshot.data!['result'];
          final attempt = result[index];
          final answers = attempt['answers'] as List;
          answers.sort((a, b) => (a['questionNumber'] as int).compareTo(b['questionNumber'] as int));

          return Title(
            color: Colors.black,
            title: "Chấm điểm ${attempt['assessmentTitle']}",
            child: SiteLayout(
              menuNo: 13,
              content: SelectionArea(
                child: Container(
                  color: Colors.white,
                  child: ListView(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Column(
                              children: [
                                Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.arrow_circle_left_outlined,
                                        size: 32,
                                      ),
                                      onPressed: () {
                                        context.go(
                                          '/classes/${widget.classId}/exercises/${widget.exerciseId}',
                                        );
                                      },
                                    ),
                                    Text(
                                      'Chấm điểm ${attempt['assessmentTitle']}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 16),

                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.grey.shade50,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      IconButton(
                                        onPressed: index > 0
                                            ? () {
                                                setState(() {
                                                  index--;
                                                  grades.clear();
                                                });
                                              }
                                            : null,
                                        icon: const Icon(Icons.arrow_back_ios),
                                      ),

                                      FutureBuilder(
                                        future: _studentDataFuture, 
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState == ConnectionState.waiting) {
                                            return CircularProgressIndicator();
                                          } else if (snapshot.hasError) {
                                            return Text('Lỗi tải thông tin học viên');
                                          } else if (snapshot.hasData) {
                                            final student = snapshot.data!['result'];
                                            return Column(
                                              children: [
                                                Text(
                                                  (student['lastName'] != null && student['firstName'] != null)
                                                    ? '${student['lastName']} ${student['firstName']}'
                                                    : 'Unknown Student',
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),

                                                const SizedBox(height: 4),

                                                Text(
                                                  'Lần làm bài ${result[index]['attemptNo']}',
                                                ),

                                                const SizedBox(height: 4),

                                                Text(
                                                  student['email'] ?? '',
                                                  style: TextStyle(
                                                    color: Colors.grey.shade700,
                                                    fontSize: 14,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),

                                                const SizedBox(height: 4),

                                                Text(
                                                  'Bài nộp ${index + 1} / ${result.length}',
                                                  style: TextStyle(
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              ],
                                            );
                                          } else {
                                            return Container();
                                          }
                                        }
                                      ),

                                      IconButton(
                                        onPressed: index < result.length - 1
                                            ? () {
                                                setState(() {
                                                  index++;
                                                  grades.clear();
                                                });
                                              }
                                            : null,
                                        icon: const Icon(Icons.arrow_forward_ios),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 16),
                              ],
                            ),

                            Column(
                              children: answers.map((attempt) {
                                grades.add(WritingExerciseGrade());
                                return WritingTaskGrading(
                                  key: ValueKey(
                                    '${result[index]['id']}-${attempt['questionNumber']}',
                                  ),
                                  assessmentId: widget.exerciseId,
                                  gradeModel: grades[attempt['questionNumber'] - 1],
                                  answerData: attempt,
                                );
                              }).toList(),
                            ),

                            ElevatedButton(
                              onPressed: () async {
                                for (var answer in answers) {
                                  var grade = grades[answer['questionNumber'] - 1];
                                  var response = await ApiService.post(
                                    '/identity/writing-grading',
                                    token: authService.accessToken,
                                    body: {
                                      "attemptId": attempt['id'],
                                      "questionNumber": answer['questionNumber'],
                                      "trScore": grade.task ?? "",
                                      "ccScore": grade.coherence ?? "",
                                      "lrScore": grade.lexical ?? "",
                                      "graScore": grade.grammar ?? "",
                                      "score": grade.overall ?? "",
                                      "errors": grade.errors.map((e) => {
                                        "studentErrorType": e.type,
                                        "description": e.descriptionController.text,
                                      }).toList(),
                                      "feedback": grade.commentController.document.toPlainText(),
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
                                        '/identity/writing-grading',
                                        token: authService.accessToken,
                                        body: {
                                          "attemptId": attempt['id'],
                                          "questionNumber": answer['questionNumber'],
                                          "trScore": grade.task ?? "",
                                          "ccScore": grade.coherence ?? "",
                                          "lrScore": grade.lexical ?? "",
                                          "graScore": grade.grammar ?? "",
                                          "score": grade.overall ?? "",
                                          "errors": grade.errors.map((e) => {
                                            "studentErrorType": e.type,
                                            "description": e.descriptionController.text,
                                          }).toList(),
                                          "feedback": grade.commentController.document.toPlainText(),
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
                                      SnackBar(content: Text('Chấm điểm task ${answer['questionNumber']} thành công')),
                                    );
                                  } else {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Chấm điểm task ${answer['questionNumber']} thất bại')),
                                    );
                                  }
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
                              child: const Text("Submit"),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        } else {
          return Container();
        }
      },
    );
  }
}