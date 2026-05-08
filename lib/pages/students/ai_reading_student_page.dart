import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:universal_html/html.dart' as html;

import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/layout/layout.dart';

class AiReadingStudentPage extends StatefulWidget {
  const AiReadingStudentPage({super.key, this.menuOrder = 5});

  /// Sidebar order to highlight when this page is shown. Defaults to 5
  /// ("Bài tập của bạn") since Reading AI bài tập được giao thuộc nhóm này.
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
    final result = decoded['result'];
    if (result is List) {
      return result
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

  void _saveBytes(String fileName, Uint8List bytes, String? contentType) {
    final blob = html.Blob([bytes], contentType ?? 'application/octet-stream');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..download = fileName
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  Future<void> _showSubmitDialog(Map<String, dynamic> assignment) async {
    final answerController = TextEditingController();
    PlatformFile? answerFile;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Nộp bài Reading'),
              content: SizedBox(
                width: 520,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: answerController,
                      maxLines: 8,
                      decoration: InputDecoration(
                        labelText: 'Câu trả lời',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () async {
                            final result = await FilePicker.platform.pickFiles(
                              withData: true,
                            );
                            if (result == null || result.files.isEmpty) return;
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
                            answerFile?.name ?? 'Có thể nộp text hoặc file',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await _submitAssignment(
                      assignment['id'].toString(),
                      answerController.text,
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
    answerController.dispose();
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
            'myScore': submission['score'],
            'myRecommendation': submission['recommendation'],
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
              ? Center(child: Text('Không tải được dữ liệu Reading AI'))
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
                              'Bài tập Reading AI',
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
      return Center(child: Text('Chưa có đề Reading AI nào'));
    }
    return ListView(
      padding: EdgeInsets.all(24),
      children: assignments.map((assignment) {
        final locked = assignment['locked'] == true;
        final submitted = assignment['mySubmissionStatus'] != null;
        final graded = assignment['myScore'] != null;
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
                  if (graded)
                    Text(
                      'Điểm: ${assignment['myScore']}',
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
                    result['score'] == null ? '-' : '${result['score']} / 100',
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
            ],
          ),
        );
      }).toList(),
    );
  }
}
