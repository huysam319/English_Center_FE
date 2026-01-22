import 'package:english_center_fe/widgets/layout/layout.dart';
import 'package:flutter/material.dart';

class ClassExercisePage extends StatelessWidget {
  const ClassExercisePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Title(
      color: Colors.black,
      title: "Bài tập trên lớp",
      child: SiteLayout(
        menuNo: 5,
        content: Container(
          color: Color(0xFFF1F3F4),
        ),
      ),
    );
  }
}