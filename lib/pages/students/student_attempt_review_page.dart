import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html/flutter_html.dart' as html;
import 'package:go_router/go_router.dart';

import '../../exceptions/unauthorized_exception.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/layout/layout.dart';

class StudentAttemptReviewPage extends StatefulWidget {
  final String attemptId;
  final String exerciseId;

  const StudentAttemptReviewPage({super.key, required this.attemptId, required this.exerciseId});

  @override
  State<StudentAttemptReviewPage> createState() => _StudentAttemptReviewPageState();
}

class _StudentAttemptReviewPageState extends State<StudentAttemptReviewPage> {
  late final Future<Map<String, dynamic>> _attemptDataFuture;

  Future<Map<String, dynamic>> _loadAttemptData(String attemptId) async {
    var response = await ApiService.get(
      '/identity/attempts/$attemptId',
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
          '/identity/attempts/$attemptId',
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
      '/identity/writing-assessments/student/$exerciseId?partNumber=$partNumber',
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
          '/identity/writing-assessments/student/$exerciseId?partNumber=$partNumber',
          token: authService.accessToken,
        );
      } else {
        await authService.clearAuth();
        throw UnauthorizedException();
      }
    }

    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> _loadEvaluationInfo(String evaluationId) async {
    var response = await ApiService.get(
      '/identity/writing-grading/$evaluationId',
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
          '/identity/writing-assessments/$evaluationId',
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
    _attemptDataFuture = _loadAttemptData(widget.attemptId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _attemptDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final attempt = snapshot.data!['result'];

        return Title(
          color: Colors.black,
          title: 'Xem lại bài làm ${attempt['assessmentTitle']} - Lần nộp thứ ${attempt['attemptNo']}',
          child: SiteLayout(
            menuNo: 5,
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
                          onPressed: () {
                            context.go(
                              '/exercise/${widget.exerciseId}',
                            );
                          },
                        ),
                        Text(
                          'Xem lại bài làm ${attempt['assessmentTitle']} - Lần nộp thứ ${attempt['attemptNo']}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    Column(
                      children: (attempt['answers'] as List).map((answer) {
                        return FutureBuilder<Map<String, dynamic>>(
                          future: _loadPartInfo(widget.exerciseId, answer['questionNumber']),
                          builder: (context, partSnapshot) {
                            if (partSnapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            if (partSnapshot.hasError) {
                              return Center(child: Text('Error loading part info: ${partSnapshot.error}'));
                            }

                            final result = partSnapshot.data!['result'];
                            return Container(
                              margin: EdgeInsets.symmetric(vertical: 8),
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Align(
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Task ${result['partNumber']}',
                                      style: TextStyle(
                                        fontSize: 20, 
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E40AF),
                                      ),
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
                                  const SizedBox(height: 12),

                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Bài làm học viên',
                                      style: TextStyle(
                                        fontSize: 16, 
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),

                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey.shade400, 
                                        width: 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      color: Colors.grey[50],
                                    ),
                                    padding: const EdgeInsets.all(4),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        answer['textAnswer'] ?? 'No answer provided',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  const Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      "Chấm điểm",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),

                                  if (answer['evaluationId'] == null) Text(
                                    'Bài làm chưa được chấm điểm',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.redAccent,
                                    ),
                                  )
                                  else FutureBuilder(
                                    future: _loadEvaluationInfo(answer['evaluationId']),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return CircularProgressIndicator();
                                      }
                                      if (!snapshot.hasData) {
                                        return Text('Error loading evaluation data');
                                      }
                                      final evaluation = snapshot.data!['result'];
                                      return Column(
                                        children: [
                                          Row(
                                            children: [
                                              SizedBox(width: 50),
                                              SizedBox(
                                                width: 300,
                                                child: Text(
                                                  'Task Achievement / Response', 
                                                  style: TextStyle(fontSize: 16),
                                                ),
                                              ),
                                              Text(
                                                evaluation['trScore'].toString(),
                                                style: TextStyle(
                                                  fontSize: 16, 
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 5),
                                          Row(
                                            children: [
                                              SizedBox(width: 50),
                                              SizedBox(
                                                width: 300,
                                                child: Text(
                                                  'Coherence and Cohesion', 
                                                  style: TextStyle(fontSize: 16),
                                                ),
                                              ),
                                              Text(
                                                evaluation['ccScore'].toString(),
                                                style: TextStyle(
                                                  fontSize: 16, 
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 5),
                                          Row(
                                            children: [
                                              SizedBox(width: 50),
                                              SizedBox(
                                                width: 300,
                                                child: Text(
                                                  'Lexical Resource', 
                                                  style: TextStyle(fontSize: 16),
                                                ),
                                              ),
                                              Text(
                                                evaluation['lrScore'].toString(),
                                                style: TextStyle(
                                                  fontSize: 16, 
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 5),
                                          Row(
                                            children: [
                                              SizedBox(width: 50),
                                              SizedBox(
                                                width: 300,
                                                child: Text(
                                                  'Grammatical Range and Accuracy', 
                                                  style: TextStyle(fontSize: 16),
                                                ),
                                              ),
                                              Text(
                                                evaluation['graScore'].toString(),
                                                style: TextStyle(
                                                  fontSize: 16, 
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          
                                          SizedBox(height: 10),

                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Text(
                                                "Overall score",
                                                style: TextStyle(fontSize: 18),
                                              ),
                                              const SizedBox(width: 10),
                                              Text(
                                                evaluation['score'].toString(),
                                                style: TextStyle(
                                                  fontSize: 16, 
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),

                                          const SizedBox(height: 20),

                                          const Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              "Nhận xét tổng thể",
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),

                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Text(
                                                evaluation['feedback'].toString(),
                                                style: TextStyle(fontSize: 16),
                                              ),
                                            ],
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      }).toList(),
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