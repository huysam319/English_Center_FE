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

class TestHistoryPage extends StatefulWidget {
  const TestHistoryPage({super.key});

  @override
  State<TestHistoryPage> createState() => _TestHistoryPageState();
}

class _TestHistoryPageState extends State<TestHistoryPage> {
  late final Future<List<Map<String, dynamic>>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _loadHistory();
  }

  Future<List<Map<String, dynamic>>> _loadHistory() async {
    final response = await ApiService.get(
      '/identity/ai-reading-assignments/student/results',
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

  String _typeLabel(Map<String, dynamic> item) {
    return item['assignmentKind']?.toString().toUpperCase() == 'TEST'
        ? 'Đề thi'
        : 'Bài tập';
  }

  String _scoreText(Map<String, dynamic> item) {
    final score = item['score'];
    final correct = item['correctAnswerCount'];
    final total = item['totalQuestions'];
    if (score == null) return 'Đang chờ AI chấm';
    if (correct != null && total != null) {
      return '$score / 100 - Đúng $correct / $total';
    }
    return '$score / 100';
  }

  List<Map<String, dynamic>> _jsonList(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => item.map((key, value) => MapEntry('$key', value)))
          .toList();
    }
    if (value is String && value.trim().isNotEmpty) {
      try {
        return _jsonList(jsonDecode(value));
      } catch (_) {
        return [];
      }
    }
    return [];
  }

  void _saveBytes(String fileName, Uint8List bytes, String? contentType) {
    final blob = html.Blob([bytes], contentType ?? 'application/octet-stream');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..download = fileName
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  Future<void> _downloadSubmissionFile(Map<String, dynamic> item) async {
    final assignmentId = item['assignmentId']?.toString();
    final submissionId = item['id']?.toString();
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
      item['fileName']?.toString() ?? 'bai-lam',
      response.bodyBytes,
      response.headers['content-type'],
    );
  }

  Future<void> _showSubmissionDialog(Map<String, dynamic> item) async {
    final text = item['submissionText']?.toString() ?? '';
    final fileName = item['fileName']?.toString() ?? '';
    final answers = _jsonList(text);
    final questionResults = _jsonList(item['questionResults']);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Xem lại ${_typeLabel(item).toLowerCase()}'),
          content: SizedBox(
            width: 620,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(item['assignmentTitle']?.toString() ?? ''),
                  Text('Nộp lúc: ${_formatInstant(item['submittedAt'])}'),
                  if (item['gradedAt'] != null)
                    Text('AI chấm lúc: ${_formatInstant(item['gradedAt'])}'),
                  const SizedBox(height: 12),
                  Text(
                    _scoreText(item),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  _buildAnswersView(text, answers, questionResults),
                  if ((item['feedback']?.toString() ?? '').isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text('Nhận xét: ${item['feedback']}'),
                  ],
                  if ((item['recommendation']?.toString() ?? '')
                      .isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('Gợi ý: ${item['recommendation']}'),
                  ],
                  const SizedBox(height: 12),
                  if (fileName.isNotEmpty)
                    OutlinedButton.icon(
                      onPressed: () => _downloadSubmissionFile(item),
                      icon: const Icon(Icons.download_outlined),
                      label: Text('Tải file bài làm: $fileName'),
                    )
                  else
                    const Text('Không có file đính kèm'),
                ],
              ),
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

  Widget _buildAnswersView(
    String rawText,
    List<Map<String, dynamic>> answers,
    List<Map<String, dynamic>> questionResults,
  ) {
    if (questionResults.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chi tiết đúng/sai từng câu',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 380),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: questionResults.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final result = questionResults[index];
                final correct = result['correct'] == true;
                final studentAnswer =
                    result['studentAnswer']?.toString().trim() ?? '';
                final correctAnswer =
                    result['correctAnswer']?.toString().trim() ?? '';
                final explanation =
                    result['explanation']?.toString().trim() ?? '';
                return Container(
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
                      SelectableText(
                        'Bạn trả lời: ${studentAnswer.isEmpty ? '(trống)' : studentAnswer}',
                      ),
                      if (correctAnswer.isNotEmpty)
                        SelectableText('Đáp án đúng: $correctAnswer'),
                      if (explanation.isNotEmpty)
                        SelectableText('Giải thích: $explanation'),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      );
    }

    if (answers.isNotEmpty) {
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
            children: answers
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
          rawText.trim().isEmpty ? 'Không có nội dung text' : rawText,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Title(
      color: Colors.black,
      title: 'Lịch sử làm bài',
      child: SiteLayout(
        menuNo: 7,
        content: Container(
          color: Colors.white,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _historyFuture,
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
                return const Center(child: Text('Lỗi tải lịch sử làm bài'));
              }

              final history = snapshot.data ?? [];
              if (history.isEmpty) {
                return const Center(child: Text('Chưa có lịch sử làm bài'));
              }

              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const Text(
                    'Lịch sử làm bài',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  ...history.map(_buildHistoryCard),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> item) {
    final typeLabel = _typeLabel(item);
    final graded = item['score'] != null;
    final correct = item['correctAnswerCount'];
    final total = item['totalQuestions'];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Chip(
                label: Text(typeLabel),
                backgroundColor: typeLabel == 'Đề thi'
                    ? const Color(0xFFEFF6FF)
                    : const Color(0xFFF0FDF4),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item['assignmentTitle']?.toString() ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(_formatInstant(item['submittedAt'])),
            ],
          ),
          const SizedBox(height: 8),
          Text('Lớp: ${item['className'] ?? ''}'),
          if (item['dueAt'] != null)
            Text('Hạn nộp: ${_formatInstant(item['dueAt'])}'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                _scoreText(item),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              if (graded && correct != null && total != null)
                Text('Sai ${total - correct} câu'),
              OutlinedButton.icon(
                onPressed: () => _showSubmissionDialog(item),
                icon: const Icon(Icons.visibility_outlined, size: 18),
                label: Text(graded ? 'Xem đúng/sai' : 'Xem bài đã nộp'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
