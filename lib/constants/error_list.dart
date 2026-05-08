final List<Map<String, String>> errorTypes = [
  {'id': 'GRAMMAR_VERB_TENSE', 'name': 'Dùng sai thì của động từ'},
  {'id': 'GRAMMAR_SUBJECT_VERB_AGREEMENT', 'name': 'Không hòa hợp chủ ngữ - động từ'},
  {'id': 'GRAMMAR_ARTICLE', 'name': 'Dùng mạo từ không đúng'},
  {'id': 'GRAMMAR_PREPOSITION', 'name': 'Dùng giới từ không đúng'},
  {'id': 'GRAMMAR_SENTENCE_STRUCTURE', 'name': 'Cấu trúc câu không đúng'},
  {'id': 'VOCAB_WORD_CHOICE', 'name': 'Chọn từ chưa phù hợp'},
  {'id': 'VOCAB_COLLOCATION', 'name': 'Dùng collocation không đúng'},
  {'id': 'VOCAB_REPETITION', 'name': 'Lặp từ'},
  {'id': 'COHERENCE_LINKING_WORD', 'name': 'Dùng từ nối chưa phù hợp'},
  {'id': 'COHERENCE_LOGICAL_FLOW', 'name': 'Mạch ý chưa rõ ràng'},
  {'id': 'TASK_UNDERDEVELOPED_IDEA', 'name': 'Phát triển ý chưa đủ'},
  {'id': 'TASK_OFF_TOPIC', 'name': 'Lạc đề'},
];

String getErrorTypeName(String errorTypeId) {
  final errorType = errorTypes.firstWhere((e) => e['id'] == errorTypeId, orElse: () => {});
  return errorType['name'] ?? '';
}