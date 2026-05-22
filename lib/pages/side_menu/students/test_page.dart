import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:universal_html/html.dart' as html;

import '../../../exceptions/unauthorized_exception.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/layout/layout.dart';

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  late final Future<List<Map<String, dynamic>>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadTests();
  }

  Future<List<Map<String, dynamic>>> _loadTests() async {
    final response = await ApiService.get(
      '/identity/ai-reading-assignments/student?kind=TEST',
      token: authService.accessToken,
    );
    if (response.statusCode == 401) {
      await authService.clearAuth();
      throw UnauthorizedException();
    }
    final decoded = jsonDecode(response.body);
    final result = decoded['result'];
    if (result is List) {
      return result
          .whereType<Map>()
          .map((item) => item.map((key, value) => MapEntry('$key', value)))
          .toList();
    }
    return [];
  }

  String _formatInstant(dynamic value) {
    if (value == null) return '';
    final date = DateTime.tryParse(value.toString());
    if (date == null) return value.toString();
    return DateFormat('dd/MM/yyyy HH:mm').format(date.toLocal());
  }

  String _scoreText(Map<String, dynamic> test) {
    final score = test['myScore'];
    final correct = test['myCorrectAnswerCount'];
    final total = test['myTotalQuestions'];
    if (score == null) return '';
    if (correct != null && total != null) {
      return 'Điểm: $score / 100 - Đúng $correct / $total';
    }
    return 'Điểm: $score / 100';
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

  bool _hasSubmissionDetail(Map<String, dynamic> test) {
    return test['mySubmissionId'] != null ||
        (test['mySubmissionText']?.toString() ?? '').isNotEmpty ||
        (test['mySubmissionFileName']?.toString() ?? '').isNotEmpty ||
        _questionResultList(test['myQuestionResults']).isNotEmpty;
  }

  void _saveBytes(String fileName, Uint8List bytes, String? contentType) {
    final blob = html.Blob([bytes], contentType ?? 'application/octet-stream');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..download = fileName
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  Future<void> _downloadSubmissionFile(Map<String, dynamic> test) async {
    final assignmentId = test['id']?.toString();
    final submissionId = test['mySubmissionId']?.toString();
    if (assignmentId == null || submissionId == null) return;

    final response = await http.get(
      Uri.parse(
        '${ApiService.baseUrl}/identity/ai-reading-assignments/$assignmentId/my-submissions/$submissionId/file',
      ),
      headers: {'Authorization': 'Bearer ${authService.accessToken}'},
    );
    if (response.statusCode != 200) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tải file bài làm thất bại.')),
      );
      return;
    }
    _saveBytes(
      test['mySubmissionFileName']?.toString() ?? 'bai-lam',
      response.bodyBytes,
      response.headers['content-type'],
    );
  }

  Future<void> _showSubmissionDialog(Map<String, dynamic> test) async {
    final text = test['mySubmissionText']?.toString() ?? '';
    final fileName = test['mySubmissionFileName']?.toString() ?? '';
    final questionResults = _questionResultList(test['myQuestionResults']);
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
                Text('Nộp lúc: ${_formatInstant(test['mySubmittedAt'])}'),
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
                    onPressed: () => _downloadSubmissionFile(test),
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

  @override
  Widget build(BuildContext context) {
    return Title(
      color: Colors.black,
      title: 'Danh sách đề thi',
      child: SiteLayout(
        menuNo: 6,
        content: Container(
          color: Colors.white,
          child: FutureBuilder<List<Map<String, dynamic>>>(
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
                return const Center(child: Text('Lỗi tải danh sách đề thi'));
              }

              final tests = snapshot.data ?? [];
              if (tests.isEmpty) {
                return const Center(child: Text('Chưa có đề thi nào'));
              }

              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const Text(
                    'Đề thi được giao',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: tests.map((test) {
                      final locked = test['locked'] == true;
                      final submitted = test['mySubmissionStatus'] != null;
                      final score = test['myScore'];
                      return SizedBox(
                        width: 360,
                        child: Material(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(color: Color(0xFFE0E0E0)),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => context.go('/test/${test['id']}'),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          test['title']?.toString() ?? '',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      Chip(
                                        label: Text(
                                          locked ? 'Đã khóa' : 'Đang mở',
                                        ),
                                        backgroundColor: locked
                                            ? const Color(0xFFFFE7E7)
                                            : const Color(0xFFE8F5E9),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text('Lớp: ${test['className'] ?? ''}'),
                                  Text(
                                    'Hạn nộp: ${_formatInstant(test['dueAt'])}',
                                  ),
                                  const SizedBox(height: 12),
                                  if (score != null)
                                    Text(
                                      _scoreText(test),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    )
                                  else if (submitted)
                                    const Text('Đã nộp, đang chờ chấm')
                                  else
                                    const Text('Chưa nộp bài'),
                                  if (_hasSubmissionDetail(test)) ...[
                                    const SizedBox(height: 10),
                                    OutlinedButton.icon(
                                      onPressed: () =>
                                          _showSubmissionDialog(test),
                                      icon: const Icon(
                                        Icons.visibility_outlined,
                                        size: 18,
                                      ),
                                      label: const Text('Xem lại bài đã nộp'),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
