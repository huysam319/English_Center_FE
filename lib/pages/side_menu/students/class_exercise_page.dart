import 'package:english_center_fe/pages/students/ai_reading_student_page.dart';
import 'package:flutter/material.dart';

class ClassExercisePage extends StatelessWidget {
  const ClassExercisePage({super.key});

  @override
  Widget build(BuildContext context) {
    // "Bài tập của bạn" hiển thị các đề Reading AI mà giáo viên đã giao cho lớp.
    return const AiReadingStudentPage(menuOrder: 5);
  }
}
