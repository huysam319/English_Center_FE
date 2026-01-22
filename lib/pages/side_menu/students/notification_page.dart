import 'package:english_center_fe/widgets/layout/layout.dart';
import 'package:flutter/material.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Title(
      color: Colors.black,
      title: "Thông báo",
      child: SiteLayout(
        menuNo: 2,
        content: Container(
          color: Color(0xFFF1F3F4),
        ),
      ),
    );
  }
}