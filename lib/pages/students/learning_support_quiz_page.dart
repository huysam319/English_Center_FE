import 'package:flutter/material.dart';

import '../../widgets/layout/layout.dart';

class LearningSupportQuizPage extends StatefulWidget {
  const LearningSupportQuizPage({super.key});

  @override
  State<LearningSupportQuizPage> createState() => _LearningSupportQuizPageState();
}

class _LearningSupportQuizPageState extends State<LearningSupportQuizPage> {
  late final Future<Map<String, dynamic>> _quizDataFuture;

  @override
  void initState() {
    super.initState();
    // _quizDataFuture = _fetchQuizData();
  }

  Future<Map<String, dynamic>> _fetchQuizData() async {
    // Simulate fetching quiz data from an API
    await Future.delayed(Duration(seconds: 2));
    return {
      'questions': [
        {
          'question': 'What is the capital of France?',
          'options': ['Paris', 'London', 'Berlin', 'Madrid'],
          'answer': 'Paris',
        },
        {
          'question': 'What is 2 + 2?',
          'options': ['3', '4', '5', '6'],
          'answer': '4',
        },
      ],
    };
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
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Bài quiz ôn tập lỗi sai',
                style: TextStyle(
                  fontSize: 20, 
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

              
            ],
          ),
        ),
      ),
    );
  }
}