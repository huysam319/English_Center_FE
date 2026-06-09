import 'dart:convert';

import 'package:flutter/material.dart';

import '../../exceptions/unauthorized_exception.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/layout/layout.dart';
import '../../widgets/test/multiple_choice_quiz_widget.dart';

class LearningSupportQuizPage extends StatefulWidget {
  const LearningSupportQuizPage({super.key});

  @override
  State<LearningSupportQuizPage> createState() =>
      _LearningSupportQuizPageState();
}

class _LearningSupportQuizPageState extends State<LearningSupportQuizPage> {
  late final Future<Map<String, dynamic>> _quizDataFuture;
  final Map<int, int> selectedAnswers = {};
  List<String> correctedErrorTypes = [];

  bool submitted = false;
  int score = 0;

  @override
  void initState() {
    super.initState();
    _quizDataFuture = _loadQuizData();
  }

  Future<Map<String, dynamic>> _loadQuizData() async {
    var response = await ApiService.get(
      "/identity/learning-support/quiz",
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
          "/identity/learning-support/quiz",
          token: authService.accessToken,
        );
      } else {
        await authService.clearAuth();
        throw UnauthorizedException();
      }
    }

    return jsonDecode(response.body);
  }

  void _submitQuiz(List questions, Map<String, dynamic> responseData) {
    int totalCorrect = 0;

    for (var question in questions) {
      final int questionOrder = question['order'];

      final List choices = question['choices'];

      final selectedChoiceOrder =
          selectedAnswers[questionOrder];

      Map<String, dynamic>? selectedChoice;

      try {
        selectedChoice = choices.firstWhere(
          (choice) => choice['order'] == selectedChoiceOrder,
        );
      } catch (_) {
        selectedChoice = null;
      }

      if (selectedChoice != null && selectedChoice['isCorrect'] == true) {
        totalCorrect++;
      }
    }



    setState(() {
      submitted = true;
      score = totalCorrect;
      correctedErrorTypes = (responseData['result']['correctedErrors'] as List)
          .map((e) => e['description'] as String)
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Title(
      color: Colors.black,
      title: "Quiz ôn tập lỗi sai",
      child: SiteLayout(
        menuNo: 9,
        content: Container(
          color: Colors.white,
          child: SelectionArea(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _quizDataFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text("Không thể tải bài quiz"),
                  );
                }

                if (!snapshot.hasData) {
                  return Center(
                    child: Text("Không có dữ liệu"),
                  );
                }

                final data = snapshot.data!['result'];
                final List skills = data['errorsToReview'];
                final List questions = data['questions'];

                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      'Quiz ôn tập lỗi sai',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E40AF),
                      ),
                    ),

                    SizedBox(height: 10),

                    Text(
                      'Hãy bắt đầu ôn tập để khắc phục các lỗi sai trong quá trình học tập của bạn.',
                      style: TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                      ),
                    ),

                    SizedBox(height: 20),

                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: skills.map((skill) {
                        return Chip(
                          label: Text(skill['description']),
                          backgroundColor:
                            skill['errorType'].toString().startsWith('GRAMMAR') ? Colors.red.shade50
                              : skill['errorType'].toString().startsWith('VOCAB') ? Colors.green.shade50
                              : skill['errorType'].toString().startsWith('COHERENCE') ? Colors.orange.shade50
                              : skill['errorType'].toString().startsWith('TASK') ? Colors.purple.shade50
                              : Colors.blue.shade50,
                        );
                      }).toList(),
                    ),

                    SizedBox(height: 30),

                    ...questions.map((question) => MultipleChoiceQuizWidget(
                          question: question,
                          selectedAnswers: selectedAnswers,
                          submitted: submitted,
                        )).toList(),

                    SizedBox(height: 20),

                    if (!submitted)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                              var response = await ApiService.post(
                                "/identity/learning-support/quiz",
                                token: authService.accessToken,
                                body: {
                                "studentReviewErrors": skills
                                    .map((skill) => skill['errorType'])
                                    .toList(),
                                "quizQuestions": questions
                                    .map((question) { 
                                      final int questionOrder = question['order'];
                                      final List choices = question['choices'];
                                      final selectedChoiceOrder =
                                          selectedAnswers[questionOrder];

                                      Map<String, dynamic>? selectedChoice;

                                      try {
                                        selectedChoice = choices.firstWhere(
                                          (choice) => choice['order'] == selectedChoiceOrder,
                                        );
                                      } catch (_) {
                                        selectedChoice = null;
                                      }

                                      return {
                                        "order": question['order'],
                                        "errorTypes": question['errorTypes'],
                                        "content": question['content'],
                                        "correctAnswer": question['answer'],
                                        "isCorrect": (selectedChoice != null && selectedChoice['isCorrect'] == true) 
                                            ? true 
                                            : false,
                                      };
                                    })
                                    .toList(),
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
                                  "/identity/learning-support/quiz",
                                  token: authService.accessToken,
                                  body: {
                                    "studentReviewErrors": skills
                                        .map((skill) => skill['errorType'])
                                        .toList(),
                                    "quizQuestions": questions
                                        .map((question) { 
                                          final int questionOrder = question['order'];
                                          final List choices = question['choices'];
                                          final selectedChoiceOrder =
                                              selectedAnswers[questionOrder];

                                          Map<String, dynamic>? selectedChoice;

                                          try {
                                            selectedChoice = choices.firstWhere(
                                              (choice) => choice['order'] == selectedChoiceOrder,
                                            );
                                          } catch (_) {
                                            selectedChoice = null;
                                          }

                                          return {
                                            "order": question['order'],
                                            "errorTypes": question['errorTypes'],
                                            "content": question['content'],
                                            "correctAnswer": question['answer'],
                                            "isCorrect": (selectedChoice != null && selectedChoice['isCorrect'] == true) 
                                                ? true 
                                                : false,
                                          };
                                        })
                                        .toList(),
                                  },
                                );
                              } else {
                                await authService.clearAuth();
                                throw UnauthorizedException();
                              }
                            }

                            final responseData = jsonDecode(response.body);
                            if (responseData['code'] != 1000) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Không thể lưu kết quả quiz"),
                                ),
                              );
                            }

                            _submitQuiz(questions, responseData);
                          },
                          style: ElevatedButton.styleFrom(
                            padding:
                                EdgeInsets.symmetric(
                              vertical: 16,
                            ),
                            backgroundColor:
                                Color(0xFF1E40AF),
                            foregroundColor:
                                Colors.white,
                            minimumSize: Size(150, 45),
                          ),
                          child: Text(
                            'Nộp bài',
                            style: TextStyle(
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (submitted)
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius:
                              BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                Colors.green.shade200,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Kết quả',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            SizedBox(height: 5),

                            Text(
                              '$score / ${questions.length}',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight:
                                    FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),

                            SizedBox(height: 5),

                            Text(
                              'Bạn đã hoàn thành bài quiz ôn tập.',
                              style: TextStyle(
                                fontSize: 16,
                              ),
                            ),

                            SizedBox(height: 10),

                            Text(
                              'Các lỗi sai đã được cải thiện: ${correctedErrorTypes.isEmpty ? "Không có" : ""}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                            ...correctedErrorTypes.map((error) => Text(error)),
                          ],
                        ),
                      ),

                    SizedBox(height: 30),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}