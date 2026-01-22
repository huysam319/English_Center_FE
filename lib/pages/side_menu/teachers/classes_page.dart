import 'package:english_center_fe/widgets/layout/layout.dart';
import 'package:flutter/material.dart';

class ClassesPage extends StatelessWidget {
  const ClassesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Title(
      color: Colors.black,
      title: "Quản lý lớp",
      child: SiteLayout(
        menuNo: 13,
        content: Container(
          color: Color(0xFFF1F3F4),
        ),
      ),
    );
  }
}