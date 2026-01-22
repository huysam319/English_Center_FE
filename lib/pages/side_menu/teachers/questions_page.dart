import 'package:english_center_fe/widgets/layout/layout.dart';
import 'package:flutter/material.dart';

class QuestionsPage extends StatelessWidget {
  const QuestionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Title(
      color: Colors.black,
      title: "Ngân hàng câu hỏi",
      child: SiteLayout(
        menuNo: 12,
        content: Container(
          color: Color(0xFFF1F3F4),
        ),
      ),
    );
  }
}