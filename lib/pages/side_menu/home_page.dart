
import 'package:english_center_fe/widgets/layout/layout.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Title(
      color: Colors.black,
      title: "Trang chủ",
      child: SiteLayout(
        menuNo: 1,
        content: Container(
          color: Color(0xFFF1F3F4),
        ),
      ),
    );
  }
}