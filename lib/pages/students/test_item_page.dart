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
  final TextEditingController _answerController = TextEditingController();
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
    _answerController.dispose();
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

  Future<void> _pickAnswerFile() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null || result.files.isEmpty) return;
    setState(() {
      _answerFile = result.files.first;
    });
  }

  Future<void> _submitAnswer() async {
    final answerText = _answerController.text.trim();
    if (answerText.isEmpty && _answerFile?.bytes == null) {
      _showSnackBar('Vui lòng nhập bài làm hoặc chọn file bài làm.');
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
      request.fields['submissionText'] = answerText;
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
            'mySubmissionStatus': result is Map
                ? result['status']
                : 'SUBMITTED',
            'myScore': result is Map ? result['score'] : null,
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
            child: TextField(
              controller: _answerController,
              expands: true,
              maxLines: null,
              minLines: null,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(
                labelText: 'Nhập đáp án hoặc nội dung bài làm',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
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
                  : 'Điểm: $score / 100',
              style: const TextStyle(fontWeight: FontWeight.w700),
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
