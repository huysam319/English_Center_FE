import 'package:english_center_fe/widgets/layout/layout.dart';
import 'package:flutter/material.dart';

class ExercisesPage extends StatelessWidget {
  const ExercisesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Title(
      color: Colors.black,
      title: "Bài tập",
      child: SiteLayout(
        menuNo: 10,
        content: Container(
          color: Color(0xFFF1F3F4),
        ),
      ),
    );
  }
}