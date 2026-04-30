import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../models/completion_blank_answer_draft.dart';
import '../../models/matching_information_draft.dart';
import '../../models/matching_information_question_draft.dart';
import '../../models/multiple_choice_draft.dart';
import '../../models/multiple_choice_question_draft.dart';
import '../../models/part_model.dart';
import '../../models/question_type_model.dart';
import '../../models/short_answer_draft.dart';
import '../../models/short_answer_question_draft.dart';
import '../../models/true_false_not_given_draft.dart';
import '../../models/true_false_not_given_question_draft.dart';

class ReadingPartCreation extends StatefulWidget {
  final PartModel part;
  final List<PartModel> parts;
  final Map<int, List<String?>> questionTypeSelectionsByPart;
  final Map<int, List<MultipleChoiceDraft>> multipleChoiceDraftsByPart;
  final Map<int, List<TrueFalseNotGivenDraft>> trueFalseNotGivenDraftsByPart;
  final Map<int, List<ShortAnswerDraft>> shortAnswerDraftsByPart;
  final Map<int, List<MatchingInformationDraft>> matchingInformationDraftsByPart;
  final Map<int, List<String?>> completionMaterialSelectionsByPart;
  final Map<int, List<QuillController>> materialTextControllersByPart;
  final Map<int, List<QuillController>> instructionTextControllersByPart;
  final Map<int, List<TextEditingController>> blankQuestionNoControllersByPart;
  final Map<int, List<TextEditingController>> blankCorrectAnswerControllersByPart;
  final Map<int, List<List<CompletionBlankAnswerDraft>>> completionBlankAnswersByPart;
  final Map<int, List<List<String>>> labelingOptionsByPart;

  const ReadingPartCreation({super.key, required this.part, required this.parts, required this.questionTypeSelectionsByPart, required this.multipleChoiceDraftsByPart, required this.trueFalseNotGivenDraftsByPart, required this.shortAnswerDraftsByPart, required this.matchingInformationDraftsByPart, required this.completionMaterialSelectionsByPart, required this.materialTextControllersByPart, required this.instructionTextControllersByPart, required this.blankQuestionNoControllersByPart, required this.blankCorrectAnswerControllersByPart, required this.completionBlankAnswersByPart, required this.labelingOptionsByPart});

  @override
  State<ReadingPartCreation> createState() => _ReadingPartCreationState();
}

class _ReadingPartCreationState extends State<ReadingPartCreation> {
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

  void _syncBlankQuestionNumbers(int partId) {
    final controllers = widget.blankQuestionNoControllersByPart[partId];
    if (controllers == null) return;

    for (var index = 0; index < controllers.length; index++) {
      final expectedValue = (index + 1).toString();
      final controller = controllers[index];

      if (controller.text != expectedValue) {
        controller.text = expectedValue;
        controller.selection = TextSelection.collapsed(
          offset: expectedValue.length,
        );
      }
    }
  }

  int _nextCompletionBlankQuestionNo({
    required int partId,
    required int questionTypeIndex,
  }) {
    final blanks = widget.completionBlankAnswersByPart[partId]![questionTypeIndex];
    var maxQuestionNo = 0;

    for (final blank in blanks) {
      if (blank.questionNo > maxQuestionNo) {
        maxQuestionNo = blank.questionNo;
      }
    }

    return maxQuestionNo + 1;
  }

  int? _insertBlankTag({required int partId, required int questionTypeIndex}) {
    final questionNo = _nextCompletionBlankQuestionNo(
      partId: partId,
      questionTypeIndex: questionTypeIndex,
    );

    final editorController = widget.materialTextControllersByPart[partId]![questionTypeIndex];
    var baseOffset = editorController.selection.baseOffset;
    var extentOffset = editorController.selection.extentOffset;

    if (baseOffset < 0 || extentOffset < 0) {
      baseOffset = editorController.document.length - 1;
      extentOffset = baseOffset;
    }

    final startOffset = baseOffset < extentOffset ? baseOffset : extentOffset;
    final replaceLength = (extentOffset - baseOffset).abs();
    final blankTag = '<blank id="$questionNo"></blank>';

    editorController.replaceText(
      startOffset,
      replaceLength,
      blankTag,
      TextSelection.collapsed(offset: startOffset + blankTag.length),
    );
    return questionNo;
  }

  void _renumberCompletionBlankQuestions({
    required int partId,
    required int questionTypeIndex,
  }) {
    final blanks = widget.completionBlankAnswersByPart[partId]![questionTypeIndex];

    for (var index = 0; index < blanks.length; index++) {
      blanks[index].questionNo = index + 1;
    }
  }

  void _addBlankQuestionAnswer({
    required int partId,
    required int questionTypeIndex,
  }) {
    final correctAnswerController = widget.blankCorrectAnswerControllersByPart[partId]![questionTypeIndex];
    final correctAnswer = correctAnswerController.text.trim();

    if (correctAnswer.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Vui lòng nhập đáp án đúng')));
      return;
    }

    final questionNo = _insertBlankTag(
      partId: partId,
      questionTypeIndex: questionTypeIndex,
    );

    if (questionNo == null) return;

    setState(() {
      widget.completionBlankAnswersByPart[partId]![questionTypeIndex].add(
        CompletionBlankAnswerDraft(
          questionNo: questionNo,
          initialCorrectAnswer: correctAnswer,
        ),
      );
    });

    correctAnswerController.clear();
  }

  void _renumberTrueFalseNotGivenQuestions({
    required int partId,
    required int questionTypeIndex,
  }) {
    final questions = widget.trueFalseNotGivenDraftsByPart[partId]![questionTypeIndex].questions;

    for (var index = 0; index < questions.length; index++) {
      questions[index].questionNo = index + 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    _syncBlankQuestionNumbers(widget.part.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        color: Colors.grey.shade300,
        alignment: Alignment.center,
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      "Part ${widget.part.id + 1}",
                      style: TextStyle(
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 16),
                  onPressed: () {
                    setState(() {
                      widget.part.textController.dispose();
                      widget.part.classController.dispose();
                      widget.part.classController
                          .removeListener(
                            widget.part.onClassChanged,
                          );
                      widget.questionTypeSelectionsByPart.remove(widget.part.id);
                      widget.multipleChoiceDraftsByPart.remove(widget.part.id);
                      widget.trueFalseNotGivenDraftsByPart.remove(widget.part.id);
                      widget.shortAnswerDraftsByPart.remove(widget.part.id);
                      widget.matchingInformationDraftsByPart.remove(widget.part.id);
                      widget.completionMaterialSelectionsByPart.remove(widget.part.id);
                      widget.labelingOptionsByPart.remove(widget.part.id);
                      final materialControllers = widget.materialTextControllersByPart.remove(widget.part.id);
                      if (materialControllers != null) {
                        for (final controller in materialControllers) {
                          controller.dispose();
                        }
                      }
                      final blankQuestionNoControllers = widget.blankQuestionNoControllersByPart.remove(widget.part.id);
                      if (blankQuestionNoControllers != null) {
                        for (final controller in blankQuestionNoControllers) {
                          controller.dispose();
                        }
                      }
                      final blankCorrectAnswerControllers = widget.blankCorrectAnswerControllersByPart.remove(widget.part.id);
                      if (blankCorrectAnswerControllers != null) {
                        for (final controller in blankCorrectAnswerControllers) {
                          controller.dispose();
                        }
                      }
                      final blankAnswers = widget.completionBlankAnswersByPart.remove(widget.part.id);
                      if (blankAnswers != null) {
                        for (final answerList in blankAnswers) {
                          for (final answerDraft in answerList) {
                            answerDraft.dispose();
                          }
                        }
                      }
                      widget.parts.remove(widget.part);
                    });
                    final instructionControllers = widget.instructionTextControllersByPart.remove(widget.part.id);
                    if (instructionControllers != null) {
                      for (final controller in instructionControllers) {
                        controller.dispose();
                      }
                    }
                  },
                  style: ButtonStyle(
                    padding: WidgetStateProperty.all(EdgeInsets.zero),
                    minimumSize: WidgetStateProperty.all(Size(16, 16)),
                    maximumSize: WidgetStateProperty.all(Size(16, 16)),
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: Colors.black,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    QuillSimpleToolbar(
                      controller:
                          widget.part.textController,
                    ),
                    Divider(
                      color: Colors.grey,
                      thickness: 1,
                      height: 20,
                    ),
                    QuillEditor(
                      controller:
                          widget.part.textController,
                      scrollController:
                          ScrollController(),
                      focusNode: FocusNode(),
                      config: QuillEditorConfig(
                        padding: EdgeInsets.all(10),
                        autoFocus: false,
                        expands: false,
                        placeholder:
                            'Add your passage here...',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Column(
              children: [
                ...((widget.questionTypeSelectionsByPart[widget.part
                            .id] ??
                        [])
                    .asMap()
                    .entries
                    .map((entry) {
                      final index = entry.key;
                      final selectedValue =
                          entry.value;

                      return Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.only(
                              bottom: 12,
                            ),
                            child: Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .end,
                              children: [
                                Expanded(
                                  child: DropdownSearch<String>(
                                    items: (filter, loadProps) => readingQuestionTypes,
                                    popupProps: PopupProps.menu(
                                      disableFilter:
                                          true,
                                      showSearchBox:
                                          false,
                                      infiniteScrollProps:
                                          InfiniteScrollProps(
                                            loadProps: LoadProps(
                                              skip: 0,
                                              take:
                                                  10,
                                            ),
                                          ),
                                      constraints:
                                          BoxConstraints(
                                            maxHeight:
                                                150,
                                          ),
                                      scrollbarProps:
                                          ScrollbarProps(
                                            thumbVisibility:
                                                true,
                                          ),
                                      containerBuilder:
                                          (
                                            context,
                                            popupWidget,
                                          ) => Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    12,
                                                  ),
                                              color: Colors
                                                  .white,
                                            ),
                                            child:
                                                popupWidget,
                                          ),
                                      itemBuilder:
                                          (
                                            context,
                                            item,
                                            isDisabled,
                                            isSelected,
                                          ) => Container(
                                            height:
                                                40,
                                            padding: EdgeInsets.symmetric(
                                              horizontal:
                                                  16,
                                            ),
                                            alignment:
                                                Alignment
                                                    .centerLeft,
                                            child: Text(
                                              item,
                                              style: TextStyle(
                                                color:
                                                    isSelected
                                                    ? Color(
                                                        0xFF1E40AF,
                                                      )
                                                    : Colors.black,
                                                fontSize:
                                                    14,
                                                fontWeight:
                                                    isSelected
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                              ),
                                            ),
                                          ),
                                    ),
                                    decoratorProps: DropDownDecoratorProps(
                                      decoration: InputDecoration(
                                        labelText:
                                            'Chọn dạng câu hỏi',
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(
                                                12,
                                              ),
                                        ),
                                      ),
                                    ),
                                    selectedItem:
                                        selectedValue,
                                    onChanged: (value) {
                                      setState(() {
                                        widget.questionTypeSelectionsByPart[widget.part
                                                .id]![index] =
                                            value;
                                        if (widget.part
                                                .questionTypes
                                                .length >
                                            index) {
                                          widget.part.questionTypes[index] = QuestionTypeModel(
                                            id: index,
                                            name:
                                                value ??
                                                '',
                                          );
                                        }
                                        if (value !=
                                                "Completion" &&
                                            value !=
                                                "Labeling") {
                                          widget.completionMaterialSelectionsByPart[widget.part
                                                  .id]![index] =
                                              null;
                                        }
                                        if (value !=
                                            "Labeling") {
                                          widget.labelingOptionsByPart[widget.part
                                              .id]![index] = [
                                            '',
                                          ];
                                        }
                                      });
                                    },
                                  ),
                                ),
                                SizedBox(width: 12),
                                IconButton(
                                  icon: Icon(
                                    Icons
                                        .delete_outline,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      widget.questionTypeSelectionsByPart[widget.part
                                              .id]!
                                          .removeAt(
                                            index,
                                          );
                                      widget.multipleChoiceDraftsByPart[widget.part
                                              .id]!
                                          .removeAt(
                                            index,
                                          );
                                      widget.trueFalseNotGivenDraftsByPart[widget.part
                                              .id]!
                                          .removeAt(
                                            index,
                                          );
                                      widget.shortAnswerDraftsByPart[widget.part
                                              .id]!
                                          .removeAt(
                                            index,
                                          );
                                      widget.matchingInformationDraftsByPart[widget.part
                                              .id]!
                                          .removeAt(
                                            index,
                                          );
                                      widget.completionMaterialSelectionsByPart[widget.part
                                              .id]!
                                          .removeAt(
                                            index,
                                          );
                                      widget.labelingOptionsByPart[widget.part
                                              .id]!
                                          .removeAt(
                                            index,
                                          );
                                      final materialController =
                                          widget.materialTextControllersByPart[widget.part
                                                  .id]!
                                              .removeAt(
                                                index,
                                              );
                                      materialController
                                          .dispose();
                                      final instructionController =
                                          widget.instructionTextControllersByPart[widget.part
                                                  .id]!
                                              .removeAt(
                                                index,
                                              );
                                      instructionController
                                          .dispose();
                                      final blankQuestionNoController =
                                          widget.blankQuestionNoControllersByPart[widget.part
                                                  .id]!
                                              .removeAt(
                                                index,
                                              );
                                      blankQuestionNoController
                                          .dispose();
                                      final blankCorrectAnswerController =
                                          widget.blankCorrectAnswerControllersByPart[widget.part
                                                  .id]!
                                              .removeAt(
                                                index,
                                              );
                                      blankCorrectAnswerController
                                          .dispose();
                                      final blankAnswers =
                                          widget.completionBlankAnswersByPart[widget.part
                                                  .id]!
                                              .removeAt(
                                                index,
                                              );
                                      for (final answerDraft
                                          in blankAnswers) {
                                        answerDraft
                                            .dispose();
                                      }
                                      if (widget.part
                                              .questionTypes
                                              .length >
                                          index) {
                                        widget.part.questionTypes
                                            .removeAt(
                                              index,
                                            );
                                      }
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          if (selectedValue ==
                                  "Completion" ||
                              selectedValue ==
                                  "Labeling")
                            Padding(
                              padding:
                                  EdgeInsets.only(
                                    bottom: 12,
                                  ),
                              child: Container(
                                padding:
                                    EdgeInsets.all(
                                      12,
                                    ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                    color:
                                        Colors.grey,
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(
                                        8,
                                      ),
                                ),
                                child: DropdownSearch<String>(
                                  items:
                                      (
                                        filter,
                                        loadProps,
                                      ) => completionMaterialTypes,
                                  popupProps: PopupProps.menu(
                                    disableFilter:
                                        true,
                                    showSearchBox:
                                        false,
                                    infiniteScrollProps:
                                        InfiniteScrollProps(
                                          loadProps:
                                              LoadProps(
                                                skip:
                                                    0,
                                                take:
                                                    10,
                                              ),
                                        ),
                                    constraints:
                                        BoxConstraints(
                                          maxHeight:
                                              200,
                                        ),
                                    scrollbarProps:
                                        ScrollbarProps(
                                          thumbVisibility:
                                              true,
                                        ),
                                  ),
                                  decoratorProps: DropDownDecoratorProps(
                                    decoration: InputDecoration(
                                      labelText:
                                          'Chọn dạng ngữ liệu',
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(
                                              12,
                                            ),
                                      ),
                                    ),
                                  ),
                                  selectedItem:
                                      widget.completionMaterialSelectionsByPart[widget.part
                                          .id]![index],
                                  onChanged: (value) {
                                    setState(() {
                                      widget.completionMaterialSelectionsByPart[widget.part
                                              .id]![index] =
                                          value;
                                    });
                                  },
                                ),
                              ),
                            ),
                          if ((selectedValue ==
                                      "Completion" ||
                                  selectedValue ==
                                      "Labeling") &&
                              widget.completionMaterialSelectionsByPart[widget.part
                                      .id]![index] !=
                                  null)
                            Padding(
                              padding:
                                  EdgeInsets.only(
                                    bottom: 12,
                                  ),
                              child: Container(
                                padding:
                                    EdgeInsets.all(
                                      12,
                                    ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                    color:
                                        Colors.grey,
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(
                                        8,
                                      ),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    Text(
                                      'Instruction',
                                      style: TextStyle(
                                        fontWeight:
                                            FontWeight
                                                .w600,
                                      ),
                                    ),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    QuillSimpleToolbar(
                                      controller:
                                          widget.instructionTextControllersByPart[widget.part
                                              .id]![index],
                                    ),
                                    Divider(
                                      color:
                                          Colors.grey,
                                      thickness: 1,
                                      height: 20,
                                    ),
                                    SizedBox(
                                      height: 160,
                                      child: QuillEditor(
                                        controller:
                                            widget.instructionTextControllersByPart[widget.part
                                                .id]![index],
                                        scrollController:
                                            ScrollController(),
                                        focusNode:
                                            FocusNode(),
                                        config: QuillEditorConfig(
                                          padding:
                                              EdgeInsets.all(
                                                10,
                                              ),
                                          autoFocus:
                                              false,
                                          expands:
                                              false,
                                          placeholder:
                                              'Nhập instruction...',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (selectedValue ==
                              "Short answer")
                            Padding(
                              padding:
                                  EdgeInsets.only(
                                    bottom: 12,
                                  ),
                              child: Container(
                                padding:
                                    EdgeInsets.all(
                                      12,
                                    ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                    color:
                                        Colors.grey,
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(
                                        8,
                                      ),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    Text(
                                      'Instruction',
                                      style: TextStyle(
                                        fontWeight:
                                            FontWeight
                                                .w600,
                                      ),
                                    ),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    QuillSimpleToolbar(
                                      controller:
                                          widget.instructionTextControllersByPart[widget.part
                                              .id]![index],
                                    ),
                                    Divider(
                                      color:
                                          Colors.grey,
                                      thickness: 1,
                                      height: 20,
                                    ),
                                    SizedBox(
                                      height: 160,
                                      child: QuillEditor(
                                        controller:
                                            widget.instructionTextControllersByPart[widget.part
                                                .id]![index],
                                        scrollController:
                                            ScrollController(),
                                        focusNode:
                                            FocusNode(),
                                        config: QuillEditorConfig(
                                          padding:
                                              EdgeInsets.all(
                                                10,
                                              ),
                                          autoFocus:
                                              false,
                                          expands:
                                              false,
                                          placeholder:
                                              'Nhập instruction...',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (selectedValue ==
                              "Labeling")
                            Padding(
                              padding:
                                  EdgeInsets.only(
                                    bottom: 12,
                                  ),
                              child: Container(
                                padding:
                                    EdgeInsets.all(
                                      12,
                                    ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                    color:
                                        Colors.grey,
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(
                                        8,
                                      ),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    Text(
                                      'Instruction',
                                      style: TextStyle(
                                        fontWeight:
                                            FontWeight
                                                .w600,
                                      ),
                                    ),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    QuillSimpleToolbar(
                                      controller:
                                          widget.instructionTextControllersByPart[widget.part
                                              .id]![index],
                                    ),
                                    Divider(
                                      color:
                                          Colors.grey,
                                      thickness: 1,
                                      height: 20,
                                    ),
                                    SizedBox(
                                      height: 160,
                                      child: QuillEditor(
                                        controller:
                                            widget.instructionTextControllersByPart[widget.part
                                                .id]![index],
                                        scrollController:
                                            ScrollController(),
                                        focusNode:
                                            FocusNode(),
                                        config: QuillEditorConfig(
                                          padding:
                                              EdgeInsets.all(
                                                10,
                                              ),
                                          autoFocus:
                                              false,
                                          expands:
                                              false,
                                          placeholder:
                                              'Nhập instruction...',
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      height: 12,
                                    ),
                                    Text(
                                      'Options để match',
                                      style: TextStyle(
                                        fontWeight:
                                            FontWeight
                                                .w600,
                                      ),
                                    ),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    ...(widget.labelingOptionsByPart[widget.part.id]![index].asMap().entries.map((
                                      optionEntry,
                                    ) {
                                      final optionIndex =
                                          optionEntry
                                              .key;
                                      final optionValue =
                                          optionEntry
                                              .value;

                                      return Padding(
                                        padding:
                                            EdgeInsets.only(
                                              bottom:
                                                  8,
                                            ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: TextFormField(
                                                initialValue:
                                                    optionValue,
                                                onChanged:
                                                    (
                                                      value,
                                                    ) {
                                                      widget.labelingOptionsByPart[widget.part.id]![index][optionIndex] = value;
                                                    },
                                                decoration: InputDecoration(
                                                  labelText:
                                                      'Option ${optionIndex + 1}',
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(
                                                      8,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              width:
                                                  8,
                                            ),
                                            IconButton(
                                              onPressed:
                                                  widget.labelingOptionsByPart[widget.part.id]![index].length >
                                                      1
                                                  ? () {
                                                      setState(
                                                        () {
                                                          widget.labelingOptionsByPart[widget.part.id]![index].removeAt(
                                                            optionIndex,
                                                          );
                                                        },
                                                      );
                                                    }
                                                  : null,
                                              icon: Icon(
                                                Icons
                                                    .delete_outline,
                                                color:
                                                    Colors.red,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    })),
                                    Align(
                                      alignment: Alignment
                                          .centerLeft,
                                      child: TextButton.icon(
                                        onPressed: () {
                                          setState(() {
                                            widget.labelingOptionsByPart[widget.part
                                                    .id]![index]
                                                .add(
                                                  '',
                                                );
                                          });
                                        },
                                        icon: Icon(
                                          Icons
                                              .add_outlined,
                                        ),
                                        label: Text(
                                          'Thêm option',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (widget.completionMaterialSelectionsByPart[widget.part
                                      .id]![index] ==
                                  "Note" ||
                              widget.completionMaterialSelectionsByPart[widget.part
                                      .id]![index] ==
                                  "Summary" ||
                              widget.completionMaterialSelectionsByPart[widget.part
                                      .id]![index] ==
                                  "Sentence")
                            Padding(
                              padding:
                                  EdgeInsets.only(
                                    bottom: 12,
                                  ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                    color:
                                        Colors.black,
                                    width: 1,
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(
                                        8,
                                      ),
                                ),
                                child: Column(
                                  children: [
                                    Padding(
                                      padding:
                                          EdgeInsets.fromLTRB(
                                            12,
                                            12,
                                            12,
                                            0,
                                          ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: TextFormField(
                                              controller:
                                                  widget.blankCorrectAnswerControllersByPart[widget.part.id]![index],
                                              decoration: InputDecoration(
                                                labelText:
                                                    'Đáp án đúng',
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(
                                                    8,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            width: 12,
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              _addBlankQuestionAnswer(
                                                partId:
                                                    widget.part.id,
                                                questionTypeIndex:
                                                    index,
                                              );
                                            },
                                            style: ButtonStyle(
                                              backgroundColor: WidgetStateProperty.all(
                                                Color(
                                                  0xFF1E40AF,
                                                ),
                                              ),
                                              foregroundColor: WidgetStateProperty.all(
                                                Colors
                                                    .white,
                                              ),
                                            ),
                                            child: Text(
                                              'Thêm câu hỏi',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (widget.completionBlankAnswersByPart[widget.part
                                            .id]![index]
                                        .isNotEmpty)
                                      Padding(
                                        padding:
                                            EdgeInsets.fromLTRB(
                                              12,
                                              12,
                                              12,
                                              0,
                                            ),
                                        child: Column(
                                          children: widget.completionBlankAnswersByPart[widget.part.id]![index].asMap().entries.map((
                                            blankEntry,
                                          ) {
                                            final blankIndex =
                                                blankEntry
                                                    .key;
                                            final blankDraft =
                                                blankEntry
                                                    .value;
                                            return Padding(
                                              padding: EdgeInsets.only(
                                                bottom:
                                                    8,
                                              ),
                                              child: Row(
                                                children: [
                                                  SizedBox(
                                                    width: 100,
                                                    child: Text(
                                                      'ID ${blankDraft.questionNo}',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: TextFormField(
                                                      controller: blankDraft.correctAnswerController,
                                                      decoration: InputDecoration(
                                                        labelText: 'Đáp án đúng',
                                                        border: OutlineInputBorder(
                                                          borderRadius: BorderRadius.circular(
                                                            8,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: 8,
                                                  ),
                                                  IconButton(
                                                    onPressed: () {
                                                      setState(
                                                        () {
                                                          final removed = widget.completionBlankAnswersByPart[widget.part.id]![index].removeAt(
                                                            blankIndex,
                                                          );
                                                          removed.dispose();
                                                          _renumberCompletionBlankQuestions(
                                                            partId: widget.part.id,
                                                            questionTypeIndex: index,
                                                          );
                                                        },
                                                      );
                                                    },
                                                    icon: Icon(
                                                      Icons.delete_outline,
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    QuillSimpleToolbar(
                                      controller:
                                          widget.materialTextControllersByPart[widget.part
                                              .id]![index],
                                    ),
                                    Divider(
                                      color:
                                          Colors.grey,
                                      thickness: 1,
                                      height: 20,
                                    ),
                                    QuillEditor(
                                      controller:
                                          widget.materialTextControllersByPart[widget.part
                                              .id]![index],
                                      scrollController:
                                          ScrollController(),
                                      focusNode:
                                          FocusNode(),
                                      config: QuillEditorConfig(
                                        padding:
                                            EdgeInsets.all(
                                              10,
                                            ),
                                        autoFocus:
                                            false,
                                        expands:
                                            false,
                                        placeholder:
                                            'Add your text here...',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (selectedValue ==
                              "Short answer")
                            Padding(
                              padding:
                                  EdgeInsets.only(
                                    bottom: 12,
                                  ),
                              child: Container(
                                padding:
                                    EdgeInsets.all(
                                      12,
                                    ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                    color:
                                        Colors.grey,
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(
                                        8,
                                      ),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    ...(widget.shortAnswerDraftsByPart[widget.part.id]![index].questions.asMap().entries.map((
                                      shortEntry,
                                    ) {
                                      final shortIndex =
                                          shortEntry
                                              .key;
                                      final shortQuestion =
                                          shortEntry
                                              .value;

                                      return Padding(
                                        padding:
                                            EdgeInsets.only(
                                              bottom:
                                                  12,
                                            ),
                                        child: Container(
                                          padding:
                                              EdgeInsets.all(
                                                12,
                                              ),
                                          decoration: BoxDecoration(
                                            color: Colors
                                                .white,
                                            border: Border.all(
                                              color: Colors
                                                  .grey
                                                  .shade300,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(
                                                  8,
                                                ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment
                                                    .start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      'Câu hỏi ${shortIndex + 1}',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                  IconButton(
                                                    onPressed:
                                                        widget.shortAnswerDraftsByPart[widget.part.id]![index].questions.length >
                                                            1
                                                        ? () {
                                                            setState(
                                                              () {
                                                                widget.shortAnswerDraftsByPart[widget.part.id]![index].questions.removeAt(
                                                                  shortIndex,
                                                                );
                                                              },
                                                            );
                                                          }
                                                        : null,
                                                    icon: Icon(
                                                      Icons.delete_outline,
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(
                                                height:
                                                    8,
                                              ),
                                              TextFormField(
                                                initialValue:
                                                    shortQuestion.question,
                                                onChanged:
                                                    (
                                                      value,
                                                    ) {
                                                      shortQuestion.question = value;
                                                    },
                                                decoration: InputDecoration(
                                                  labelText:
                                                      'Nội dung câu hỏi',
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(
                                                      8,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                height:
                                                    10,
                                              ),
                                              TextFormField(
                                                initialValue:
                                                    shortQuestion.answer,
                                                onChanged:
                                                    (
                                                      value,
                                                    ) {
                                                      shortQuestion.answer = value;
                                                    },
                                                decoration: InputDecoration(
                                                  labelText:
                                                      'Đáp án',
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(
                                                      8,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    })),
                                    Align(
                                      alignment: Alignment
                                          .centerLeft,
                                      child: TextButton.icon(
                                        onPressed: () {
                                          setState(() {
                                            widget.shortAnswerDraftsByPart[widget.part
                                                    .id]![index]
                                                .questions
                                                .add(
                                                  ShortAnswerQuestionDraft(),
                                                );
                                          });
                                        },
                                        icon: Icon(
                                          Icons
                                              .add_outlined,
                                        ),
                                        label: Text(
                                          'Thêm câu hỏi',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (selectedValue ==
                              "Matching information")
                            Padding(
                              padding:
                                  EdgeInsets.only(
                                    bottom: 12,
                                  ),
                              child: Container(
                                padding:
                                    EdgeInsets.all(
                                      12,
                                    ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                    color:
                                        Colors.grey,
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(
                                        8,
                                      ),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    Text(
                                      'Instruction',
                                      style: TextStyle(
                                        fontWeight:
                                            FontWeight
                                                .w600,
                                      ),
                                    ),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    QuillSimpleToolbar(
                                      controller:
                                          widget.instructionTextControllersByPart[widget.part
                                              .id]![index],
                                    ),
                                    Divider(
                                      color:
                                          Colors.grey,
                                      thickness: 1,
                                      height: 20,
                                    ),
                                    SizedBox(
                                      height: 160,
                                      child: QuillEditor(
                                        controller:
                                            widget.instructionTextControllersByPart[widget.part
                                                .id]![index],
                                        scrollController:
                                            ScrollController(),
                                        focusNode:
                                            FocusNode(),
                                        config: QuillEditorConfig(
                                          padding:
                                              EdgeInsets.all(
                                                10,
                                              ),
                                          autoFocus:
                                              false,
                                          expands:
                                              false,
                                          placeholder:
                                              'Nhập instruction...',
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      height: 12,
                                    ),
                                    Text(
                                      'Options để match',
                                      style: TextStyle(
                                        fontWeight:
                                            FontWeight
                                                .w600,
                                      ),
                                    ),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    ...(widget.matchingInformationDraftsByPart[widget.part.id]![index].options.asMap().entries.map((
                                      optionEntry,
                                    ) {
                                      final optionIndex =
                                          optionEntry
                                              .key;
                                      final optionValue =
                                          optionEntry
                                              .value;

                                      return Padding(
                                        padding:
                                            EdgeInsets.only(
                                              bottom:
                                                  8,
                                            ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: TextFormField(
                                                initialValue:
                                                    optionValue,
                                                onChanged:
                                                    (
                                                      value,
                                                    ) {
                                                      widget.matchingInformationDraftsByPart[widget.part.id]![index].options[optionIndex] = value;
                                                    },
                                                decoration: InputDecoration(
                                                  labelText:
                                                      'Option ${optionIndex + 1}',
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(
                                                      8,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              width:
                                                  8,
                                            ),
                                            IconButton(
                                              onPressed:
                                                  widget.matchingInformationDraftsByPart[widget.part.id]![index].options.length >
                                                      1
                                                  ? () {
                                                      setState(
                                                        () {
                                                          widget.matchingInformationDraftsByPart[widget.part.id]![index].options.removeAt(
                                                            optionIndex,
                                                          );
                                                        },
                                                      );
                                                    }
                                                  : null,
                                              icon: Icon(
                                                Icons
                                                    .delete_outline,
                                                color:
                                                    Colors.red,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    })),
                                    Align(
                                      alignment: Alignment
                                          .centerLeft,
                                      child: TextButton.icon(
                                        onPressed: () {
                                          setState(() {
                                            widget.matchingInformationDraftsByPart[widget.part
                                                    .id]![index]
                                                .options
                                                .add(
                                                  '',
                                                );
                                          });
                                        },
                                        icon: Icon(
                                          Icons
                                              .add_outlined,
                                        ),
                                        label: Text(
                                          'Thêm option',
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      height: 8,
                                    ),
                                    ...(widget.matchingInformationDraftsByPart[widget.part.id]![index].questions.asMap().entries.map((
                                      questionEntry,
                                    ) {
                                      final questionIndex =
                                          questionEntry
                                              .key;
                                      final questionDraft =
                                          questionEntry
                                              .value;

                                      return Padding(
                                        padding:
                                            EdgeInsets.only(
                                              bottom:
                                                  12,
                                            ),
                                        child: Container(
                                          padding:
                                              EdgeInsets.all(
                                                12,
                                              ),
                                          decoration: BoxDecoration(
                                            color: Colors
                                                .white,
                                            border: Border.all(
                                              color: Colors
                                                  .grey
                                                  .shade300,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(
                                                  8,
                                                ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment
                                                    .start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      'Câu hỏi ${questionIndex + 1}',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                  IconButton(
                                                    onPressed:
                                                        widget.matchingInformationDraftsByPart[widget.part.id]![index].questions.length >
                                                            1
                                                        ? () {
                                                            setState(
                                                              () {
                                                                widget.matchingInformationDraftsByPart[widget.part.id]![index].questions.removeAt(
                                                                  questionIndex,
                                                                );
                                                              },
                                                            );
                                                          }
                                                        : null,
                                                    icon: Icon(
                                                      Icons.delete_outline,
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(
                                                height:
                                                    8,
                                              ),
                                              TextFormField(
                                                initialValue:
                                                    questionDraft.question,
                                                onChanged:
                                                    (
                                                      value,
                                                    ) {
                                                      questionDraft.question = value;
                                                    },
                                                decoration: InputDecoration(
                                                  labelText:
                                                      'Nội dung câu hỏi',
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(
                                                      8,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                height:
                                                    10,
                                              ),
                                              TextFormField(
                                                initialValue:
                                                    questionDraft.answer,
                                                onChanged:
                                                    (
                                                      value,
                                                    ) {
                                                      questionDraft.answer = value;
                                                    },
                                                decoration: InputDecoration(
                                                  labelText:
                                                      'Đáp án',
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(
                                                      8,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    })),
                                    Align(
                                      alignment: Alignment
                                          .centerLeft,
                                      child: TextButton.icon(
                                        onPressed: () {
                                          setState(() {
                                            widget.matchingInformationDraftsByPart[widget.part
                                                    .id]![index]
                                                .questions
                                                .add(
                                                  MatchingInformationQuestionDraft(),
                                                );
                                          });
                                        },
                                        icon: Icon(
                                          Icons
                                              .add_outlined,
                                        ),
                                        label: Text(
                                          'Tạo câu hỏi',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (selectedValue ==
                                  "Multiple choice" ||
                              selectedValue ==
                                  "Choose from a list")
                            Padding(
                              padding:
                                  EdgeInsets.only(
                                    bottom: 12,
                                  ),
                              child: Container(
                                padding:
                                    EdgeInsets.all(
                                      12,
                                    ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                    color:
                                        Colors.grey,
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(
                                        8,
                                      ),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    ...(widget.multipleChoiceDraftsByPart[widget.part.id]![index].questions.asMap().entries.map((
                                      questionEntry,
                                    ) {
                                      final questionIndex =
                                          questionEntry
                                              .key;
                                      final questionDraft =
                                          questionEntry
                                              .value;

                                      return Padding(
                                        padding:
                                            EdgeInsets.only(
                                              bottom:
                                                  12,
                                            ),
                                        child: Container(
                                          padding:
                                              EdgeInsets.all(
                                                12,
                                              ),
                                          decoration: BoxDecoration(
                                            color: Colors
                                                .white,
                                            border: Border.all(
                                              color: Colors
                                                  .grey
                                                  .shade300,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(
                                                  8,
                                                ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment
                                                    .start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      "Câu hỏi ${questionIndex + 1}",
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                  IconButton(
                                                    onPressed:
                                                        widget.multipleChoiceDraftsByPart[widget.part.id]![index].questions.length >
                                                            1
                                                        ? () {
                                                            setState(
                                                              () {
                                                                widget.multipleChoiceDraftsByPart[widget.part.id]![index].questions.removeAt(
                                                                  questionIndex,
                                                                );
                                                              },
                                                            );
                                                          }
                                                        : null,
                                                    icon: Icon(
                                                      Icons.delete_outline,
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(
                                                height:
                                                    8,
                                              ),
                                              TextFormField(
                                                initialValue:
                                                    questionDraft.question,
                                                onChanged:
                                                    (
                                                      value,
                                                    ) {
                                                      questionDraft.question = value;
                                                    },
                                                decoration: InputDecoration(
                                                  labelText:
                                                      "Câu hỏi",
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(
                                                      8,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                height:
                                                    10,
                                              ),
                                              ...(questionDraft.options.asMap().entries.map((
                                                optionEntry,
                                              ) {
                                                final optionIndex =
                                                    optionEntry.key;
                                                final optionValue =
                                                    optionEntry.value;
                                                final isCorrect = questionDraft.correctOptionIndices.contains(
                                                  optionIndex,
                                                );

                                                return Padding(
                                                  padding: EdgeInsets.only(
                                                    bottom: 8,
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          if (selectedValue ==
                                                              "Multiple choice")
                                                            Radio<
                                                              int
                                                            >(
                                                              value: optionIndex,
                                                              groupValue: questionDraft.correctOptionIndices.isNotEmpty
                                                                  ? questionDraft.correctOptionIndices.first
                                                                  : -1,
                                                              onChanged:
                                                                  (
                                                                    value,
                                                                  ) {
                                                                    setState(
                                                                      () {
                                                                        questionDraft.correctOptionIndices = {
                                                                          value!,
                                                                        };
                                                                      },
                                                                    );
                                                                  },
                                                            )
                                                          else if (selectedValue ==
                                                              "Choose from a list")
                                                            Checkbox(
                                                              value: isCorrect,
                                                              onChanged:
                                                                  (
                                                                    value,
                                                                  ) {
                                                                    setState(
                                                                      () {
                                                                        if (value ==
                                                                            true) {
                                                                          questionDraft.correctOptionIndices.add(
                                                                            optionIndex,
                                                                          );
                                                                        } else {
                                                                          questionDraft.correctOptionIndices.remove(
                                                                            optionIndex,
                                                                          );
                                                                        }
                                                                      },
                                                                    );
                                                                  },
                                                            )
                                                          else
                                                            SizedBox(
                                                              width: 24,
                                                            ),
                                                          SizedBox(
                                                            width: 8,
                                                          ),
                                                          Expanded(
                                                            child: TextFormField(
                                                              initialValue: optionValue,
                                                              onChanged:
                                                                  (
                                                                    value,
                                                                  ) {
                                                                    questionDraft.options[optionIndex] = value;
                                                                  },
                                                              decoration: InputDecoration(
                                                                labelText: "Phương án ${optionIndex + 1}",
                                                                border: OutlineInputBorder(
                                                                  borderRadius: BorderRadius.circular(
                                                                    8,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            width: 8,
                                                          ),
                                                          IconButton(
                                                            onPressed:
                                                                questionDraft.options.length >
                                                                    2
                                                                ? () {
                                                                    setState(
                                                                      () {
                                                                        questionDraft.correctOptionIndices.remove(
                                                                          optionIndex,
                                                                        );
                                                                        questionDraft.options.removeAt(
                                                                          optionIndex,
                                                                        );
                                                                        // Cập nhật lại indices
                                                                        questionDraft.correctOptionIndices = questionDraft.correctOptionIndices
                                                                            .where(
                                                                              (
                                                                                idx,
                                                                              ) =>
                                                                                  idx <
                                                                                  questionDraft.options.length,
                                                                            )
                                                                            .toSet();
                                                                      },
                                                                    );
                                                                  }
                                                                : null,
                                                            icon: Icon(
                                                              Icons.delete_outline,
                                                              color: Colors.red,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              })),
                                              Align(
                                                alignment:
                                                    Alignment.centerLeft,
                                                child: TextButton.icon(
                                                  onPressed: () {
                                                    setState(
                                                      () {
                                                        questionDraft.options.add(
                                                          '',
                                                        );
                                                      },
                                                    );
                                                  },
                                                  icon: Icon(
                                                    Icons.add_outlined,
                                                  ),
                                                  label: Text(
                                                    "Thêm phương án",
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    })),
                                    Align(
                                      alignment: Alignment
                                          .centerLeft,
                                      child: TextButton.icon(
                                        onPressed: () {
                                          setState(() {
                                            widget.multipleChoiceDraftsByPart[widget.part
                                                    .id]![index]
                                                .questions
                                                .add(
                                                  MultipleChoiceQuestionDraft(),
                                                );
                                          });
                                        },
                                        icon: Icon(
                                          Icons
                                              .add_outlined,
                                        ),
                                        label: Text(
                                          "Thêm câu hỏi",
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (selectedValue ==
                                  "Multiple choice" ||
                              selectedValue ==
                                  "Choose from a list")
                            Padding(
                              padding:
                                  EdgeInsets.only(
                                    bottom: 12,
                                  ),
                              child: Container(
                                padding:
                                    EdgeInsets.all(
                                      12,
                                    ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                    color:
                                        Colors.grey,
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(
                                        8,
                                      ),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    Text(
                                      'Instruction',
                                      style: TextStyle(
                                        fontWeight:
                                            FontWeight
                                                .w600,
                                      ),
                                    ),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    QuillSimpleToolbar(
                                      controller:
                                          widget.instructionTextControllersByPart[widget.part
                                              .id]![index],
                                    ),
                                    Divider(
                                      color:
                                          Colors.grey,
                                      thickness: 1,
                                      height: 20,
                                    ),
                                    SizedBox(
                                      height: 160,
                                      child: QuillEditor(
                                        controller:
                                            widget.instructionTextControllersByPart[widget.part
                                                .id]![index],
                                        scrollController:
                                            ScrollController(),
                                        focusNode:
                                            FocusNode(),
                                        config: QuillEditorConfig(
                                          padding:
                                              EdgeInsets.all(
                                                10,
                                              ),
                                          autoFocus:
                                              false,
                                          expands:
                                              false,
                                          placeholder:
                                              'Nhập instruction...',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (selectedValue ==
                                  "T/F/NG" ||
                              selectedValue ==
                                  "Y/N/NG")
                            Padding(
                              padding:
                                  EdgeInsets.only(
                                    bottom: 12,
                                  ),
                              child: Container(
                                padding:
                                    EdgeInsets.all(
                                      12,
                                    ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                    color:
                                        Colors.grey,
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(
                                        8,
                                      ),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    Text(
                                      'Instruction',
                                      style: TextStyle(
                                        fontWeight:
                                            FontWeight
                                                .w600,
                                      ),
                                    ),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    QuillSimpleToolbar(
                                      controller:
                                          widget.instructionTextControllersByPart[widget.part
                                              .id]![index],
                                    ),
                                    Divider(
                                      color:
                                          Colors.grey,
                                      thickness: 1,
                                      height: 20,
                                    ),
                                    SizedBox(
                                      height: 160,
                                      child: QuillEditor(
                                        controller:
                                            widget.instructionTextControllersByPart[widget.part
                                                .id]![index],
                                        scrollController:
                                            ScrollController(),
                                        focusNode:
                                            FocusNode(),
                                        config: QuillEditorConfig(
                                          padding:
                                              EdgeInsets.all(
                                                10,
                                              ),
                                          autoFocus:
                                              false,
                                          expands:
                                              false,
                                          placeholder:
                                              'Nhập instruction...',
                                        ),
                                      ),
                                    ),
                                    ...(widget.trueFalseNotGivenDraftsByPart[widget.part.id]![index].questions.asMap().entries.map((
                                      questionEntry,
                                    ) {
                                      final questionIndex =
                                          questionEntry
                                              .key;
                                      final questionDraft =
                                          questionEntry
                                              .value;
                                      final answerOptions =
                                          selectedValue ==
                                              "T/F/NG"
                                          ? [
                                              "TRUE",
                                              "FALSE",
                                              "NOT GIVEN",
                                            ]
                                          : [
                                              "YES",
                                              "NO",
                                              "NOT GIVEN",
                                            ];

                                      return Padding(
                                        padding:
                                            EdgeInsets.only(
                                              bottom:
                                                  12,
                                            ),
                                        child: Container(
                                          padding:
                                              EdgeInsets.all(
                                                12,
                                              ),
                                          decoration: BoxDecoration(
                                            color: Colors
                                                .white,
                                            border: Border.all(
                                              color: Colors
                                                  .grey
                                                  .shade300,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(
                                                  8,
                                                ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment
                                                    .start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      "Câu hỏi ${questionDraft.questionNo}",
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                  IconButton(
                                                    onPressed:
                                                        widget.trueFalseNotGivenDraftsByPart[widget.part.id]![index].questions.length >
                                                            1
                                                        ? () {
                                                            setState(
                                                              () {
                                                                widget.trueFalseNotGivenDraftsByPart[widget.part.id]![index].questions.removeAt(
                                                                  questionIndex,
                                                                );
                                                                _renumberTrueFalseNotGivenQuestions(
                                                                  partId: widget.part.id,
                                                                  questionTypeIndex: index,
                                                                );
                                                              },
                                                            );
                                                          }
                                                        : null,
                                                    icon: Icon(
                                                      Icons.delete_outline,
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(
                                                height:
                                                    8,
                                              ),
                                              TextFormField(
                                                initialValue:
                                                    questionDraft.statement,
                                                onChanged:
                                                    (
                                                      value,
                                                    ) {
                                                      questionDraft.statement = value;
                                                    },
                                                decoration: InputDecoration(
                                                  labelText:
                                                      "Statement",
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(
                                                      8,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                height:
                                                    10,
                                              ),
                                              DropdownButtonFormField<
                                                String
                                              >(
                                                value:
                                                    questionDraft.correctAnswer,
                                                decoration: InputDecoration(
                                                  labelText:
                                                      "Đáp án đúng",
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(
                                                      8,
                                                    ),
                                                  ),
                                                ),
                                                items: answerOptions
                                                    .map(
                                                      (
                                                        option,
                                                      ) =>
                                                          DropdownMenuItem<
                                                            String
                                                          >(
                                                            value: option,
                                                            child: Text(
                                                              option,
                                                            ),
                                                          ),
                                                    )
                                                    .toList(),
                                                onChanged:
                                                    (
                                                      value,
                                                    ) {
                                                      setState(
                                                        () {
                                                          questionDraft.correctAnswer = value;
                                                        },
                                                      );
                                                    },
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    })),
                                    Align(
                                      alignment: Alignment
                                          .centerLeft,
                                      child: TextButton.icon(
                                        onPressed: () {
                                          setState(() {
                                            final questions = widget.trueFalseNotGivenDraftsByPart[widget.part.id]![index].questions;
                                            questions.add(
                                              TrueFalseNotGivenQuestionDraft(
                                                questionNo: questions.length + 1,
                                              ),
                                            );
                                            _renumberTrueFalseNotGivenQuestions(
                                              partId: widget.part.id,
                                              questionTypeIndex: index,
                                            );
                                          });
                                        },
                                        icon: Icon(
                                          Icons
                                              .add_outlined,
                                        ),
                                        label: Text(
                                          "Thêm câu hỏi",
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (index !=
                              (widget.questionTypeSelectionsByPart[widget.part
                                              .id]
                                          ?.length ??
                                      0) -
                                  1)
                            Padding(
                              padding:
                                  EdgeInsets.only(
                                    bottom: 12,
                                  ),
                              child: Divider(
                                color: Colors.grey,
                                thickness: 1,
                                height: 1,
                              ),
                            ),
                        ],
                      );
                    })),

                Row(
                  children: [
                    Expanded(child: Container()),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          widget.questionTypeSelectionsByPart[widget.part
                                  .id] ??=
                              [];
                          widget.questionTypeSelectionsByPart[widget.part
                                  .id]!
                              .add(null);
                          widget.multipleChoiceDraftsByPart[widget.part
                                  .id]!
                              .add(
                                MultipleChoiceDraft(),
                              );
                          widget.trueFalseNotGivenDraftsByPart[widget.part
                                  .id]!
                              .add(
                                TrueFalseNotGivenDraft(),
                              );
                          widget.shortAnswerDraftsByPart[widget.part
                                  .id]!
                              .add(
                                ShortAnswerDraft(),
                              );
                          widget.matchingInformationDraftsByPart[widget.part
                                  .id]!
                              .add(
                                MatchingInformationDraft(),
                              );
                          widget.completionMaterialSelectionsByPart[widget.part
                                  .id]!
                              .add(null);
                          widget.labelingOptionsByPart[widget.part
                                  .id]!
                              .add(['']);
                          widget.materialTextControllersByPart[widget.part
                                  .id]!
                              .add(
                                QuillController.basic(),
                              );
                          widget.instructionTextControllersByPart[widget.part
                                  .id]!
                              .add(
                                QuillController.basic(),
                              );
                          widget.blankQuestionNoControllersByPart[widget.part
                                  .id]!
                              .add(
                                TextEditingController(),
                              );
                          widget.blankCorrectAnswerControllersByPart[widget.part
                                  .id]!
                              .add(
                                TextEditingController(),
                              );
                          widget.completionBlankAnswersByPart[widget.part
                                  .id]!
                              .add([]);
                          widget.part.questionTypes.add(
                            QuestionTypeModel(
                              id: widget.part
                                  .questionTypes
                                  .length,
                              name: '',
                            ),
                          );
                        });
                      },
                      style: ButtonStyle(
                        backgroundColor:
                            WidgetStateProperty.all(
                              Color(0xFF1E40AF),
                            ),
                        foregroundColor:
                            WidgetStateProperty.all(
                              Colors.white,
                            ),
                        overlayColor:
                            WidgetStateProperty.all(
                              Colors.transparent,
                            ),
                        minimumSize:
                            WidgetStateProperty.all(
                              Size(180, 50),
                            ),
                        elevation:
                            WidgetStateProperty.all(
                              0,
                            ),
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                                  4,
                                ),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.add_outlined,
                            size: 20,
                          ),
                          SizedBox(width: 4),
                          Text('Thêm dạng câu hỏi'),
                        ],
                      ),
                    ),
                    Expanded(child: Container()),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}