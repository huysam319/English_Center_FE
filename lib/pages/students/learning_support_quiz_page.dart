import 'package:flutter/material.dart';

import '../../widgets/layout/layout.dart';

class LearningSupportQuizPage extends StatefulWidget {
  const LearningSupportQuizPage({super.key});

  @override
  State<LearningSupportQuizPage> createState() =>
      _LearningSupportQuizPageState();
}

class _LearningSupportQuizPageState
    extends State<LearningSupportQuizPage> {
  late final Future<Map<String, dynamic>> _quizDataFuture;

  /// questionOrder -> selectedChoiceOrder
  final Map<int, int> selectedAnswers = {};

  bool submitted = false;
  int score = 0;

  @override
  void initState() {
    super.initState();
    _quizDataFuture = _loadQuizData();
  }

  Future<Map<String, dynamic>> _loadQuizData() async {
    await Future.delayed(Duration(seconds: 2));

    return {
      'skillsToImprove': [
        'GRAMMAR_SUBJECT_VERB_AGREEMENT',
        'VOCAB_REPETITION'
      ],
      'questions': [
        {
          "order": 1,
          "content": "Choose the correct sentence:",
          "answer": "She goes to school every morning.",
          "choices": [
            {
              "order": 1,
              "content": "She go to school every morning.",
              "isCorrect": false
            },
            {
              "order": 2,
              "content": "She goes to school every morning.",
              "isCorrect": true
            },
            {
              "order": 3,
              "content": "She going to school every morning.",
              "isCorrect": false
            },
            {
              "order": 4,
              "content": "She gone to school every morning.",
              "isCorrect": false
            }
          ]
        },
        {
          "order": 2,
          "content": "Choose the sentence with the correct subject-verb agreement:",
          "answer": "The students study hard for the exam.",
          "choices": [
            {
              "order": 1,
              "content": "The students studies hard for the exam.",
              "isCorrect": false
            },
            {
              "order": 2,
              "content": "The students study hard for the exam.",
              "isCorrect": true
            },
            {
              "order": 3,
              "content": "The students studying hard for the exam.",
              "isCorrect": false
            },
            {
              "order": 4,
              "content": "The students has studied hard for the exam.",
              "isCorrect": false
            }
          ]
        },
        {
          "order": 3,
          "content": "Which sentence avoids unnecessary word repetition?",
          "answer": "Technology is important because it improves communication and education.",
          "choices": [
            {
              "order": 1,
              "content": "Technology is important because technology improves technology and technology education.",
              "isCorrect": false
            },
            {
              "order": 2,
              "content": "Technology is important because it improves communication and education.",
              "isCorrect": true
            },
            {
              "order": 3,
              "content": "Technology technology technology improves communication.",
              "isCorrect": false
            },
            {
              "order": 4,
              "content": "Technology is important and important and important.",
              "isCorrect": false
            }
          ]
        },
        {
          "order": 4,
          "content": "Choose the sentence with better vocabulary variety:",
          "answer": "Many people enjoy traveling because it helps them relax and explore new cultures.",
          "choices": [
            {
              "order": 1,
              "content": "Many people like traveling because traveling is fun and traveling is relaxing.",
              "isCorrect": false
            },
            {
              "order": 2,
              "content": "Many people enjoy traveling because it helps them relax and explore new cultures.",
              "isCorrect": true
            },
            {
              "order": 3,
              "content": "Traveling traveling traveling is good for people.",
              "isCorrect": false
            },
            {
              "order": 4,
              "content": "People travel because travel is travel.",
              "isCorrect": false
            }
          ]
        },
        {
          "order": 5,
          "content": "Choose the sentence with the correct article usage:",
          "answer": "I bought a new laptop yesterday.",
          "choices": [
            {
              "order": 1,
              "content": "I bought new laptop yesterday.",
              "isCorrect": false
            },
            {
              "order": 2,
              "content": "I bought a new laptop yesterday.",
              "isCorrect": true
            },
            {
              "order": 3,
              "content": "I bought an new laptop yesterday.",
              "isCorrect": false
            },
            {
              "order": 4,
              "content": "I bought the new laptop yesterday.",
              "isCorrect": false
            }
          ]
        },
        {
          "order": 6,
          "content": "Choose the correct sentence:",
          "answer": "She wants to become an engineer in the future.",
          "choices": [
            {
              "order": 1,
              "content": "She wants to become engineer in the future.",
              "isCorrect": false
            },
            {
              "order": 2,
              "content": "She wants to become an engineer in the future.",
              "isCorrect": true
            },
            {
              "order": 3,
              "content": "She wants to become a engineer in the future.",
              "isCorrect": false
            },
            {
              "order": 4,
              "content": "She wants to become the engineer in future.",
              "isCorrect": false
            }
          ]
        }
      ]
    };
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
          (choice) =>
              choice['order'] ==
              selectedChoiceOrder,
        );
      } catch (_) {
        selectedChoice = null;
      }

      if (selectedChoice != null &&
          selectedChoice['isCorrect'] == true) {
        totalCorrect++;
      }
    }

    setState(() {
      submitted = true;
      score = totalCorrect;
    });
  }

  Color _getChoiceColor(
    Map<String, dynamic> choice,
    int questionOrder,
  ) {
    if (!submitted) {
      return Colors.white;
    }

    final selectedChoice =
        selectedAnswers[questionOrder];

    final bool isSelected =
        selectedChoice == choice['order'];

    final bool isCorrect = choice['isCorrect'];

    if (isCorrect) {
      return Colors.green.shade100;
    }

    if (isSelected && !isCorrect) {
      return Colors.red.shade100;
    }

    return Colors.white;
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

              final data = snapshot.data!;

              final List skills =
                  data['skillsToImprove'];

              final List questions =
                  data['questions'];

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
                        label: Text(skill),
                        backgroundColor:
                            Colors.blue.shade50,
                      );
                    }).toList(),
                  ),

                  SizedBox(height: 30),

                  ...questions.map((question) {
                    final int questionOrder =
                        question['order'];

                    final List choices =
                        question['choices'];

                    return Container(
                      margin:
                          EdgeInsets.only(bottom: 24),
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey.shade300,
                        ),
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Question ${question['order']}',
                            style: TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),

                          SizedBox(height: 10),

                          Text(
                            question['content'],
                            style: TextStyle(
                              fontSize: 16,
                            ),
                          ),

                          SizedBox(height: 16),

                          ...choices.map((choice) {
                            return Container(
                              margin:
                                  EdgeInsets.only(
                                      bottom: 10),
                              decoration: BoxDecoration(
                                color: _getChoiceColor(
                                  choice,
                                  questionOrder,
                                ),
                                borderRadius:
                                    BorderRadius
                                        .circular(10),
                                border: Border.all(
                                  color: Colors
                                      .grey.shade300,
                                ),
                              ),
                              child: RadioListTile<int>(
                                value: choice['order'],
                                groupValue:
                                    selectedAnswers[
                                        questionOrder],
                                onChanged: submitted
                                    ? null
                                    : (value) {
                                        setState(() {
                                          selectedAnswers[
                                                  questionOrder] =
                                              value!;
                                        });
                                      },
                                title: Text(
                                  choice['content'],
                                ),
                              ),
                            );
                          }).toList(),

                          if (submitted)
                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                SizedBox(height: 10),

                                Text(
                                  'Correct answer:',
                                  style: TextStyle(
                                    fontWeight:
                                        FontWeight.bold,
                                    color:
                                        Colors.green,
                                  ),
                                ),

                                SizedBox(height: 5),

                                Text(
                                  question['answer'],
                                ),
                              ],
                            ),
                        ],
                      ),
                    );
                  }).toList(),

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
    );
  }
}