import 'package:english_center_fe/widgets/layout/layout.dart';
import 'package:flutter/material.dart';

class ClassPage extends StatefulWidget {
  const ClassPage({super.key});

  @override
  State<ClassPage> createState() => _ClassPageState();
}

class _ClassPageState extends State<ClassPage> {
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