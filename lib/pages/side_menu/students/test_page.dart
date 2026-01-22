import 'package:english_center_fe/widgets/layout/layout.dart';
import 'package:flutter/material.dart';

class TestPage extends StatelessWidget {
  const TestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Title(
      color: Colors.black,
      title: "Danh sách đề thi",
      child: SiteLayout(
        menuNo: 6,
        content: Container(
          color: Color(0xFFF1F3F4),
        ),
      ),
    );
  }
}