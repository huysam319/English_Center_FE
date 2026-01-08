import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Title(
      color: Colors.black,
      title: "Trang chủ",
      child: Scaffold(
        backgroundColor: Colors.yellow.shade100,
      ),
    );
  }
}