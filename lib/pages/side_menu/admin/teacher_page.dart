import 'package:english_center_fe/widgets/layout/layout.dart';
import 'package:flutter/material.dart';

class TeacherPage extends StatelessWidget {
  const TeacherPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Title(
      color: Colors.black,
      title: "Quản lý giáo viên",
      child: SiteLayout(
        menuNo: 14,
        content: Container(
          color: Color(0xFFF1F3F4),
        ),
      ),
    );
  }
}