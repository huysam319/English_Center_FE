import 'package:english_center_fe/widgets/layout/layout.dart';
import 'package:flutter/material.dart';

class FlashcardPage extends StatelessWidget {
  const FlashcardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Title(
      color: Colors.black,
      title: "Flashcards",
      child: SiteLayout(
        menuNo: 8,
        content: Container(
          color: Color(0xFFF1F3F4),
        ),
      ),
    );
  }
}