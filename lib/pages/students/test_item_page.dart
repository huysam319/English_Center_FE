import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui_web' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:universal_html/html.dart' as html;

import '../../exceptions/unauthorized_exception.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/layout/layout.dart';

class TestItemPage extends StatefulWidget {
  const TestItemPage({super.key, required this.testId});

  final String testId;

  @override
  State<TestItemPage> createState() => _TestItemPageState();
}

class _TestItemPageState extends State<TestItemPage> {
  final List<TextEditingController> _answerControllers = List.generate(
    40,
    (_) => TextEditingController(),
  );
  late Future<Map<String, dynamic>> _dataFuture;
  late Future<Uint8List> _pdfFuture;

  Map<String, dynamic>? _assignment;
  PlatformFile? _answerFile;
  String? _pdfObjectUrl;
  String? _pdfViewType;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadAssignment();
    _pdfFuture = _loadPdfBytes();
  }

  @override
  void dispose() {
    _revokePdfObjectUrl();
    for (final controller in _answerControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<Map<String, dynamic>> _loadAssignment() async {
    final response = await ApiService.get(
      '/identity/ai-reading-assignments/${widget.testId}',
      token: authService.accessToken,
    );
    if (response.statusCode == 401) {
      await authService.clearAuth();
      throw UnauthorizedException();
    }
    final decoded = jsonDecode(response.body);
    final result = decoded['result'];
    if (result is! Map) {
      throw StateError('Invalid test data');
    }
    final assignment = result.map((key, value) => MapEntry('$key', value));
    _assignment = assignment;
    _prefillAnswerControllers(assignment['mySubmissionText']?.toString() ?? '');
    return assignment;
  }

  Future<Uint8List> _loadPdfBytes() async {
    final response = await http.get(
      Uri.parse(
        '${ApiService.baseUrl}/identity/ai-reading-assignments/${widget.testId}/file',
      ),
      headers: {
        if (authService.accessToken != null)
          'Authorization': 'Bearer ${authService.accessToken}',
      },
    );
    if (response.statusCode == 401) {
      await authService.clearAuth();
      throw UnauthorizedException();
    }
    if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
      throw StateError('Cannot load test PDF');
    }
    return response.bodyBytes;
  }

  String _formatInstant(dynamic value) {
    if (value == null) return '';
    final date = DateTime.tryParse(value.toString());
    if (date == null) return value.toString();
    return DateFormat('dd/MM/yyyy HH:mm').format(date.toLocal());
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

  void _prefillAnswerControllers(String text) {
    for (final answer in _answerListFromText(text)) {
      final number = int.tryParse(answer['questionNumber']?.toString() ?? '');
      if (number == null || number < 1 || number > _answerControllers.length) {
        continue;
      }
      _answerControllers[number - 1].text = answer['answer']?.toString() ?? '';
    }
  }

  String _encodedAnswers() {
    final answers = <Map<String, dynamic>>[];
    for (var index = 0; index < _answerControllers.length; index++) {
      final answer = _answerControllers[index].text.trim();
      if (answer.isEmpty) continue;
      answers.add({'questionNumber': index + 1, 'answer': answer});
    }
    return jsonEncode(answers);
  }

  bool _hasAnyAnswer() {
    return _answerControllers.any(
      (controller) => controller.text.trim().isNotEmpty,
    );
  }

  Widget _buildNumberedAnswerBoxes({double maxHeight = 420}) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: ListView.separated(
        itemCount: _answerControllers.length,
        separatorBuilder: (context, index) => const SizedBox(height: 18),
        itemBuilder: (context, index) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF3FF),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Color(0xFF214AA5),
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: TextField(
                  controller: _answerControllers[index],
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: Color(0xFFB8C2CC)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: Color(0xFFB8C2CC)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(
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

  Future<void> _pickAnswerFile() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null || result.files.isEmpty) return;
    setState(() {
      _answerFile = result.files.first;
    });
  }

  Future<void> _submitAnswer() async {
    if (!_hasAnyAnswer() && _answerFile?.bytes == null) {
      _showSnackBar(
        'Vui lòng nhập ít nhất 1 câu trả lời hoặc chọn file bài làm.',
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(
          '${ApiService.baseUrl}/identity/ai-reading-assignments/${widget.testId}/submit',
        ),
      );
      request.headers['Authorization'] = 'Bearer ${authService.accessToken}';
      request.fields['submissionText'] = _encodedAnswers();
      if (_answerFile?.bytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            _answerFile!.bytes!,
            filename: _answerFile!.name,
          ),
        );
      }

      final response = await request.send();
      final body = await response.stream.bytesToString();
      final decoded = body.isNotEmpty ? jsonDecode(body) : {};
      if (response.statusCode == 200 && decoded['code'] == 1000) {
        final result = decoded['result'];
        setState(() {
          _assignment = {
            ...?_assignment,
            'mySubmissionId': result is Map ? result['id'] : null,
            'mySubmissionText': result is Map ? result['submissionText'] : null,
            'mySubmissionFileName': result is Map ? result['fileName'] : null,
            'mySubmittedAt': result is Map ? result['submittedAt'] : null,
            'mySubmissionStatus': result is Map
                ? result['status']
                : 'SUBMITTED',
            'myScore': result is Map ? result['score'] : null,
            'myTotalQuestions': result is Map ? result['totalQuestions'] : null,
            'myAnsweredQuestionCount': result is Map
                ? result['answeredQuestionCount']
                : null,
            'myCorrectAnswerCount': result is Map
                ? result['correctAnswerCount']
                : null,
            'myQuestionResults': result is Map
                ? result['questionResults']
                : null,
            'myRecommendation': result is Map ? result['recommendation'] : null,
            'myRecommendedResources': result is Map
                ? result['recommendedResources']
                : null,
          };
          _answerFile = null;
        });
        _showSnackBar('Đã nộp bài.');
      } else {
        _showSnackBar(decoded['message']?.toString() ?? 'Nộp bài thất bại.');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _scoreText(Map<String, dynamic> assignment) {
    final score = assignment['myScore'];
    final correct = assignment['myCorrectAnswerCount'];
    final total = assignment['myTotalQuestions'];
    if (score == null) return '';
    if (correct != null && total != null) {
      return 'Điểm: $score / 100 - Đúng $correct / $total';
    }
    return 'Điểm: $score / 100';
  }

  bool _hasSubmissionDetail(Map<String, dynamic> assignment) {
    return assignment['mySubmissionId'] != null ||
        (assignment['mySubmissionText']?.toString() ?? '').isNotEmpty ||
        (assignment['mySubmissionFileName']?.toString() ?? '').isNotEmpty ||
        _questionResultList(assignment['myQuestionResults']).isNotEmpty;
  }

  void _revokePdfObjectUrl() {
    final objectUrl = _pdfObjectUrl;
    if (objectUrl == null) return;
    html.Url.revokeObjectUrl(objectUrl);
    _pdfObjectUrl = null;
    _pdfViewType = null;
  }

  bool _looksLikePdf(Uint8List bytes) {
    const signature = [0x25, 0x50, 0x44, 0x46, 0x2D]; // %PDF-
    final maxOffset = bytes.length < 1024 ? bytes.length : 1024;
    for (var offset = 0; offset <= maxOffset - signature.length; offset++) {
      var matched = true;
      for (var index = 0; index < signature.length; index++) {
        if (bytes[offset + index] != signature[index]) {
          matched = false;
          break;
        }
      }
      if (matched) return true;
    }
    return false;
  }

  String get _assignmentFileName {
    final fileName = _assignment?['fileName']?.toString().trim();
    return fileName == null || fileName.isEmpty ? 'de-thi' : fileName;
  }

  void _downloadBytes(Uint8List bytes, String fileName) {
    final blob = html.Blob([bytes], 'application/octet-stream');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..download = fileName
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  Future<void> _downloadSubmissionFile(Map<String, dynamic> assignment) async {
    final submissionId = assignment['mySubmissionId']?.toString();
    if (submissionId == null) return;

    final response = await http.get(
      Uri.parse(
        '${ApiService.baseUrl}/identity/ai-reading-assignments/${widget.testId}/my-submissions/$submissionId/file',
      ),
      headers: {'Authorization': 'Bearer ${authService.accessToken}'},
    );
    if (response.statusCode != 200) {
      _showSnackBar('Tải file bài làm thất bại.');
      return;
    }
    _downloadBytes(
      response.bodyBytes,
      assignment['mySubmissionFileName']?.toString() ?? 'bai-lam',
    );
  }

  Future<void> _showSubmissionDialog(Map<String, dynamic> assignment) async {
    final text = assignment['mySubmissionText']?.toString() ?? '';
    final fileName = assignment['mySubmissionFileName']?.toString() ?? '';
    final questionResults = _questionResultList(
      assignment['myQuestionResults'],
    );
    final answerList = _answerListFromText(text);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Bài làm đã nộp'),
          content: SizedBox(
            width: 560,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nộp lúc: ${_formatInstant(assignment['mySubmittedAt'])}'),
                const SizedBox(height: 12),
                const Text(
                  'Kết quả / bài làm',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                _buildSubmittedAnswersView(text, answerList, questionResults),
                const SizedBox(height: 12),
                if (fileName.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: () => _downloadSubmissionFile(assignment),
                    icon: const Icon(Icons.download_outlined),
                    label: Text('Tải file bài làm: $fileName'),
                  )
                else
                  const Text('Không có file đính kèm'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Đóng'),
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
        constraints: const BoxConstraints(maxHeight: 360),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE0E0E0)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: questionResults.map((result) {
              final correct = result['correct'] == true;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: correct
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFFFF1F1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: correct
                        ? const Color(0xFF81C784)
                        : const Color(0xFFE57373),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Câu ${result['questionNumber']}: ${correct ? 'Đúng' : 'Sai'}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
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
        constraints: const BoxConstraints(maxHeight: 300),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE0E0E0)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: answerList
                .map(
                  (answer) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
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
      constraints: const BoxConstraints(maxHeight: 260),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        child: SelectableText(
          text.trim().isEmpty ? 'Không có nội dung text' : text,
        ),
      ),
    );
  }

  Widget _buildBrowserPdfViewer(Uint8List pdfBytes) {
    if (_pdfViewType == null) {
      final blob = html.Blob([pdfBytes], 'application/pdf');
      final objectUrl = html.Url.createObjectUrlFromBlob(blob);
      final viewType =
          'test-pdf-${widget.testId}-${DateTime.now().microsecondsSinceEpoch}';

      _pdfObjectUrl = objectUrl;
      _pdfViewType = viewType;
      ui.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
        return html.IFrameElement()
          ..src = objectUrl
          ..style.border = '0'
          ..style.height = '100%'
          ..style.width = '100%'
          ..setAttribute('title', 'File PDF đề thi');
      });
    }

    return HtmlElementView(
      key: ValueKey(_pdfViewType),
      viewType: _pdfViewType!,
    );
  }

  Widget _buildInvalidPdfPane(Uint8List bytes) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.picture_as_pdf_outlined,
                size: 44,
                color: Color(0xFF6A4FA3),
              ),
              const SizedBox(height: 12),
              const Text(
                'File đề thi hiện không phải PDF hợp lệ.',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Vui lòng nhờ giáo viên tải lại file PDF. Bạn vẫn có thể tải file hiện tại xuống để kiểm tra.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _downloadBytes(bytes, _assignmentFileName),
                    icon: const Icon(Icons.download_outlined),
                    label: const Text('Tải file'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Title(
      color: Colors.black,
      title: 'Làm đề thi',
      child: SiteLayout(
        menuNo: 6,
        content: Container(
          color: Colors.white,
          child: FutureBuilder<Map<String, dynamic>>(
            future: _dataFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                final err = snapshot.error;
                if (err is UnauthorizedException) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) context.go('/login');
                  });
                  return const SizedBox.shrink();
                }
                return const Center(child: Text('Lỗi tải đề thi'));
              }

              final assignment = _assignment ?? snapshot.data ?? {};
              return _buildTestWorkspace(assignment);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTestWorkspace(Map<String, dynamic> assignment) {
    final locked = assignment['locked'] == true;
    final submitted = assignment['mySubmissionStatus'] != null;
    final score = assignment['myScore'];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Row(
            children: [
              IconButton(
                onPressed: () => context.go('/test'),
                icon: const Icon(Icons.arrow_circle_left_outlined, size: 30),
                tooltip: 'Quay lại',
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assignment['title']?.toString() ?? 'Đề thi',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Hạn nộp: ${_formatInstant(assignment['dueAt'])}',
                      style: const TextStyle(color: Color(0xFF555555)),
                    ),
                  ],
                ),
              ),
              Chip(
                label: Text(locked ? 'Đã khóa' : 'Đang mở'),
                backgroundColor: locked
                    ? const Color(0xFFFFE7E7)
                    : const Color(0xFFE8F5E9),
              ),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 900;
              final pdfPane = _buildPdfPane();
              final answerPane = _buildAnswerPane(
                locked: locked,
                submitted: submitted,
                score: score,
                assignment: assignment,
              );
              if (stacked) {
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    SizedBox(height: 520, child: pdfPane),
                    const SizedBox(height: 16),
                    answerPane,
                  ],
                );
              }
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 6, child: pdfPane),
                    const SizedBox(width: 16),
                    Expanded(flex: 4, child: answerPane),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPdfPane() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: FutureBuilder<Uint8List>(
        future: _pdfFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final err = snapshot.error;
            if (err is UnauthorizedException) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) context.go('/login');
              });
              return const SizedBox.shrink();
            }
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Không mở được file PDF đề thi.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (!_looksLikePdf(snapshot.data!)) {
            return _buildInvalidPdfPane(snapshot.data!);
          }

          return _buildBrowserPdfViewer(snapshot.data!);
        },
      ),
    );
  }

  Widget _buildAnswerPane({
    required bool locked,
    required bool submitted,
    required dynamic score,
    required Map<String, dynamic> assignment,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bài làm của học sinh',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          if ((assignment['instruction']?.toString() ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(assignment['instruction'].toString()),
          ],
          const SizedBox(height: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nhập đáp án theo số câu. Đề 20 câu thì chỉ điền 20 câu.',
                  style: TextStyle(color: Color(0xFF555555)),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _buildNumberedAnswerBoxes(maxHeight: double.infinity),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: locked ? null : _pickAnswerFile,
                icon: const Icon(Icons.attach_file),
                label: const Text('Upload file'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _answerFile?.name ?? 'Có thể nộp text, file hoặc cả hai',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: locked || _submitting ? null : _submitAnswer,
              icon: _submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_outlined),
              label: Text(submitted ? 'Nộp lại bài' : 'Nộp bài'),
            ),
          ),
          if (submitted || score != null) ...[
            const SizedBox(height: 12),
            Text(
              score == null
                  ? 'Đã nộp, đang chờ giáo viên chấm AI'
                  : _scoreText(assignment),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            if (_hasSubmissionDetail(assignment))
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: OutlinedButton.icon(
                  onPressed: () => _showSubmissionDialog(assignment),
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text('Xem lại bài đã nộp'),
                ),
              ),
            if ((assignment['myRecommendation']?.toString() ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Gợi ý: ${assignment['myRecommendation']}'),
              ),
          ],
        ],
      ),
    );
  }
}
