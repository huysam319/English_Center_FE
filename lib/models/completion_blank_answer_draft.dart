import 'package:flutter/material.dart';

class CompletionBlankAnswerDraft {
  int questionNo;
  final TextEditingController correctAnswerController;

  CompletionBlankAnswerDraft({
    required this.questionNo,
    String initialCorrectAnswer = '',
  }) : correctAnswerController = TextEditingController(
         text: initialCorrectAnswer,
       );

  void dispose() {
    correctAnswerController.dispose();
  }
}