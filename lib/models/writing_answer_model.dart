import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class WritingAnswerModel {
  final int partNumber;
  final ValueNotifier<int> wordCountNotifier = ValueNotifier<int>(0);
  final QuillController answerController = QuillController.basic();

  WritingAnswerModel({required this.partNumber});
}