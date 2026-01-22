import 'package:english_center_fe/widgets/layout/layout.dart';
import 'package:flutter/material.dart';

class StudentPage extends StatelessWidget {
  const StudentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Title(
      color: Colors.black,
      title: "Quản lý học viên",
      child: SiteLayout(
        menuNo: 15,
        content: Container(
          color: Color(0xFFF1F3F4),
        ),
      ),
    );
  }
}