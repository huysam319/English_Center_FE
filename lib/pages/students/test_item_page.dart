import 'package:english_center_fe/constants/student_tests/student_tests_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html/flutter_html.dart' as html;
import 'package:flutter_quill/flutter_quill.dart';
import 'package:go_router/go_router.dart';

import '../../exceptions/unauthorized_exception.dart';
import '../../models/writing_answer_model.dart';
import '../../widgets/layout/layout.dart';
import '../../widgets/test/answer_box/matching_option.dart';
import '../../widgets/test/answer_box/tfng_ynng.dart';
import '../../widgets/test/audio_player_widget.dart';
import '../../widgets/test/completion_text.dart';
import '../../widgets/test/countdown_timer.dart';
import '../../widgets/test/labeling_text.dart';
import '../../widgets/test/passage_text.dart';
import '../../widgets/test/section_navbar.dart';

class TestItemPage extends StatefulWidget {
  final String testId;

  const TestItemPage({super.key, required this.testId});

  @override
  State<TestItemPage> createState() => _TestItemPageState();
}

class _TestItemPageState extends State<TestItemPage> {
  late Future<Map<String, dynamic>> _dataFuture;
  final ScrollController _verticalController = ScrollController();
  final GlobalKey<CountdownTimerState> _timerKey = GlobalKey<CountdownTimerState>();

  int activeSection = 1;
  bool isTimer = false;
  List<bool> checkboxValues = List.filled(5, false);
  List<String?> selectedValue = List.filled(4, null);
  List<dynamic> answerModels = [];

  int countWords(String text) {
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }

  Future<Map<String, dynamic>> _loadTestInfo(String testId) async {
    final response = await getTestsInfo(testId);
    setState(() {
      isTimer = response['skill'] == 'Reading' || response['skill'] == 'Writing';
    });
      
    if (response['skill'] == 'Writing') {
      final parts = response['parts'] as List;
      answerModels = List.generate(
        parts.length,
        (index) => WritingAnswerModel(partNumber: parts[index]['partNumber']),
      );
      for (var model in answerModels) {
        if (model is WritingAnswerModel) {
          _addWordCountListener(model);
        }
      }
    }
    return response;
  }

  void _addWordCountListener(WritingAnswerModel model) {
    model.answerController.addListener(() {
      final text = model.answerController.document.toPlainText();
      final count = countWords(text);
      model.wordCountNotifier.value = count;
    });
  }

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadTestInfo(widget.testId);
  }

  @override
  void dispose() {
    _verticalController.dispose();
    for (var model in answerModels) {
      if (model is WritingAnswerModel) {
        model.answerController.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Title(
      color: Colors.black,
      title: "Thông tin đề thi",
      child: SiteLayout(
        menuNo: 6,
        content: Container(
          color: Colors.white,
          child: Column(
            children: [
              isTimer
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.access_time_outlined),
                      SizedBox(width: 5),
                      CountdownTimer(key: _timerKey, seconds: 3600,),
                    ],
                  )
                : Container(),
              Expanded(
                child: FutureBuilder<Map<String, dynamic>>(
                  future: _dataFuture,
                  builder:(context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      final err = snapshot.error;
                      if (err is UnauthorizedException) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) context.go('/login');
                        });
                        return SizedBox.shrink();
                      }
                      return Center(
                        child: Text('Lỗi tải thông tin đề thi'),
                      );
                    } else if (snapshot.hasData) {
                      final result = snapshot.data!;
                      final parts = result['parts'] as List;

                      final partData = parts.where((part) => int.parse(part['partNumber'].toString()) == activeSection).first;
                      if (result['skill'] == 'Listening') {
                        return Column(
                          children: [
                            AudioPlayerWidget(url: partData['audio'] ?? ''),
                            Expanded(
                              child: Container(),
                            ),
                            Row(
                              children: [
                                for (var part in parts)
                                  Expanded(
                                    child: SectionNavbar(
                                      isActive: activeSection == part['number'],
                                      label: "Part", 
                                      number: part['number'],
                                      onChanged: () {
                                        setState(() {
                                          activeSection = part['number'];
                                        });
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        );
                      }
                      else if (result['skill'] == 'Reading') {
                        return Column(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.all(20),
                                      child: PassageText(
                                        key: ValueKey('passage-${widget.testId}-${partData['number']}'),
                                        text: partData['text'] ?? '',
                                        highlightStorageKey: 'passage-highlight-${widget.testId}-${partData['number']}',
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(vertical: 20, horizontal: 5),
                                      child:  ListView(
                                        children: [
                                          Text(
                                            "Questions 1-7: Do the following statements agree with the information given in the passage? In boxes 1-7 write",
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          SizedBox(height: 10),
                                          Text(
                                            " TRUE – if the statement agrees with the information;",
                                            style: TextStyle(fontSize: 15),
                                          ),
                                          Text(
                                            " FALSE – if the statement contradicts the information;",
                                            style: TextStyle(fontSize: 16),
                                          ),
                                          Text(
                                            " NOT GIVEN – if there is no information on this.",
                                            style: TextStyle(fontSize: 16),
                                          ),

                                          SizedBox(height: 10),

                                          Row(
                                            children: [
                                              TFNGYNNGAnswerBox(
                                                questionNo: 1, 
                                                isTFNG: true, 
                                                answerController: TextEditingController(),
                                              ),
                                              SizedBox(width: 10),
                                              Expanded(
                                                child: Text('Polar bears suffer from various health problems due to the build-up of fat under their skin.'),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 5),
                                          Row(
                                            children: [
                                              TFNGYNNGAnswerBox(
                                                questionNo: 2, 
                                                isTFNG: true, 
                                                answerController: TextEditingController(),
                                              ),
                                              SizedBox(width: 10),
                                              Expanded(
                                                child: Text('The study done by Liu and his colleagues compared different groups of polar bears.'),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 5),
                                          Row(
                                            children: [
                                              TFNGYNNGAnswerBox(
                                                questionNo: 3, 
                                                isTFNG: true, 
                                                answerController: TextEditingController(),
                                              ),
                                              SizedBox(width: 10),
                                              Expanded(
                                                child: Text('Liu and colleagues were the first researchers to compare polar bears and brown bears genetically.'),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 5),
                                          Row(
                                            children: [
                                              TFNGYNNGAnswerBox(
                                                questionNo: 4, 
                                                isTFNG: true, 
                                                answerController: TextEditingController(),
                                              ),
                                              SizedBox(width: 10),
                                              Expanded(
                                                child: Text('Polar bears are able to control their levels of ‘bad’ cholesterol by genetic means.'),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 5),
                                          Row(
                                            children: [
                                              TFNGYNNGAnswerBox(
                                                questionNo: 5, 
                                                isTFNG: true, 
                                                answerController: TextEditingController(),
                                              ),
                                              SizedBox(width: 10),
                                              Expanded(
                                                child: Text('Female polar bears are able to survive for about six months without food.'),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 5),
                                          Row(
                                            children: [
                                              TFNGYNNGAnswerBox(
                                                questionNo: 6, 
                                                isTFNG: true, 
                                                answerController: TextEditingController(),
                                              ),
                                              SizedBox(width: 10),
                                              Expanded(
                                                child: Text('It was found that the bones of female polar bears were very weak when they came out of their dens in spring.'),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 5),
                                          Row(
                                            children: [
                                              TFNGYNNGAnswerBox(
                                                questionNo: 7, 
                                                isTFNG: true, 
                                                answerController: TextEditingController(),
                                              ),
                                              SizedBox(width: 10),
                                              Expanded(
                                                child: Text('The polar bear’s mechanism for increasing bone density could also be used by people one day.'),
                                              ),
                                            ],
                                          ),

                                          SizedBox(height: 10),

                                          Text(
                                            'Questions 8-13: Complete the table below. Choose ONE WORD ONLY from the passage for each answer.',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          SizedBox(height: 10),

                                          CompletionText(text: """<p><b>Reasons why polar bears should be protected</b><br><br>People think of bears as unintelligent and <blank id="8"></blank>.<br>However, this may not be correct. For example:
                                              <ul style="padding: 0; margin: 0;"><li>In Tennoji Zoo, a bear has been seen using a branch as a <blank id="9"></blank>. This allowed him to knock down some <blank id="10"></blank>.
                                              <li>A wild polar bear worked out a method of reaching a platform where a <blank id="11"></blank> was located.
                                              <li>Polar bears have displayed behaviour such as conscious manipulation of objects and activity similar to a <blank id="12"></blank>.</ul>
                                              Bears may also display emotions. For example:
                                              <ul style="padding: 0; margin: 0;"><li>They may make movements suggesting <blank id="13"></blank>&nbsp;if disappointed when hunting.
                                              <li>They may form relationships with other species.</ul></p>"""
                                          ),

                                          SizedBox(height: 10),

                                          Text(
                                            'Questions 25-26: Which TWO of the following points does the writer make about King Djoser?',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),

                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Checkbox(
                                                value: checkboxValues[0],
                                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                visualDensity: VisualDensity(
                                                  horizontal: -2,
                                                  vertical: -4,
                                                ),
                                                onChanged: (value) {
                                                  setState(() {
                                                    checkboxValues[0] = value!;
                                                  });
                                                },
                                              ),
                                              Expanded(
                                                child: Text(
                                                  'Initially he had to be persuaded to build in stone rather than clay.',
                                                  style: TextStyle(
                                                    height: 1.2,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Checkbox(
                                                value: checkboxValues[1],
                                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                visualDensity: VisualDensity(
                                                  horizontal: -2,
                                                  vertical: -4,
                                                ),
                                                onChanged: (value) {
                                                  setState(() {
                                                    checkboxValues[1] = value!;
                                                  });
                                                },
                                              ),
                                              Expanded(
                                                child: Text(
                                                  'There is disagreement concerning the length of his reign.',
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Checkbox(
                                                value: checkboxValues[2],
                                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                visualDensity: VisualDensity(
                                                  horizontal: -2,
                                                  vertical: -4,
                                                ),
                                                onChanged: (value) {
                                                  setState(() {
                                                    checkboxValues[2] = value!;
                                                  });
                                                },
                                              ),
                                              Expanded(
                                                child: Text(
                                                  '''He failed to appreciate Imhotep's part in the design of the Step Pyramid.''',
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Checkbox(
                                                value: checkboxValues[3],
                                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                visualDensity: VisualDensity(
                                                  horizontal: -2,
                                                  vertical: -4,
                                                ),
                                                onChanged: (value) {
                                                  setState(() {
                                                    checkboxValues[3] = value!;
                                                  });
                                                },
                                              ),
                                              Expanded(
                                                child: Text(
                                                  'A few of his possessions were still in his tomb when archaeologists found it.',
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Checkbox(
                                                value: checkboxValues[4],
                                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                visualDensity: VisualDensity(
                                                  horizontal: -2,
                                                  vertical: -4,
                                                ),
                                                onChanged: (value) {
                                                  setState(() {
                                                    checkboxValues[4] = value!;
                                                  });
                                                },
                                              ),
                                              Expanded(
                                                child: Text(
                                                  'He criticised the design and construction of other pyramids in Egypt.',
                                                ),
                                              ),
                                            ],
                                          ),

                                          SizedBox(height: 10,),

                                          Text(
                                            'Questions 27-30: Choose the correct answer.',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          SizedBox(height: 4,),

                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              RichText(
                                                text: TextSpan(
                                                  text: '27',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Color(0xFF1E40AF),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  children: [
                                                    TextSpan(text: '  '),
                                                    TextSpan(
                                                      text: 'The first paragraph tells us about',
                                                      style: TextStyle(
                                                        color: Colors.black,
                                                        fontWeight: FontWeight.normal,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              SizedBox(height: 2),
                                              ...[
                                                '''the kinds of jobs that will be most affected by the growth of AI''',
                                                '''the extent to which AI will alter the nature of the work that people do''',
                                                '''the proportion of the world's labour force who will have jobs in AI in the future''',
                                                '''the difference between ways that embodied and disembodied AI will impact on workers''',
                                              ].map((option) {
                                                return Row(
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  children: [
                                                    Transform.scale(
                                                      scale: 0.8,
                                                      child: Radio<String>(
                                                        visualDensity: VisualDensity(
                                                          horizontal: -2,
                                                          vertical: -4,
                                                        ),
                                                        value: option,
                                                        groupValue: selectedValue[0],
                                                        onChanged: (value) {
                                                          setState(() {
                                                            selectedValue[0] = value;
                                                          });
                                                        },
                                                      ),
                                                    ),
                                                    Expanded(child: Text(option)),
                                                  ],
                                                );
                                              }),
                                            ],
                                          ),
                                          SizedBox(height: 4),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              RichText(
                                                text: TextSpan(
                                                  text: '28',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Color(0xFF1E40AF),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  children: [
                                                    TextSpan(text: '  '),
                                                    TextSpan(
                                                      text: 'The first paragraph tells us about',
                                                      style: TextStyle(
                                                        color: Colors.black,
                                                        fontWeight: FontWeight.normal,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              SizedBox(height: 2),
                                              ...[
                                                '''the kinds of jobs that will be most affected by the growth of AI''',
                                                '''the extent to which AI will alter the nature of the work that people do''',
                                                '''the proportion of the world's labour force who will have jobs in AI in the future''',
                                                '''the difference between ways that embodied and disembodied AI will impact on workers''',
                                              ].map((option) {
                                                return Row(
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  children: [
                                                    Transform.scale(
                                                      scale: 0.8,
                                                      child: Radio<String>(
                                                        visualDensity: VisualDensity(
                                                          horizontal: -2,
                                                          vertical: -4,
                                                        ),
                                                        value: option,
                                                        groupValue: selectedValue[1],
                                                        onChanged: (value) {
                                                          setState(() {
                                                            selectedValue[1] = value;
                                                          });
                                                        },
                                                      ),
                                                    ),
                                                    Expanded(child: Text(option)),
                                                  ],
                                                );
                                              }),
                                            ],
                                          ),
                                          SizedBox(height: 4),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              RichText(
                                                text: TextSpan(
                                                  text: '29',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Color(0xFF1E40AF),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  children: [
                                                    TextSpan(text: '  '),
                                                    TextSpan(
                                                      text: 'The first paragraph tells us about',
                                                      style: TextStyle(
                                                        color: Colors.black,
                                                        fontWeight: FontWeight.normal,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              SizedBox(height: 2),
                                              ...[
                                                '''the kinds of jobs that will be most affected by the growth of AI''',
                                                '''the extent to which AI will alter the nature of the work that people do''',
                                                '''the proportion of the world's labour force who will have jobs in AI in the future''',
                                                '''the difference between ways that embodied and disembodied AI will impact on workers''',
                                              ].map((option) {
                                                return Row(
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  children: [
                                                    Transform.scale(
                                                      scale: 0.8,
                                                      child: Radio<String>(
                                                        visualDensity: VisualDensity(
                                                          horizontal: -2,
                                                          vertical: -4,
                                                        ),
                                                        value: option,
                                                        groupValue: selectedValue[2],
                                                        onChanged: (value) {
                                                          setState(() {
                                                            selectedValue[2] = value;
                                                          });
                                                        },
                                                      ),
                                                    ),
                                                    Expanded(child: Text(option)),
                                                  ],
                                                );
                                              }),
                                            ],
                                          ),
                                          SizedBox(height: 4),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              RichText(
                                                text: TextSpan(
                                                  text: '30',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Color(0xFF1E40AF),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  children: [
                                                    TextSpan(text: '  '),
                                                    TextSpan(
                                                      text: 'The first paragraph tells us about',
                                                      style: TextStyle(
                                                        color: Colors.black,
                                                        fontWeight: FontWeight.normal,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              SizedBox(height: 2),
                                              ...[
                                                '''the kinds of jobs that will be most affected by the growth of AI''',
                                                '''the extent to which AI will alter the nature of the work that people do''',
                                                '''the proportion of the world's labour force who will have jobs in AI in the future''',
                                                '''the difference between ways that embodied and disembodied AI will impact on workers''',
                                              ].map((option) {
                                                return Row(
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  children: [
                                                    Transform.scale(
                                                      scale: 0.8,
                                                      child: Radio<String>(
                                                        visualDensity: VisualDensity(
                                                          horizontal: -2,
                                                          vertical: -4,
                                                        ),
                                                        value: option,
                                                        groupValue: selectedValue[3],
                                                        onChanged: (value) {
                                                          setState(() {
                                                            selectedValue[3] = value;
                                                          });
                                                        },
                                                      ),
                                                    ),
                                                    Expanded(child: Text(option)),
                                                  ],
                                                );
                                              }),
                                            ],
                                          ),

                                          SizedBox(height: 10),

                                          Text(
                                            'Questions 31-34: Complete the summary using the list of words below.',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          SizedBox(height: 4),
                                          LabelingText(
                                            text: """<p><div style="text-align: center;"><b>The 'algorithmication' of jobs</b></div>Stella Panchidi of Cambridge Judge Business School has been focusing on the 'algorithmication' of jobs which rely not on production but on <blank id="31"></blank>.<br><br>
                                                While monitoring a telecommunications company, Pachidi observed a growing <blank id="32"></blank> on the recommendations made by AI, as workers begin to learn through the 'algorithm's eyes'. Meanwhile, staff are deterred from experimenting and using their own <blank id="33"></blank>, and therefore preventing from achieving innovation.<br><br>
                                                To avoid the kind of situations which Panchidi observed, researchers are trying to make AI's decision-making process easier to comprehend, and to increase users' <blank id="34"></blank> with regard to the technology.</p>""",
                                          ),
                                          SizedBox(height: 4),
                                          Wrap(
                                            spacing: 4,
                                            runSpacing: 4,
                                            children: [
                                              MatchingOption(content: "pressure"),
                                              MatchingOption(content: "satisfaction"),
                                              MatchingOption(content: "intuition"),
                                              MatchingOption(content: "promotion"),
                                              MatchingOption(content: "reliance"),
                                              MatchingOption(content: "confidence"),
                                              MatchingOption(content: "information"),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ), 
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                for (var part in parts)
                                  Expanded(
                                    child: SectionNavbar(
                                      isActive: activeSection == part['number'],
                                      label: "Passage", 
                                      number: part['number'],
                                      onChanged: () {
                                        setState(() {
                                          activeSection = part['number'];
                                        });
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        );
                      }
                      else if (result['skill'] == "Writing") {
                        return Column(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    // Text(partData['text'] ?? 'No title available'),
                                    Html(
                                      data: partData['text'] ?? 'No title available',
                                      style: {
                                        "body": html.Style(fontSize: FontSize(16.0)),
                                      },
                                    ),
                                    SizedBox(height: 10,),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border.all(
                                          color: Colors.black,
                                          width: 1,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: QuillEditor(
                                        controller: answerModels.firstWhere((model) => model.partNumber == activeSection).answerController,
                                        scrollController: ScrollController(),
                                        focusNode: FocusNode(),
                                        config: QuillEditorConfig(
                                          padding: EdgeInsets.all(10),
                                          autoFocus: false,
                                          expands: false,
                                          placeholder: 'Add your answer here...',
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 5,),
                                    ValueListenableBuilder<int>(
                                      valueListenable: answerModels.firstWhere((model) => model.partNumber == activeSection)
                                          .wordCountNotifier,
                                      builder: (context, value, child) {
                                        return Align(
                                          alignment: Alignment.centerRight,
                                          child: Text('Word count: $value',),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                for (var part in parts)
                                  Expanded(
                                    child: SectionNavbar(
                                      isActive: activeSection == part['partNumber'],
                                      label: "Task", 
                                      number: part['partNumber'],
                                      onChanged: () {
                                        setState(() {
                                          activeSection = part['partNumber'];
                                        });
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        );
                      }
                      else {
                        return Container();
                      }
                    } else {
                      return Center(child: Text('No data available'));
                    }
                  }
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}