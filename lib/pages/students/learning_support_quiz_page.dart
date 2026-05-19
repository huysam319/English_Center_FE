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

  bool submitted = false;
  int score = 0;

  @override
  void initState() {
    super.initState();
    _quizDataFuture = _loadQuizData();
  }

  Future<Map<String, dynamic>> _loadQuizData() async {
    var response = await ApiService.get(
      "/identity/learning-support",
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
          "/identity/learning-support",
          token: authService.accessToken,
        );
      } else {
        await authService.clearAuth();
        throw UnauthorizedException();
      }
    }

    return jsonDecode(response.body);
  }

  void _submitQuiz(List questions) {
    int totalCorrect = 0;

    for (var question in questions) {
      final int questionOrder = question['order'];

      final List choices = question['choices'];

      final selectedChoiceOrder =
          selectedAnswers[questionOrder];

      Map<String, dynamic>? selectedChoice;

      try {
        selectedChoice = choices.firstWhere(
          (choice) =>choice['order'] == selectedChoiceOrder,
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Title(
      color: Colors.black,
      title: "Hỗ trợ học tập",
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
                      'Bài quiz ôn tập lỗi sai',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
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
                      ElevatedButton(
                        onPressed: () {
                          _submitQuiz(questions);
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
                        ),
                        child: Text(
                          'Nộp bài',
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
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

                            SizedBox(height: 10),

                            Text(
                              '$score / ${questions.length}',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight:
                                    FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),

                            SizedBox(height: 10),

                            Text(
                              'Bạn đã hoàn thành bài quiz ôn tập.',
                              style: TextStyle(
                                fontSize: 16,
                              ),
                            ),
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