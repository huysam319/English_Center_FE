import 'package:flutter/material.dart';

class SmallScreen extends StatelessWidget {
  const SmallScreen({super.key, required this.content});
  final Widget content;

  @override
  Widget build(BuildContext context) {
    return content;
  }
}