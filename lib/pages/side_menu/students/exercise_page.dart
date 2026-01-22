import 'package:english_center_fe/widgets/layout/layout.dart';
import 'package:flutter/material.dart';

class ExercisePage extends StatelessWidget {
  const ExercisePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Title(
      color: Colors.black,
      title: "Bài tập tự chọn",
      child: SiteLayout(
        menuNo: 4,
        content: Container(
          color: Color(0xFFF1F3F4),
        ),
      ),
    );
  }
}