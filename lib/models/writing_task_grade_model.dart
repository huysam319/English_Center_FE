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
  String description;

  WritingError({this.type, this.description = ''});
}