import 'multiple_choice_question_draft.dart';

class MultipleChoiceDraft {
  List<MultipleChoiceQuestionDraft> questions;

  MultipleChoiceDraft({List<MultipleChoiceQuestionDraft>? questions})
    : questions = questions ?? [MultipleChoiceQuestionDraft()];
}