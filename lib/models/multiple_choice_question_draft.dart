class MultipleChoiceQuestionDraft {
  String question;
  List<String> options;
  Set<int> correctOptionIndices;

  MultipleChoiceQuestionDraft({
    this.question = '',
    List<String>? options,
    Set<int>? correctOptionIndices,
  }) : options = options ?? ['', ''],
       correctOptionIndices = correctOptionIndices ?? {};
}