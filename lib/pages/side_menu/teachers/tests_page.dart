import 'package:english_center_fe/widgets/layout/layout.dart';
import 'package:flutter/material.dart';

class TestsPage extends StatelessWidget {
  const TestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Title(
      color: Colors.black,
      title: "Đề thi",
      child: SiteLayout(
        menuNo: 11,
        content: Container(
          color: Color(0xFFF1F3F4),
        ),
      ),
    );
  }
}