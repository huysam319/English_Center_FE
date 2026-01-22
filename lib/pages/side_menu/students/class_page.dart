import 'package:english_center_fe/widgets/layout/layout.dart';
import 'package:flutter/material.dart';

class ClassPage extends StatelessWidget {
  const ClassPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Title(
      color: Colors.black,
      title: "Lớp của tôi",
      child: SiteLayout(
        menuNo: 3,
        content: Container(
          color: Color(0xFFF1F3F4),
        ),
      ),
    );
  }
}