import 'package:english_center_fe/constants/student_tests/student_tests_list.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../exceptions/unauthorized_exception.dart';
import '../../widgets/layout/layout.dart';
import '../../widgets/test/audio_player_widget.dart';
import '../../widgets/test/countdown_timer.dart';
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

  Future<Map<String, dynamic>> _loadTestInfo(String testId) async {
    final response = await getTestsInfo(testId);
    isTimer = response['type'] == 'Reading' || response['type'] == 'Writting';
    return getTestsInfo(testId);
  }

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadTestInfo(widget.testId);
  }

  @override
  void dispose() {
    _verticalController.dispose();
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
                      final partData = parts.where((part) => int.parse(part['number'].toString()) == activeSection).first;
                      if (result['type'] == 'Listening') {
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
                      else if (result['type'] == 'Reading') {
                        return Column(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.all(20),
                                      child: PassageText(
                                        text: partData['text'] ?? '',
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(),
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