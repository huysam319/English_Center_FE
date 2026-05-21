import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class WritingExerciseGrade {
  double? task;
  double? coherence;
  double? lexical;
  double? grammar;
  double? overall;
  List<WritingError> errors = [];
  QuillController commentController = QuillController.basic();

  WritingExerciseGrade();
}
class WritingError {
  String? type;
  TextEditingController descriptionController = TextEditingController();

  WritingError({this.type, String? description}) {
    descriptionController.text = description ?? '';
  }
}