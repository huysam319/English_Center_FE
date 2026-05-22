import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:universal_html/html.dart' as html;

import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/layout/layout.dart';

class AiReadingStudentPage extends StatefulWidget {
  const AiReadingStudentPage({super.key, this.menuOrder = 5});

  /// Sidebar order to highlight when this page is shown. Defaults to 5
  /// ("Bài tập của bạn") vì bài đọc AI được giao thuộc nhóm bài tập trên lớp.
  final int menuOrder;

  @override
  State<AiReadingStudentPage> createState() => _AiReadingStudentPageState();
}

class _AiReadingStudentPageState extends State<AiReadingStudentPage> {
  Timer? _refreshTimer;
  Timer? _deadlineTimer;
  List<Map<String, dynamic>> _assignments = [];
  List<Map<String, dynamic>> _results = [];
  bool _loading = true;
  bool _refreshing = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _refreshData(showLoading: true);
    _refreshTimer = Timer.periodic(
      Duration(seconds: 15),
      (_) => _refreshData(),
    );
    _deadlineTimer = Timer.periodic(
      Duration(seconds: 1),
      (_) => _applyDeadlineLocks(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _deadlineTimer?.cancel();
    super.dispose();
  }

  Future<Map<String, dynamic>> _loadData() async {
    final assignmentsResponse = await ApiService.get(
      '/identity/ai-reading-assignments/student',
      token: authService.accessToken,
    );
    final resultsResponse = await ApiService.get(
      '/identity/ai-reading-assignments/student/results',
      token: authService.accessToken,
    );
    return {
      'assignments': _resultList(assignmentsResponse.body),
      'results': _resultList(resultsResponse.body),
    };
  }

  List<Map<String, dynamic>> _resultList(String body) {
    final decoded = jsonDecode(body);
    if (decoded is Map) {
      final result = decoded['result'];
      final rawList = result is Map ? result['content'] : result;
      if (rawList is List) {
        return rawList
            .whereType<Map>()
            .map((item) => item.map((key, value) => MapEntry('$key', value)))
            .toList();
      }
    }
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((item) => item.map((key, value) => MapEntry('$key', value)))
          .toList();
    }
    return [];
  }

  Future<void> _refreshData({bool showLoading = false}) async {
    if (_refreshing) return;
    if (showLoading && mounted) {
      setState(() {
        _loading = true;
        _loadError = null;
      });
    }

    _refreshing = true;
    try {
      final data = await _loadData();
      if (!mounted) return;
      setState(() {
        _assignments = data['assignments'] as List<Map<String, dynamic>>;
        _results = data['results'] as List<Map<String, dynamic>>;
        _loading = false;
        _loadError = null;
      });
      _applyDeadlineLocks();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = e.toString();
      });
    } finally {
      _refreshing = false;
    }
  }

  void _applyDeadlineLocks() {
    if (!mounted || _assignments.isEmpty) return;
    final now = DateTime.now();
    var changed = false;
    final updated = _assignments.map((assignment) {
      final dueAt = DateTime.tryParse(assignment['dueAt']?.toString() ?? '');
      if (dueAt == null || assignment['locked'] == true) return assignment;
      if (!now.isBefore(dueAt.toLocal())) {
        changed = true;
        return {...assignment, 'locked': true};
      }
      return assignment;
    }).toList();
    if (changed) {
      setState(() {
        _assignments = updated;
      });
    }
  }

  void _upsertAssignment(Map<String, dynamic> assignment) {
    final id = assignment['id']?.toString();
    if (id == null) return;
    final index = _assignments.indexWhere(
      (item) => item['id']?.toString() == id,
    );
    setState(() {
      if (index >= 0) {
        _assignments[index] = {..._assignments[index], ...assignment};
      } else {
        _assignments = [assignment, ..._assignments];
      }
    });
    _applyDeadlineLocks();
  }

  void _upsertResult(Map<String, dynamic> result) {
    final id = result['id']?.toString();
    if (id == null) return;
    final index = _results.indexWhere((item) => item['id']?.toString() == id);
    setState(() {
      if (index >= 0) {
        _results[index] = {..._results[index], ...result};
      } else {
        _results = [result, ..._results];
      }
    });
  }

  List<Map<String, dynamic>> _resourceList(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => item.map((key, value) => MapEntry('$key', value)))
          .toList();
    }
    if (value is String && value.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        return _resourceList(decoded);
      } catch (_) {
        return [];
      }
    }
    return [];
  }

  List<Map<String, dynamic>> _questionResultList(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => item.map((key, value) => MapEntry('$key', value)))
          .toList();
    }
    if (value is String && value.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        return _questionResultList(decoded);
      } catch (_) {
        return [];
      }
    }
    return [];
  }

  List<Map<String, dynamic>> _answerListFromText(String text) {
    if (text.trim().isEmpty) return [];
    try {
      final decoded = jsonDecode(text);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((item) => item.map((key, value) => MapEntry('$key', value)))
            .toList();
      }
    } catch (_) {
      return [];
    }
    return [];
  }

  void _prefillAnswerControllers(
    List<TextEditingController> controllers,
    String text,
  ) {
    for (final answer in _answerListFromText(text)) {
      final number = int.tryParse(answer['questionNumber']?.toString() ?? '');
      if (number == null || number < 1 || number > controllers.length) {
        continue;
      }
      controllers[number - 1].text = answer['answer']?.toString() ?? '';
    }
  }

  String _encodeAnswerControllers(List<TextEditingController> controllers) {
    final answers = <Map<String, dynamic>>[];
    for (var index = 0; index < controllers.length; index++) {
      final answer = controllers[index].text.trim();
      if (answer.isEmpty) continue;
      answers.add({'questionNumber': index + 1, 'answer': answer});
    }
    return jsonEncode(answers);
  }

  bool _hasAnyAnswer(List<TextEditingController> controllers) {
    return controllers.any((controller) => controller.text.trim().isNotEmpty);
  }

  int _assignmentQuestionCount(Map<String, dynamic> assignment) {
    final questionCount = int.tryParse(
      assignment['questionCount']?.toString() ?? '',
    );
    if (questionCount != null && questionCount > 0) {
      return questionCount.clamp(1, 40).toInt();
    }
    return 40;
  }

  Widget _buildNumberedAnswerBoxes(
    List<TextEditingController> controllers, {
    double maxHeight = 420,
  }) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: controllers.length,
        separatorBuilder: (context, index) => SizedBox(height: 18),
        itemBuilder: (context, index) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Color(0xFFEAF3FF),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: Color(0xFF214AA5),
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: TextField(
                  controller: controllers[index],
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: Color(0xFFB8C2CC)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: Color(0xFFB8C2CC)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(
                        color: Color(0xFF214AA5),
                        width: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _assignmentScoreText(Map<String, dynamic> assignment) {
    final score = assignment['myScore'];
    final correct = assignment['myCorrectAnswerCount'];
    final total = assignment['myTotalQuestions'];
    if (score == null) return '';
    if (correct != null && total != null) {
      return 'Điểm: $score / 100 - Đúng $correct / $total';
    }
    return 'Điểm: $score / 100';
  }

  String _resultScoreText(Map<String, dynamic> result) {
    final score = result['score'];
    final correct = result['correctAnswerCount'];
    final total = result['totalQuestions'];
    if (score == null) return '-';
    if (correct != null && total != null) {
      return '$score / 100 - Đúng $correct / $total';
    }
    return '$score / 100';
  }

  Future<void> _downloadFile(String id, String fileName) async {
    final response = await http.get(
      Uri.parse(
        '${ApiService.baseUrl}/identity/ai-reading-assignments/$id/file',
      ),
      headers: {'Authorization': 'Bearer ${authService.accessToken}'},
    );
    if (response.statusCode != 200) {
      _showSnackBar('Tải file thất bại.');
      return;
    }
    _saveBytes(fileName, response.bodyBytes, response.headers['content-type']);
  }

  Map<String, dynamic>? _submissionForAssignment(String assignmentId) {
    for (final result in _results) {
      if (result['assignmentId']?.toString() == assignmentId) {
        return result;
      }
    }
    return null;
  }

  Future<void> _downloadSubmissionFile(Map<String, dynamic> submission) async {
    final assignmentId = submission['assignmentId']?.toString();
    final submissionId = submission['id']?.toString();
    if (assignmentId == null || submissionId == null) return;

    final response = await http.get(
      Uri.parse(
        '${ApiService.baseUrl}/identity/ai-reading-assignments/$assignmentId/my-submissions/$submissionId/file',
      ),
      headers: {'Authorization': 'Bearer ${authService.accessToken}'},
    );
    if (response.statusCode != 200) {
      _showSnackBar('Tải file bài làm thất bại.');
      return;
    }
    _saveBytes(
      submission['fileName']?.toString() ?? 'bai-lam',
      response.bodyBytes,
      response.headers['content-type'],
    );
  }

  Future<void> _showSubmissionDialog(Map<String, dynamic> submission) async {
    final text = submission['submissionText']?.toString() ?? '';
    final fileName = submission['fileName']?.toString() ?? '';
    final questionResults = _questionResultList(submission['questionResults']);
    final answerList = _answerListFromText(text);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Bài làm đã nộp'),
          content: SizedBox(
            width: 560,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nộp lúc: ${_formatInstant(submission['submittedAt'])}'),
                SizedBox(height: 12),
                Text(
                  questionResults.isNotEmpty
                      ? 'Kết quả từng câu'
                      : 'Nội dung bài làm',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 8),
                _buildSubmittedAnswersView(text, answerList, questionResults),
                SizedBox(height: 12),
                if (fileName.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: () => _downloadSubmissionFile(submission),
                    icon: Icon(Icons.download_outlined),
                    label: Text('Tải file bài làm: $fileName'),
                  )
                else
                  Text('Không có file đính kèm'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSubmittedAnswersView(
    String text,
    List<Map<String, dynamic>> answerList,
    List<Map<String, dynamic>> questionResults,
  ) {
    if (questionResults.isNotEmpty) {
      return Container(
        width: double.infinity,
        constraints: BoxConstraints(maxHeight: 360),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Color(0xFFE0E0E0)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: questionResults.map((result) {
              final correct = result['correct'] == true;
              return Container(
                margin: EdgeInsets.only(bottom: 8),
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: correct ? Color(0xFFE8F5E9) : Color(0xFFFFF1F1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: correct ? Color(0xFF81C784) : Color(0xFFE57373),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Câu ${result['questionNumber']}: ${correct ? 'Đúng' : 'Sai'}',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 4),
                    SelectableText(
                      'Bạn trả lời: ${(result['studentAnswer']?.toString() ?? '').isEmpty ? '(trống)' : result['studentAnswer']}',
                    ),
                    if ((result['correctAnswer']?.toString() ?? '').isNotEmpty)
                      SelectableText('Đáp án đúng: ${result['correctAnswer']}'),
                    if ((result['explanation']?.toString() ?? '').isNotEmpty)
                      SelectableText('Giải thích: ${result['explanation']}'),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      );
    }

    if (answerList.isNotEmpty) {
      return Container(
        width: double.infinity,
        constraints: BoxConstraints(maxHeight: 300),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Color(0xFFE0E0E0)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: answerList
                .map(
                  (answer) => Padding(
                    padding: EdgeInsets.only(bottom: 6),
                    child: SelectableText(
                      'Câu ${answer['questionNumber']}: ${answer['answer']}',
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(maxHeight: 260),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        child: SelectableText(
          text.trim().isEmpty ? 'Không có nội dung text' : text,
        ),
      ),
    );
  }

  void _saveBytes(String fileName, Uint8List bytes, String? contentType) {
    final blob = html.Blob([bytes], contentType ?? 'application/octet-stream');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..download = fileName
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  Future<void> _showSubmitDialog(Map<String, dynamic> assignment) async {
    final questionCount = _assignmentQuestionCount(assignment);
    final answerControllers = List.generate(
      questionCount,
      (_) => TextEditingController(),
    );
    final currentSubmission = _submissionForAssignment(
      assignment['id']?.toString() ?? '',
    );
    _prefillAnswerControllers(
      answerControllers,
      currentSubmission?['submissionText']?.toString() ?? '',
    );
    PlatformFile? answerFile;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Nộp bài Reading'),
              content: SizedBox(
                width: 720,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nhập đáp án theo $questionCount câu của đề.',
                        style: TextStyle(color: Color(0xFF555555)),
                      ),
                      SizedBox(height: 12),
                      _buildNumberedAnswerBoxes(answerControllers),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () async {
                              final result = await FilePicker.platform
                                  .pickFiles(withData: true);
                              if (result == null || result.files.isEmpty) {
                                return;
                              }
                              setDialogState(() {
                                answerFile = result.files.first;
                              });
                            },
                            icon: Icon(Icons.attach_file),
                            label: Text('Chọn file bài làm'),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              answerFile?.name ??
                                  'Có thể nộp text, file hoặc cả hai',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!_hasAnyAnswer(answerControllers) &&
                        answerFile?.bytes == null) {
                      _showSnackBar(
                        'Vui lòng nhập ít nhất 1 câu trả lời hoặc chọn file bài làm.',
                      );
                      return;
                    }
                    await _submitAssignment(
                      assignment['id'].toString(),
                      _encodeAnswerControllers(answerControllers),
                      answerFile,
                    );
                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                  },
                  child: Text('Nộp bài'),
                ),
              ],
            );
          },
        );
      },
    );
    for (final controller in answerControllers) {
      controller.dispose();
    }
  }

  Future<void> _submitAssignment(
    String assignmentId,
    String answerText,
    PlatformFile? answerFile,
  ) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(
        '${ApiService.baseUrl}/identity/ai-reading-assignments/$assignmentId/submit',
      ),
    );
    request.headers['Authorization'] = 'Bearer ${authService.accessToken}';
    request.fields['submissionText'] = answerText;
    if (answerFile?.bytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          answerFile!.bytes!,
          filename: answerFile.name,
        ),
      );
    }
    final response = await request.send();
    final body = await response.stream.bytesToString();
    final decoded = body.isNotEmpty ? jsonDecode(body) : {};
    if (response.statusCode == 200 && decoded['code'] == 1000) {
      _showSnackBar('Đã nộp bài.');
      final result = decoded['result'];
      if (result is Map) {
        final submission = result.map((key, value) => MapEntry('$key', value));
        _upsertResult(submission);
        final assignmentId = submission['assignmentId']?.toString();
        if (assignmentId != null) {
          _upsertAssignment({
            'id': assignmentId,
            'mySubmissionStatus': submission['status'],
            'mySubmissionId': submission['id'],
            'mySubmissionText': submission['submissionText'],
            'mySubmissionFileName': submission['fileName'],
            'mySubmittedAt': submission['submittedAt'],
            'myScore': submission['score'],
            'myTotalQuestions': submission['totalQuestions'],
            'myAnsweredQuestionCount': submission['answeredQuestionCount'],
            'myCorrectAnswerCount': submission['correctAnswerCount'],
            'myQuestionResults': submission['questionResults'],
            'myRecommendation': submission['recommendation'],
            'myRecommendedResources': submission['recommendedResources'],
          });
        }
      }
      unawaited(_refreshData());
    } else {
      _showSnackBar(decoded['message']?.toString() ?? 'Nộp bài thất bại.');
    }
  }

  String _formatInstant(dynamic value) {
    if (value == null) return '';
    final date = DateTime.tryParse(value.toString());
    if (date == null) return value.toString();
    return DateFormat('dd/MM/yyyy HH:mm').format(date.toLocal());
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _openResource(String url) {
    if (url.trim().isEmpty) return;
    html.window.open(url, '_blank');
  }

  @override
  Widget build(BuildContext context) {
    return Title(
      color: Colors.black,
      title: 'Bài tập của bạn',
      child: SiteLayout(
        menuNo: widget.menuOrder,
        content: Container(
          color: Colors.white,
          child: _loading
              ? Center(child: CircularProgressIndicator())
              : _loadError != null
              ? Center(child: Text('Không tải được dữ liệu bài đọc AI'))
              : DefaultTabController(
                  length: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(24, 18, 24, 0),
                        child: Row(
                          children: [
                            Text(
                              'Bài đọc AI được giao',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Spacer(),
                            if (_refreshing)
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                          ],
                        ),
                      ),
                      TabBar(
                        tabs: [
                          Tab(text: 'Đề cần làm'),
                          Tab(text: 'Kết quả'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildAssignments(_assignments),
                            _buildResults(_results),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildAssignments(List<Map<String, dynamic>> assignments) {
    if (assignments.isEmpty) {
      return Center(child: Text('Chưa có bài đọc AI nào'));
    }
    return ListView(
      padding: EdgeInsets.all(24),
      children: assignments.map((assignment) {
        final locked = assignment['locked'] == true;
        final submitted = assignment['mySubmissionStatus'] != null;
        final graded = assignment['myScore'] != null;
        final submission = _submissionForAssignment(
          assignment['id']?.toString() ?? '',
        );
        return Container(
          margin: EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Color(0xFFE0E0E0)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      assignment['title']?.toString() ?? '',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Chip(
                    label: Text(locked ? 'Đã khóa' : 'Đang mở'),
                    backgroundColor: locked
                        ? Color(0xFFFFE7E7)
                        : Color(0xFFE8F5E9),
                  ),
                ],
              ),
              SizedBox(height: 6),
              Text('Lớp: ${assignment['className'] ?? ''}'),
              Text('Hạn nộp: ${_formatInstant(assignment['dueAt'])}'),
              if ((assignment['instruction']?.toString() ?? '').isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(assignment['instruction'].toString()),
                ),
              SizedBox(height: 12),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _downloadFile(
                      assignment['id'].toString(),
                      assignment['fileName']?.toString() ?? 'reading-file',
                    ),
                    icon: Icon(Icons.download_outlined),
                    label: Text('Tải đề'),
                  ),
                  SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: locked
                        ? null
                        : () => _showSubmitDialog(assignment),
                    icon: Icon(Icons.upload_file_outlined),
                    label: Text(submitted ? 'Nộp lại' : 'Nộp bài'),
                  ),
                  SizedBox(width: 12),
                  if (submission != null) ...[
                    OutlinedButton.icon(
                      onPressed: () => _showSubmissionDialog(submission),
                      icon: Icon(Icons.visibility_outlined),
                      label: Text('Xem lại bài làm'),
                    ),
                    SizedBox(width: 12),
                  ],
                  if (graded)
                    Text(
                      _assignmentScoreText(assignment),
                      style: TextStyle(fontWeight: FontWeight.w700),
                    )
                  else if (submitted)
                    Text('Đã nộp, đang chờ chấm'),
                ],
              ),
              if ((assignment['myRecommendation']?.toString() ?? '').isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text('Gợi ý: ${assignment['myRecommendation']}'),
                ),
              _buildResourceLinks(
                _resourceList(assignment['myRecommendedResources']),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildResults(List<Map<String, dynamic>> results) {
    if (results.isEmpty) {
      return Center(child: Text('Chưa có kết quả nào'));
    }
    return ListView(
      padding: EdgeInsets.all(24),
      children: results.map((result) {
        return Container(
          margin: EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Color(0xFFE0E0E0)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      result['assignmentTitle']?.toString() ?? '',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Text(
                    _resultScoreText(result),
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text('Nộp lúc: ${_formatInstant(result['submittedAt'])}'),
              if ((result['feedback']?.toString() ?? '').isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text('Nhận xét: ${result['feedback']}'),
                ),
              if ((result['recommendation']?.toString() ?? '').isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text('Gợi ý: ${result['recommendation']}'),
                ),
              _buildResourceLinks(
                _resourceList(result['recommendedResources']),
              ),
              if (result['score'] != null)
                Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/flashcard'),
                    icon: Icon(Icons.style_outlined, size: 16),
                    label: Text('Ôn lỗi sai trong Flashcards'),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildResourceLinks(List<Map<String, dynamic>> resources) {
    if (resources.isEmpty) return SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Link ôn tập đề xuất',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: resources.map((resource) {
              final title = resource['title']?.toString() ?? 'Tài liệu ôn tập';
              final url = resource['url']?.toString() ?? '';
              final source = resource['source']?.toString() ?? '';
              return Tooltip(
                message: resource['description']?.toString() ?? title,
                child: OutlinedButton.icon(
                  onPressed: url.isEmpty ? null : () => _openResource(url),
                  icon: Icon(Icons.open_in_new_outlined, size: 16),
                  label: Text(source.isEmpty ? title : '$title - $source'),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
