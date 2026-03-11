import 'package:english_center_fe/models/dropped_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import 'question_type_model.dart';

class PartModel {
  final int id;
  final TextEditingController classController;
  final QuillController textController = QuillController.basic();
  final VoidCallback refresh;
  final List<QuestionTypeModel> questionTypes = [];
  bool classError;
  DroppedFile? audioFile;

  PartModel({required this.id, required this.classController, required this.refresh, this.classError = false});

  void onClassChanged() {
    if (classError && classController.text.trim().isNotEmpty) {
      classError = false;
      refresh();
    }
  }
}