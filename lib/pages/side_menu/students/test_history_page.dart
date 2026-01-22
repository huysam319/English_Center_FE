import 'package:english_center_fe/widgets/layout/layout.dart';
import 'package:flutter/material.dart';

class TestHistoryPage extends StatelessWidget {
  const TestHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Title(
      color: Colors.black,
      title: "Lịch sử làm bài",
      child: SiteLayout(
        menuNo: 7,
        content: Container(
          color: Color(0xFFF1F3F4),
        ),
      ),
    );
  }
}