import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html/flutter_html.dart' as html;
import 'package:flutter_quill/flutter_quill.dart';
import 'package:go_router/go_router.dart';

import '../../exceptions/unauthorized_exception.dart';
import '../../models/writing_answer_model.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/layout/layout.dart';
import '../../widgets/test/countdown_timer.dart';
import '../../widgets/test/section_navbar.dart';

class StudentExerciseSubmissionPage extends StatefulWidget {
  final String exerciseId;
  final String attemptId;

  const StudentExerciseSubmissionPage({super.key, required this.exerciseId, required this.attemptId});

  @override
  State<StudentExerciseSubmissionPage> createState() => _StudentExerciseSubmissionPageState();
}

class _StudentExerciseSubmissionPageState extends State<StudentExerciseSubmissionPage> {
  Future<Map<String, dynamic>>? _dataFuture;
  Future<Map<String, dynamic>>? _partFuture;
  bool isInitialized = false;
  late final String attemptId;
  final GlobalKey<CountdownTimerState> _timerKey = GlobalKey<CountdownTimerState>();

  int activeSection = 1;
  List<dynamic> answerModels = [];

  Future<Map<String, dynamic>> _loadAttemptInfo(String attemptId) async {
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

    final responseData = jsonDecode(response.body);
    // answerModels = List.generate(
    //   responseData['result']['totalQuestions'],
    //   (index) => WritingAnswerModel(partNumber: index + 1),
    // );
    // for (var model in answerModels) {
    //   if (model is WritingAnswerModel) {
    //     _addWordCountListener(model);
    //   }
    // }
    for (int i = 1; i <= responseData['result']['totalQuestions']; i++) {
      answerModels.add(WritingAnswerModel(partNumber: i));
      _addWordCountListener(answerModels.last);
      var partResponse = await _loadPartInfo(widget.exerciseId, i);
      if (i == activeSection) {
        setState(() {
          _partFuture = Future.value(partResponse);
        });
      }
    }

    setState(() {
      isInitialized = true;
    });

    return responseData;
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
    };

    final responseData = jsonDecode(response.body);

    if (responseData != null && responseData['code'] == 1000) {
      final result = responseData['result'];
      if (result != null) {
        final currentModel = answerModels.firstWhere((model) => model.partNumber == partNumber);
        if (currentModel is WritingAnswerModel) {
          currentModel.groupId = result['questionGroups'][0]['id'] ?? '';
        }
      }
    }

    return responseData;
    // setState(() {
    //   isTimer = response['skill'] == 'Reading' || response['skill'] == 'Writing';
    // });
      
    // if (response['skill'] == 'Writing') {
    //   final parts = response['parts'] as List;
    //   answerModels = List.generate(
    //     parts.length,
    //     (index) => WritingAnswerModel(partNumber: parts[index]['partNumber']),
    //   );
    //   for (var model in answerModels) {
    //     if (model is WritingAnswerModel) {
    //       _addWordCountListener(model);
    //     }
    //   }
    // }
    // return response;
  }

  void _addWordCountListener(WritingAnswerModel model) {
    model.answerController.addListener(() {
      final text = model.answerController.document.toPlainText();
      final count = countWords(text);
      model.wordCountNotifier.value = count;
    });
  }

  int countWords(String text) {
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadAttemptInfo(widget.attemptId);
  }

  @override
  Widget build(BuildContext context) {
    return Title(
      color: Colors.black,
      title: "Bài tập trên lớp",
      child: SiteLayout(
        menuNo: 5,
        content: SelectionArea( 
          child: Container(
            color: Colors.white,
            child: Column(
              children: [
                SizedBox(height: 5),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.access_time_outlined),
                          SizedBox(width: 5),
                          CountdownTimer(key: _timerKey, seconds: 3600,),
                        ],
                      ),
                    ),

                    FutureBuilder<Map<String, dynamic>>(
                      future: _dataFuture,
                      builder:(context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting || !isInitialized) {
                          return Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          final err = snapshot.error;
                          if (err is UnauthorizedException) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) context.go('/login');
                            });
                            return SizedBox.shrink();
                          }
                          return Center(
                            child: Text('Lỗi tải thông tin đề thi'),
                          );
                        } else if (snapshot.hasData) {
                          return TextButton(
                            onPressed: () {
                              showDialog<bool>(
                                context: context,
                                barrierDismissible: true,
                                builder: (context) {
                                  return AlertDialog(
                                    title: Text("Xác nhận nộp bài"),
                                    content: Text("Bạn có chắc chắn muốn nộp bài không? Sau khi nộp, bạn sẽ không thể chỉnh sửa câu trả lời của mình."),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: Text("Hủy"),
                                      ),
                                      ElevatedButton(
                                        onPressed: () async {
                                          Navigator.pop(context, true);

                                          final router = GoRouter.of(context);

                                          var response = await ApiService.post(
                                            '/identity/attempts/submit',
                                            token: authService.accessToken,
                                            body: {
                                              'attemptId': widget.attemptId,
                                              'answers': answerModels.map((model) => {
                                                'groupId': model.groupId,
                                                'questionOrder': model.partNumber,
                                                'textAnswer': model.answerController.document.toPlainText().trim(),
                                              }).toList(),
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
                                                '/identity/attempts/submit',
                                                token: authService.accessToken,
                                                body: {
                                                  'attemptId': widget.attemptId,
                                                  'answers': answerModels.map((model) => {
                                                    'groupId': model.groupId,
                                                    'questionOrder': model.partNumber,
                                                    'textAnswer': model.answerController.document.toPlainText().trim(),
                                                  }).toList(),
                                                },
                                              );
                                            } else {
                                              await authService.clearAuth();
                                              throw UnauthorizedException();
                                            }
                                          }

                                          final data = jsonDecode(response.body);

                                          if (data != null && data['code'] == 1000) {
                                            router.go('/exercise/${widget.exerciseId}');
                                          } else {
                                            if (!context.mounted) return;
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Hiện tại chưa thể làm bài được.')),
                                            );
                                          }
                                        },
                                        child: Text("Nộp bài"),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            style: ButtonStyle(
                              animationDuration: const Duration(milliseconds: 180),
                              backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
                                if (states.contains(WidgetState.disabled)) return Colors.grey.shade300;
                                return const Color(0xFF1E40AF);
                              }),
                              foregroundColor: WidgetStateProperty.all<Color>(Colors.white),
                              overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
                                if (states.contains(WidgetState.pressed)) return const Color(0xFF1E40AF).withOpacity(0.12);
                                if (states.contains(WidgetState.hovered)) return const Color(0xFF1E40AF).withOpacity(0.08);
                                return null;
                              }),
                              elevation: WidgetStateProperty.resolveWith<double>((states) {
                                if (states.contains(WidgetState.pressed)) return 2;
                                if (states.contains(WidgetState.hovered)) return 6;
                                return 0;
                              }),
                              shadowColor: WidgetStateProperty.resolveWith<Color?>((states) {
                                if (states.contains(WidgetState.hovered) || states.contains(WidgetState.pressed)) return const Color(0xFF1E40AF).withOpacity(0.22);
                                return Colors.transparent;
                              }),
                              minimumSize: WidgetStateProperty.all(const Size(110, 44)),
                              shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                              mouseCursor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.disabled) ? SystemMouseCursors.forbidden : SystemMouseCursors.click),
                            ),
                            child: Text('Nộp bài', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w200)),
                          );
                        }
                        else {
                          return Container();
                        }
                      },
                    ),
                    
                    SizedBox(width: 20),
                  ],
                ),
                    
                Expanded(
                  child: FutureBuilder<Map<String, dynamic>>(
                    future: _partFuture,
                    builder:(context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        final err = snapshot.error;
                        if (err is UnauthorizedException) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) context.go('/login');
                          });
                          return SizedBox.shrink();
                        }
                        return Center(
                          child: Text('Lỗi tải thông tin bài tập'),
                        );
                      } else if (snapshot.hasData) {
                        final result = snapshot.data!['result'];
                        return Column(
                          children: [
                            Expanded(
                              child: ListView(
                                padding: EdgeInsets.all(16),
                                children: [
                                  Html(
                                    data: result['text'] ?? 'No text available',
                                    style: {
                                      "body": html.Style(fontSize: FontSize(16.0)),
                                    },
                                  ),
                                  if (result['imageUrl'] != null) Align(
                                    alignment: Alignment.center,
                                    child: Image.network(result['imageUrl']),
                                  ),
                                  SizedBox(height: 10,),

                                  Padding(
                                    padding: EdgeInsetsGeometry.symmetric(horizontal: 8),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border.all(
                                          color: Colors.black,
                                          width: 1,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: QuillEditor(
                                        controller: answerModels.firstWhere((model) => model.partNumber == activeSection).answerController,
                                        scrollController: ScrollController(),
                                        focusNode: FocusNode(),
                                        config: QuillEditorConfig(
                                          padding: EdgeInsets.all(10),
                                          autoFocus: false,
                                          expands: false,
                                          placeholder: 'Add your answer here...',
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 5,),
                                  Padding(
                                    padding: EdgeInsetsGeometry.symmetric(horizontal: 8),
                                    child:ValueListenableBuilder<int>(
                                      valueListenable: answerModels.firstWhere((model) => model.partNumber == activeSection)
                                          .wordCountNotifier,
                                      builder: (context, value, child) {
                                        return Align(
                                          alignment: Alignment.centerRight,
                                          child: Text('Word count: $value',),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            FutureBuilder(
                              future: _dataFuture, 
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return SizedBox.shrink();
                                } else if (snapshot.hasError) {
                                  return SizedBox.shrink();
                                } else if (snapshot.hasData) {
                                  final result = snapshot.data!['result'];
                                  final totalQuestions = result['totalQuestions'];

                                  return Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 20),
                                    child: Row(
                                      children: [
                                        for (int i = 1; i <= totalQuestions; i++)
                                          Expanded(
                                            child: SectionNavbar(
                                              isActive: activeSection == i,
                                              label: "Task", 
                                              number: i,
                                              onChanged: () {
                                                setState(() {
                                                  activeSection = i;
                                                  _partFuture = _loadPartInfo(widget.exerciseId, activeSection);
                                                });
                                              },
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                }
                                else {
                                  return Container();
                                }
                              },
                            ),
                          ],
                        );
                      } else {
                        return Center(child: Text('No data available'));
                      }
                    }
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}