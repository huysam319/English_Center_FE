import 'short_answer_question_draft.dart';

class ShortAnswerDraft {
  List<ShortAnswerQuestionDraft> questions;

  ShortAnswerDraft({List<ShortAnswerQuestionDraft>? questions})
    : questions = questions ?? [ShortAnswerQuestionDraft()];
}