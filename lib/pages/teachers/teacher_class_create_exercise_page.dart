import 'dart:convert';
import 'dart:typed_data';

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';

import '../../exceptions/unauthorized_exception.dart';
import '../../models/completion_blank_answer_draft.dart';
import '../../models/matching_information_draft.dart';
import '../../models/multiple_choice_draft.dart';
import '../../models/part_model.dart';
import '../../models/short_answer_draft.dart';
import '../../models/true_false_not_given_draft.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/layout/layout.dart';
import '../../widgets/test/reading_part_creation.dart';
import '../../widgets/test/writing_part_creation.dart';

class TeacherClassCreateExercisePage extends StatefulWidget {
  final String classId;

  const TeacherClassCreateExercisePage({super.key, required this.classId});

  @override
  State<TeacherClassCreateExercisePage> createState() => _TeacherClassCreateExercisePageState();
}

class _TeacherClassCreateExercisePageState extends State<TeacherClassCreateExercisePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final List<String> certificates = ["IELTS"];
  final List<String> skills = ["Listening", "Reading", "Speaking", "Writing"];
  final List<String> listeningQuestionTypes = [
    "Completion",
    "Labeling",
    "Short answer",
    "Multiple choice",
    "Choose from a list",
    "Matching information",
  ];
  final List<String> readingQuestionTypes = [
    "Completion",
    "Labeling",
    "Short answer",
    "Multiple choice",
    "Choose from a list",
    "T/F/NG",
    "Y/N/NG",
    "Matching information",
    "Matching headings",
  ];
  final List<String> completionMaterialTypes = [
    "Note",
    "Table",
    "Summary",
    "Sentence",
    "Diagram",
  ];
  final List<PartModel> _parts = [];
  final Map<int, List<String?>> _questionTypeSelectionsByPart = {};
  final Map<int, List<MultipleChoiceDraft>> _multipleChoiceDraftsByPart = {};
  final Map<int, List<TrueFalseNotGivenDraft>> _trueFalseNotGivenDraftsByPart =
      {};
  final Map<int, List<ShortAnswerDraft>> _shortAnswerDraftsByPart = {};
  final Map<int, List<MatchingInformationDraft>>
  _matchingInformationDraftsByPart = {};
  final Map<int, List<String?>> _completionMaterialSelectionsByPart = {};
  final Map<int, List<QuillController>> _materialTextControllersByPart = {};
  final Map<int, List<QuillController>> _instructionTextControllersByPart = {};
  final Map<int, List<TextEditingController>>
  _blankQuestionNoControllersByPart = {};
  final Map<int, List<TextEditingController>>
  _blankCorrectAnswerControllersByPart = {};
  final Map<int, List<List<CompletionBlankAnswerDraft>>>
  _completionBlankAnswersByPart = {};
  final Map<int, List<List<String>>> _labelingOptionsByPart = {};

  String? _selectedCertificate;
  String? _selectedSkill;

  @override
  void initState() {
    super.initState();
  }

  String _quillControllerToHtml(QuillController controller) {
    final delta = controller.document.toDelta();
    final converter = QuillDeltaToHtmlConverter(
      delta.toJson(),
      ConverterOptions.forEmail(),
    );
    return converter.convert();
  }

  @override
  void dispose() {
    for (var part in _parts) {
      part.textController.dispose();
      part.classController.dispose();
      part.classController.removeListener(part.onClassChanged);
    }
    for (final controllers in _materialTextControllersByPart.values) {
      for (final controller in controllers) {
        controller.dispose();
      }
    }
    for (final controllers in _instructionTextControllersByPart.values) {
      for (final controller in controllers) {
        controller.dispose();
      }
    }
    for (final controllers in _blankQuestionNoControllersByPart.values) {
      for (final controller in controllers) {
        controller.dispose();
      }
    }
    for (final controllers in _blankCorrectAnswerControllersByPart.values) {
      for (final controller in controllers) {
        controller.dispose();
      }
    }
    for (final blankAnswers in _completionBlankAnswersByPart.values) {
      for (final answerList in blankAnswers) {
        for (final answerDraft in answerList) {
          answerDraft.dispose();
        }
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Title(
      color: Colors.black,
      title: "Tạo bài tập",
      child: SiteLayout(
        menuNo: 13,
        content: Container(
          color: Colors.white,
          child: ListView(
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.arrow_circle_left_outlined,
                              size: 32,
                            ),
                            onPressed: () {
                              context.go('/classes/${widget.classId}/exercises');
                            },
                          ),
                          Text(
                            "Thêm bài tập",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 20),

                      Padding(
                        padding: EdgeInsets.only(left: 50, right: 50),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: DropdownSearch<String>(
                                items: (filter, loadProps) => certificates,
                                popupProps: PopupProps.menu(
                                  disableFilter: true,
                                  showSearchBox: false,
                                  infiniteScrollProps: InfiniteScrollProps(
                                    loadProps: LoadProps(skip: 0, take: 10),
                                  ),
                                  constraints: BoxConstraints(maxHeight: 150),
                                  scrollbarProps: ScrollbarProps(
                                    thumbVisibility: true,
                                  ),
                                  containerBuilder: (context, popupWidget) =>
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          color: Colors.white,
                                        ),
                                        child: popupWidget,
                                      ),
                                  itemBuilder:
                                      (context, item, isDisabled, isSelected) =>
                                          Container(
                                            height: 40,
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 16,
                                            ),
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              item,
                                              style: TextStyle(
                                                color: isSelected
                                                    ? Color(0xFF1E40AF)
                                                    : Colors.black,
                                                fontSize: 14,
                                                fontWeight: isSelected
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                              ),
                                            ),
                                          ),
                                ),
                                autoValidateMode:
                                    AutovalidateMode.onUserInteraction,
                                decoratorProps: DropDownDecoratorProps(
                                  decoration: InputDecoration(
                                    labelText: 'Chứng chỉ',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.red),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.red,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                                selectedItem: _selectedCertificate,
                                onChanged: (value) {
                                  _selectedCertificate = value;
                                },
                                validator: (value) => value == null
                                    ? 'Vui lòng chọn chứng chỉ'
                                    : null,
                              ),
                            ),
                            SizedBox(width: 12),

                            Expanded(
                              child: DropdownSearch<String>(
                                items: (filter, loadProps) => skills,
                                popupProps: PopupProps.menu(
                                  disableFilter: true,
                                  showSearchBox: false,
                                  infiniteScrollProps: InfiniteScrollProps(
                                    loadProps: LoadProps(skip: 0, take: 10),
                                  ),
                                  constraints: BoxConstraints(maxHeight: 150),
                                  scrollbarProps: ScrollbarProps(
                                    thumbVisibility: true,
                                  ),
                                  containerBuilder: (context, popupWidget) =>
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          color: Colors.white,
                                        ),
                                        child: popupWidget,
                                      ),
                                  itemBuilder:
                                      (context, item, isDisabled, isSelected) =>
                                          Container(
                                            height: 40,
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 16,
                                            ),
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              item,
                                              style: TextStyle(
                                                color: isSelected
                                                    ? Color(0xFF1E40AF)
                                                    : Colors.black,
                                                fontSize: 14,
                                                fontWeight: isSelected
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                              ),
                                            ),
                                          ),
                                ),
                                autoValidateMode:
                                    AutovalidateMode.onUserInteraction,
                                decoratorProps: DropDownDecoratorProps(
                                  decoration: InputDecoration(
                                    labelText: 'Kỹ năng',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.red),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.red,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                                selectedItem: _selectedSkill,
                                onChanged: (value) {
                                  _selectedSkill = value;
                                },
                                validator: (value) => value == null
                                    ? 'Vui lòng chọn kỹ năng'
                                    : null,
                              ),
                            ),
                            SizedBox(width: 12),

                            Expanded(
                              child: TextFormField(
                                controller: _titleController,
                                decoration: InputDecoration(
                                  labelText: 'Tiêu đề',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.red),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.red,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                validator: (value) =>
                                    (value == null || value.trim().isEmpty)
                                    ? 'Vui lòng nhập tiêu đề'
                                    : null,
                                textInputAction: TextInputAction.next,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(child: Container()),
                          Align(
                            alignment: Alignment.center,
                            child: ElevatedButton(
                              onPressed: () {
                                if (!_formKey.currentState!.validate()) {
                                  return;
                                }
                                setState(() {
                                  final part = PartModel(
                                    id: _parts.length,
                                    classController: TextEditingController(),
                                    refresh: () => setState(() {}),
                                  );
                                  part.classController.addListener(
                                    part.onClassChanged,
                                  );
                                  _parts.add(part);
                                  _questionTypeSelectionsByPart[part.id] = [];
                                  _multipleChoiceDraftsByPart[part.id] = [];
                                  _trueFalseNotGivenDraftsByPart[part.id] = [];
                                  _shortAnswerDraftsByPart[part.id] = [];
                                  _matchingInformationDraftsByPart[part.id] =
                                      [];
                                  _completionMaterialSelectionsByPart[part.id] =
                                      [];
                                  _materialTextControllersByPart[part.id] = [];
                                  _instructionTextControllersByPart[part.id] =
                                      [];
                                  _blankQuestionNoControllersByPart[part.id] =
                                      [];
                                  _blankCorrectAnswerControllersByPart[part
                                          .id] =
                                      [];
                                  _completionBlankAnswersByPart[part.id] = [];
                                  _labelingOptionsByPart[part.id] = [];
                                });
                              },
                              style: ButtonStyle(
                                backgroundColor: WidgetStateProperty.all(
                                  Color(0xFF1E40AF),
                                ),
                                foregroundColor: WidgetStateProperty.all(
                                  Colors.white,
                                ),
                                overlayColor: WidgetStateProperty.all(
                                  Colors.transparent,
                                ),
                                minimumSize: WidgetStateProperty.all(
                                  Size(150, 50),
                                ),
                                maximumSize: WidgetStateProperty.all(
                                  Size(150, 50),
                                ),
                                elevation: WidgetStateProperty.all(0),
                                shape: WidgetStateProperty.all(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.add_outlined, size: 20),
                                  SizedBox(width: 4),
                                  Text('Thêm part'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 12),

                      Column(
                        children: _parts.map((part) {
                          if (_selectedSkill == "Writing") {
                            return WritingPartCreation(
                              part: part,
                              parts: _parts,
                              clearPart: () {
                                setState(() {
                                  part.textController.dispose();
                                  part.classController.dispose();
                                  part.classController.removeListener(
                                    part.onClassChanged,
                                  );
                                  _parts.remove(part);
                                  for (part in _parts) {
                                    part.id = _parts.indexOf(part);
                                  }
                                });
                              }
                            );
                          }
                          return ReadingPartCreation(
                            part: part,
                            parts: _parts,
                            questionTypeSelectionsByPart: _questionTypeSelectionsByPart,
                            multipleChoiceDraftsByPart: _multipleChoiceDraftsByPart,
                            trueFalseNotGivenDraftsByPart: _trueFalseNotGivenDraftsByPart,
                            shortAnswerDraftsByPart: _shortAnswerDraftsByPart,
                            matchingInformationDraftsByPart: _matchingInformationDraftsByPart,
                            completionMaterialSelectionsByPart: _completionMaterialSelectionsByPart,
                            materialTextControllersByPart: _materialTextControllersByPart,
                            instructionTextControllersByPart: _instructionTextControllersByPart,
                            blankQuestionNoControllersByPart: _blankQuestionNoControllersByPart,
                            blankCorrectAnswerControllersByPart: _blankCorrectAnswerControllersByPart,
                            completionBlankAnswersByPart: _completionBlankAnswersByPart,
                            labelingOptionsByPart: _labelingOptionsByPart
                          );
                        }).toList(),
                      ),

                      SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(child: Container()),
                          ElevatedButton(
                            onPressed: () async {
                              if (!_formKey.currentState!.validate() ||
                                  _parts.any((part) => part.classError)) {
                                return;
                              }

                              var assessmentResponse = await ApiService.post(
                                '/identity/assessments',
                                token: authService.accessToken,
                                body: {
                                  'title': _titleController.text.trim(),
                                  'classIds': [widget.classId],
                                  'type': 'TEST',
                                },
                              );

                              if (assessmentResponse.statusCode == 401) {
                                var refreshResponse = await ApiService.post(
                                  '/identity/auth/refresh',
                                  body: {'token': authService.accessToken},
                                );

                                var refreshData = jsonDecode(refreshResponse.body);
                                if (refreshData['code'] == 1000) {
                                  final newToken = refreshData['result']['token'];
                                  await authService.setAuth(newToken);

                                  assessmentResponse = await ApiService.post(
                                    '/identity/assessments',
                                    token: authService.accessToken,
                                    body: {
                                      'title': _titleController.text.trim(),
                                      'classIds': [widget.classId],
                                      'type': 'EXERCISE',
                                    },
                                  );
                                } else {
                                  await authService.clearAuth();
                                  throw UnauthorizedException();
                                }
                              }

                              final assessmentData = jsonDecode(assessmentResponse.body);
                              final assessmentId = assessmentData['result']['id'];

                              for (var part in _parts) {
                                if (_selectedSkill == "Listening") {}
                                if (_selectedSkill == "Reading") {
                                  final partText = part.textController.document
                                      .toPlainText()
                                      .trim();
                                  final html = partText.isNotEmpty
                                      ? QuillDeltaToHtmlConverter(
                                          part.textController.document
                                              .toDelta()
                                              .toJson(),
                                          ConverterOptions.forEmail(),
                                        ).convert()
                                      : '';

                                  var response = await ApiService.post(
                                    '/identity/reading-assessments',
                                    token: authService.accessToken,
                                    body: {
                                      'assessmentId': assessmentId,
                                      'partNumber': part.id + 1,
                                      'text': html,
                                      'questionGroups': part.questionTypes.asMap().entries.map((
                                        entry,
                                      ) {
                                        final qTypeIndex = entry.key;
                                        final selectedQType =
                                            _questionTypeSelectionsByPart[part
                                                .id]?[qTypeIndex];

                                        if (selectedQType == 'Completion') {
                                          final completionInstruction =
                                              _quillControllerToHtml(
                                                _instructionTextControllersByPart[part
                                                    .id]![qTypeIndex],
                                              );

                                          return {
                                            'type': 'COMPLETION',
                                            'instruction':
                                                completionInstruction,
                                            'questions': _completionBlankAnswersByPart[part.id]![qTypeIndex].map((
                                              blankAnswer,
                                            ) {
                                              final completionMaterialDelta =
                                                  _materialTextControllersByPart[part
                                                          .id]![qTypeIndex]
                                                      .document
                                                      .toDelta();
                                              final completionMaterialConverter =
                                                  QuillDeltaToHtmlConverter(
                                                    completionMaterialDelta
                                                        .toJson(),
                                                    ConverterOptions(
                                                      converterOptions:
                                                          OpConverterOptions(
                                                            encodeHtml: false,
                                                          ),
                                                    ),
                                                  );
                                              final completionContent =
                                                  completionMaterialConverter
                                                      .convert();

                                              return {
                                                'order': blankAnswer.questionNo,
                                                'content': completionContent,
                                                'answer': blankAnswer
                                                    .correctAnswerController
                                                    .text,
                                                'choices': []
                                              };
                                            }).toList(),
                                          };
                                        }

                                        if (selectedQType == 'Labeling') {
                                          final labelingInstruction =
                                              _quillControllerToHtml(
                                                _instructionTextControllersByPart[part
                                                    .id]![qTypeIndex],
                                              );

                                          return {
                                            'type': 'LABELING',
                                            'instruction': labelingInstruction,
                                            'questions': _completionBlankAnswersByPart[part.id]![qTypeIndex].map((
                                              blankAnswer,
                                            ) {
                                              final completionMaterialDelta =
                                                  _materialTextControllersByPart[part
                                                          .id]![qTypeIndex]
                                                      .document
                                                      .toDelta();
                                              final completionMaterialConverter =
                                                  QuillDeltaToHtmlConverter(
                                                    completionMaterialDelta
                                                        .toJson(),
                                                    ConverterOptions(
                                                      converterOptions:
                                                          OpConverterOptions(
                                                            encodeHtml: false,
                                                          ),
                                                    ),
                                                  );
                                              final completionContent =
                                                  completionMaterialConverter
                                                      .convert();

                                              return {
                                                'order': blankAnswer.questionNo,
                                                'content': completionContent,
                                                'answer': blankAnswer
                                                    .correctAnswerController
                                                    .text,
                                              };
                                            }).toList(),
                                            'options':
                                                _labelingOptionsByPart[part
                                                        .id]![qTypeIndex]
                                                    .map(
                                                      (option) => {
                                                        'order':
                                                            _labelingOptionsByPart[part
                                                                    .id]![qTypeIndex]
                                                                .indexOf(
                                                                  option,
                                                                ) +
                                                            1,
                                                        'content': option,
                                                      },
                                                    )
                                                    .toList(),
                                          };
                                        }

                                        if (selectedQType == 'Short answer') {
                                          return {
                                            'type': 'COMPLETION',
                                            'instruction': _quillControllerToHtml(
                                              _instructionTextControllersByPart[part
                                                  .id]![qTypeIndex],
                                            ),
                                            'questions':
                                                _shortAnswerDraftsByPart[part
                                                        .id]![qTypeIndex]
                                                    .questions
                                                    .map(
                                                      (q) => {
                                                        'order':
                                                            0, // You can add an order field if needed
                                                        'content': q.question,
                                                        'answer': q.answer,
                                                      },
                                                    )
                                                    .toList(),
                                          };
                                        }

                                        if (selectedQType ==
                                                'Multiple choice' ||
                                            selectedQType ==
                                                'Choose from a list') {
                                          return {
                                            'type': 'MULTIPLE_CHOICE',
                                            'instruction': _quillControllerToHtml(
                                              _instructionTextControllersByPart[part
                                                  .id]![qTypeIndex],
                                            ),
                                            'questions':
                                                _multipleChoiceDraftsByPart[part
                                                        .id]![qTypeIndex]
                                                    .questions
                                                    .map(
                                                      (q) => {
                                                        'order':
                                                            0, // You can add an order field if needed
                                                        'content': q.question,
                                                        'choices': q.options.map((
                                                          choice,
                                                        ) {
                                                          final choiceIndex = q
                                                              .options
                                                              .indexOf(choice);
                                                          return {
                                                            'order':
                                                                choiceIndex + 1,
                                                            'content': choice,
                                                            'isCorrect': q
                                                                .correctOptionIndices
                                                                .contains(
                                                                  choiceIndex,
                                                                ),
                                                          };
                                                        }).toList(),
                                                      },
                                                    )
                                                    .toList(),
                                          };
                                        }

                                        if (selectedQType == 'T/F/NG' ||
                                            selectedQType == 'Y/N/NG') {
                                          return {
                                            'type': 'TRUE_FALSE',
                                            'instruction': _quillControllerToHtml(
                                              _instructionTextControllersByPart[part
                                                  .id]![qTypeIndex],
                                            ),
                                            'questions':
                                                _trueFalseNotGivenDraftsByPart[part
                                                        .id]![qTypeIndex]
                                                    .questions
                                                    .map(
                                                      (q) => {
                                                        'order': q.questionNo,
                                                        'content': q.statement,
                                                        'choices': [
                                                          {
                                                            'order': 1, 
                                                            'content': (selectedQType == 'T/F/NG') ? 'TRUE' : 'YES',
                                                            'isCorrect': q.correctAnswer == 'TRUE' || q.correctAnswer == 'YES',
                                                          },
                                                          {
                                                            'order': 2, 
                                                            'content': (selectedQType == 'T/F/NG') ? 'FALSE' : 'NO',
                                                            'isCorrect': q.correctAnswer == 'FALSE' || q.correctAnswer == 'NO',
                                                          },
                                                          {
                                                            'order': 3, 
                                                            'content': 'NOT GIVEN',
                                                            'isCorrect': q.correctAnswer == 'NOT GIVEN',
                                                          },
                                                        ],
                                                        'answer': q.correctAnswer,
                                                      },
                                                    )
                                                    .toList(),
                                          };
                                        }

                                        if (selectedQType == 'Matching information') {
                                          return {
                                            'type': 'MATCHING',
                                            'instruction': _quillControllerToHtml(
                                              _instructionTextControllersByPart[part.id]![qTypeIndex],
                                            ),
                                            'questions': _matchingInformationDraftsByPart[part.id]![qTypeIndex].questions.map((q) => {
                                              'order': 0, // You can add an order field if needed
                                              'content': q.question,
                                              'answer': q.answer,
                                            }).toList(),
                                            'options': _matchingInformationDraftsByPart[part.id]![qTypeIndex].options.asMap().entries.map((optionEntry) => {
                                              'order': optionEntry.key + 1,
                                              'content': optionEntry.value,
                                            }).toList(),
                                          };
                                        }

                                        return {
                                          'type': selectedQType,
                                          'instruction':
                                              (selectedQType == 'Labeling')
                                              ? _quillControllerToHtml(
                                                  _instructionTextControllersByPart[part
                                                      .id]![qTypeIndex],
                                                )
                                              : '',
                                          'questions':
                                              selectedQType ==
                                                      "Multiple choice" ||
                                                  selectedQType ==
                                                      "Choose from a list"
                                              ? _multipleChoiceDraftsByPart[part
                                                        .id]![qTypeIndex]
                                                    .questions
                                                    .map(
                                                      (q) => {
                                                        'question': q.question,
                                                        'options': q.options,
                                                        'correctOptionIndices': q
                                                            .correctOptionIndices
                                                            .toList(),
                                                      },
                                                    )
                                                    .toList()
                                              : selectedQType == "T/F/NG" ||
                                                    selectedQType == "Y/N/NG"
                                              ? _trueFalseNotGivenDraftsByPart[part
                                                        .id]![qTypeIndex]
                                                    .questions
                                                    .map(
                                                      (q) => {
                                                        'statement':
                                                            q.statement,
                                                        'correctAnswer':
                                                            q.correctAnswer,
                                                      },
                                                    )
                                                    .toList()
                                              : [],
                                        };
                                      }).toList(),
                                    },
                                  );

                                  if (response.statusCode == 200) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Tạo part thành công'),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Tạo part thất bại'),
                                      ),
                                    );
                                  }
                                }
                                else if (_selectedSkill == "Writing") {
                                  var uri = Uri.parse("http://localhost:8080/identity/writing-assessments");
                                  var request = http.MultipartRequest("POST", uri);
                                  request.headers['Authorization'] = 'Bearer ${authService.accessToken}';
                                  
                                  request.fields['data'] = jsonEncode({
                                    'assessmentId': assessmentId,
                                    'partNumber': part.id + 1,
                                    'text': _quillControllerToHtml(part.textController),
                                    'questionGroups': [
                                      {
                                        'type': 'WRITING',
                                        'instruction': 'Write at least 150 words.',
                                        'questions': [
                                          {
                                            'order': part.id + 1,
                                            'content': 'Write a paragraph describing the overall trend shown in the chart.',
                                          },
                                        ],
                                      },
                                    ],
                                  });

                                  var filePath = part.file?.url;
                                  if (filePath != null && filePath.isNotEmpty) {
                                    request.files.add(await http.MultipartFile.fromBytes(
                                      'file', 
                                      part.file?.content != null ? await part.file!.content!.reduce((a, b) => a + b) : Uint8List(0),
                                      filename: part.file?.name,
                                    ));
                                  }

                                  final streamedResponse = await request.send();
                                  final response = await http.Response.fromStream(
                                    streamedResponse,
                                  );

                                  if (response.statusCode == 200 ||
                                      response.statusCode == 201) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Tạo part ${part.id + 1} thành công'),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Tạo part ${part.id + 1} thất bại'),
                                      ),
                                    );
                                  }
                                }  
                              }
                              context.go('/classes/${widget.classId}/exercises');
                            },
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.all(
                                Color(0xFF1E40AF),
                              ),
                              foregroundColor: WidgetStateProperty.all(
                                Colors.white,
                              ),
                              overlayColor: WidgetStateProperty.all(
                                Colors.transparent,
                              ),
                              minimumSize: WidgetStateProperty.all(
                                Size(150, 50),
                              ),
                              elevation: WidgetStateProperty.all(0),
                              shape: WidgetStateProperty.all(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            child: Text('Tạo bài tập'),
                          ),
                          Expanded(child: Container()),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}