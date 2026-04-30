import 'matching_information_question_draft.dart';

class MatchingInformationDraft {
  List<String> options;
  List<MatchingInformationQuestionDraft> questions;

  MatchingInformationDraft({
    List<String>? options,
    List<MatchingInformationQuestionDraft>? questions,
  }) : options = options ?? [''],
       questions = questions ?? [MatchingInformationQuestionDraft()];
}