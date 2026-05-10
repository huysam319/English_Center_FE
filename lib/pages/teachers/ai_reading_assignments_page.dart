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

class AiReadingAssignmentsPage extends StatefulWidget {
  const AiReadingAssignmentsPage({super.key, this.classId});

  final String? classId;

  @override
  State<AiReadingAssignmentsPage> createState() =>
      _AiReadingAssignmentsPageState();
}

class _AiReadingAssignmentsPageState extends State<AiReadingAssignmentsPage> {
  final _titleController = TextEditingController();
  final _instructionController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final Map<String, List<Map<String, dynamic>>> _submissionsByAssignmentId = {};
  final Set<String> _gradingAssignmentIds = {};

  Timer? _refreshTimer;
  Timer? _deadlineTimer;
  List<Map<String, dynamic>> _assignments = [];
  List<Map<String, dynamic>> _classes = [];
  String? _selectedClassId;
  String _className = '';
  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  PlatformFile? _selectedFile;
  bool _loading = true;
  bool _refreshing = false;
  bool _submitting = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _selectedClassId = widget.classId;
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
    _titleController.dispose();
    _instructionController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _loadData() async {
    final assignmentsResponse = await ApiService.get(
      '/identity/ai-reading-assignments/teacher',
      token: authService.accessToken,
    );
    final classesResponse = await ApiService.get(
      '/identity/courses/coursesOfTeacher?page=0&size=100',
      token: authService.accessToken,
    );

    return {
      'assignments': _resultList(assignmentsResponse.body),
      'classes': _courseList(classesResponse.body),
    };
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
      var assignments = data['assignments'] as List<Map<String, dynamic>>;
      final classes = data['classes'] as List<Map<String, dynamic>>;

      // If page is class-scoped, only show assignments for this class
      if (widget.classId != null) {
        assignments = assignments
            .where((a) => a['classId']?.toString() == widget.classId)
            .toList();
        final matched = classes.firstWhere(
          (c) => c['id']?.toString() == widget.classId,
          orElse: () => <String, dynamic>{},
        );
        _className = matched['name']?.toString() ?? '';
      }

      final submissions = <String, List<Map<String, dynamic>>>{};
      await Future.wait(
        assignments.map((assignment) async {
          final id = assignment['id']?.toString();
          if (id == null) return;
          submissions[id] = await _loadSubmissions(id);
        }),
      );

      if (!mounted) return;
      setState(() {
        _assignments = assignments;
        _classes = classes;
        _submissionsByAssignmentId
          ..clear()
          ..addAll(submissions);
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

  List<Map<String, dynamic>> _courseList(String body) {
    final decoded = jsonDecode(body);
    final content = decoded['result']?['content'];
    if (content is List) {
      return content
          .whereType<Map>()
          .map((item) => item.map((key, value) => MapEntry('$key', value)))
          .toList();
    }
    return [];
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

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 3),
    );
    if (selected == null) return;
    setState(() {
      _dueDate = selected;
      _dateController.text = DateFormat('dd/MM/yyyy').format(selected);
    });
  }

  Future<void> _pickDueTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? TimeOfDay.now(),
    );
    if (selected == null) return;
    setState(() {
      _dueTime = selected;
      _timeController.text =
          '${selected.hour.toString().padLeft(2, '0')}:${selected.minute.toString().padLeft(2, '0')}';
    });
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null || result.files.isEmpty) return;
    setState(() {
      _selectedFile = result.files.first;
    });
  }

  DateTime? _combinedDueAt() {
    if (_dueDate == null || _dueTime == null) return null;
    return DateTime(
      _dueDate!.year,
      _dueDate!.month,
      _dueDate!.day,
      _dueTime!.hour,
      _dueTime!.minute,
    );
  }

  Future<void> _createAssignment() async {
    final dueAt = _combinedDueAt();
    if (_titleController.text.trim().isEmpty ||
        _selectedClassId == null ||
        dueAt == null ||
        _selectedFile?.bytes == null) {
      _showSnackBar('Vui lòng nhập đủ thông tin và chọn file đề.');
      return;
    }

    setState(() => _submitting = true);
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}/identity/ai-reading-assignments'),
      );
      request.headers['Authorization'] = 'Bearer ${authService.accessToken}';
      request.fields['title'] = _titleController.text.trim();
      request.fields['classId'] = _selectedClassId!;
      request.fields['dueAt'] = dueAt.toUtc().toIso8601String();
      request.fields['instruction'] = _instructionController.text.trim();
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          _selectedFile!.bytes!,
          filename: _selectedFile!.name,
        ),
      );

      final response = await request.send();
      final body = await response.stream.bytesToString();
      final decoded = body.isNotEmpty ? jsonDecode(body) : {};
      if (response.statusCode == 200 && decoded['code'] == 1000) {
        _showSnackBar('Đã tạo bài đọc AI.');
        _titleController.clear();
        _instructionController.clear();
        _dateController.clear();
        _timeController.clear();
        setState(() {
          if (widget.classId == null) {
            _selectedClassId = null;
          }
          _dueDate = null;
          _dueTime = null;
          _selectedFile = null;
        });
        final result = decoded['result'];
        if (result is Map) {
          final assignment = result.map(
            (key, value) => MapEntry('$key', value),
          );
          _upsertAssignment(assignment);
          final id = assignment['id']?.toString();
          if (id != null) {
            _submissionsByAssignmentId[id] = [];
          }
        }
        unawaited(_refreshData());
      } else {
        _showSnackBar(decoded['message']?.toString() ?? 'Tạo đề thất bại.');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
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

  Future<void> _showAnswerKeyDialog(Map<String, dynamic> assignment) async {
    final answerController = TextEditingController();
    PlatformFile? answerFile;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Tải lên đáp án'),
              content: SizedBox(
                width: 520,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: answerController,
                      maxLines: 6,
                      decoration: InputDecoration(
                        labelText: 'Đáp án hoặc kết quả chuẩn',
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
                          label: Text('Chọn file'),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            answerFile?.name ?? 'Chưa chọn file',
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
                    await _uploadAnswerKey(
                      assignment['id'].toString(),
                      answerController.text,
                      answerFile,
                    );
                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                  },
                  child: Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );
    answerController.dispose();
  }

  Future<void> _uploadAnswerKey(
    String assignmentId,
    String answerText,
    PlatformFile? answerFile,
  ) async {
    final request = http.MultipartRequest(
      'PUT',
      Uri.parse(
        '${ApiService.baseUrl}/identity/ai-reading-assignments/$assignmentId/answer-key',
      ),
    );
    request.headers['Authorization'] = 'Bearer ${authService.accessToken}';
    request.fields['answerKeyText'] = answerText;
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
      _showSnackBar('Đã lưu đáp án.');
      final result = decoded['result'];
      if (result is Map) {
        _upsertAssignment(result.map((key, value) => MapEntry('$key', value)));
      }
      unawaited(_refreshData());
    } else {
      _showSnackBar(
        decoded['message']?.toString() ?? 'Tải lên đáp án thất bại.',
      );
    }
  }

  Future<void> _gradeAssignment(String assignmentId) async {
    if (_gradingAssignmentIds.contains(assignmentId)) return;
    setState(() => _gradingAssignmentIds.add(assignmentId));
    try {
      final response = await ApiService.post(
        '/identity/ai-reading-assignments/$assignmentId/grade',
        token: authService.accessToken,
      );
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && decoded['code'] == 1000) {
        final submissions = _resultList(response.body);
        _showSnackBar('Đã chấm điểm bằng AI.');
        setState(() {
          _submissionsByAssignmentId[assignmentId] = submissions;
          final index = _assignments.indexWhere(
            (item) => item['id']?.toString() == assignmentId,
          );
          if (index >= 0) {
            _assignments[index] = {
              ..._assignments[index],
              'locked': true,
              'submissionCount': submissions.length,
              'gradedCount': submissions
                  .where((submission) => submission['score'] != null)
                  .length,
              'gradedAt': DateTime.now().toUtc().toIso8601String(),
            };
          }
        });
        unawaited(_refreshData());
      } else {
        _showSnackBar(decoded['message']?.toString() ?? 'Chấm điểm thất bại.');
      }
    } finally {
      if (mounted) {
        setState(() => _gradingAssignmentIds.remove(assignmentId));
      }
    }
  }

  Future<List<Map<String, dynamic>>> _loadSubmissions(
    String assignmentId,
  ) async {
    final response = await ApiService.get(
      '/identity/ai-reading-assignments/$assignmentId/submissions',
      token: authService.accessToken,
    );
    return _resultList(response.body);
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

  Widget _buildClassNavTabs() {
    if (widget.classId == null) return SizedBox.shrink();
    final classId = widget.classId!;
    Widget tab(String label, String path, {bool active = false}) {
      return Padding(
        padding: EdgeInsets.only(right: 2),
        child: ElevatedButton(
          onPressed: () => context.go(path),
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(
              active ? Color(0xFF1E40AF) : Color(0xFFF1F3F4),
            ),
            foregroundColor: WidgetStateProperty.all(
              active ? Colors.white : Color(0xFF1E40AF),
            ),
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            minimumSize: WidgetStateProperty.all(Size(150, 50)),
            elevation: WidgetStateProperty.all(0),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
          ),
          child: Text(label),
        ),
      );
    }

    return Row(
      children: [
        tab('Lớp học', '/classes/$classId'),
        tab('Học viên', '/classes/$classId/students'),
        tab('Bài tập', '/classes/$classId/exercises', active: true),
        tab('Điểm danh', '/classes/$classId/attendances'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scoped = widget.classId != null;
    return Title(
      color: Colors.black,
      title: scoped ? 'Bài tập | Lớp $_className' : 'Bài tập',
      child: SiteLayout(
        menuNo: scoped ? 13 : 0,
        content: Container(
          color: Colors.white,
          child: _loading
              ? Center(child: CircularProgressIndicator())
              : _loadError != null
              ? Center(child: Text('Không tải được dữ liệu bài đọc AI'))
              : ListView(
                  padding: EdgeInsets.all(24),
                  children: [
                    if (scoped) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Lớp $_className',
                          style: TextStyle(
                            color: Color(0xFF1E40AF),
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      _buildClassNavTabs(),
                      SizedBox(height: 20),
                    ],
                    Row(
                      children: [
                        if (!scoped)
                          IconButton(
                            icon: Icon(
                              Icons.arrow_circle_left_outlined,
                              size: 30,
                            ),
                            onPressed: () => context.go('/exercises'),
                          ),
                        Text(
                          'Bài đọc AI',
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
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                    SizedBox(height: 16),
                    _buildCreatePanel(_classes),
                    SizedBox(height: 20),
                    Text(
                      'Đề đã giao',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 8),
                    if (_assignments.isEmpty)
                      Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: Text('Chưa có bài đọc AI nào')),
                      )
                    else
                      ..._assignments.map(_buildAssignmentTile),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildCreatePanel(List<Map<String, dynamic>> classes) {
    final scoped = widget.classId != null;
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tạo bài đọc AI từ file',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Tiêu đề',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: scoped
                    ? TextField(
                        readOnly: true,
                        controller: TextEditingController(text: _className),
                        decoration: InputDecoration(
                          labelText: 'Lớp',
                          border: OutlineInputBorder(),
                        ),
                      )
                    : DropdownButtonFormField<String>(
                        value: _selectedClassId,
                        items: classes
                            .map(
                              (course) => DropdownMenuItem<String>(
                                value: course['id'].toString(),
                                child: Text(course['name']?.toString() ?? ''),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _selectedClassId = value),
                        decoration: InputDecoration(
                          labelText: 'Lớp',
                          border: OutlineInputBorder(),
                        ),
                      ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _dateController,
                  readOnly: true,
                  onTap: _pickDueDate,
                  decoration: InputDecoration(
                    labelText: 'Ngày hết hạn',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_month_outlined),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _timeController,
                  readOnly: true,
                  onTap: _pickDueTime,
                  decoration: InputDecoration(
                    labelText: 'Giờ hết hạn',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.schedule_outlined),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          TextField(
            controller: _instructionController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Ghi chú cho học sinh',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _pickFile,
                icon: Icon(Icons.upload_file_outlined),
                label: Text('Chọn file đề'),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  _selectedFile?.name ?? 'Chưa chọn file',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _submitting ? null : _createAssignment,
                icon: _submitting
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.add),
                label: Text('Tạo bài'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentTile(Map<String, dynamic> assignment) {
    final id = assignment['id'].toString();
    final locked = assignment['locked'] == true;
    final grading = _gradingAssignmentIds.contains(id);
    final submissions = _submissionsByAssignmentId[id];
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        title: Text(
          assignment['title']?.toString() ?? '',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${assignment['className'] ?? ''} - Hạn: ${_formatInstant(assignment['dueAt'])}',
        ),
        trailing: Chip(
          label: Text(locked ? 'Đã khóa' : 'Đang mở'),
          backgroundColor: locked ? Color(0xFFFFE7E7) : Color(0xFFE8F5E9),
        ),
        childrenPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Row(
            children: [
              Text('Bài nộp: ${assignment['submissionCount'] ?? 0}'),
              SizedBox(width: 16),
              Text('Đã chấm: ${assignment['gradedCount'] ?? 0}'),
              SizedBox(width: 16),
              Text(
                'Đáp án: ${assignment['hasAnswerKey'] == true ? 'Đã có' : 'Chưa có'}',
              ),
              Spacer(),
              TextButton.icon(
                onPressed: () => _downloadFile(
                  id,
                  assignment['fileName']?.toString() ?? 'reading-file',
                ),
                icon: Icon(Icons.download_outlined),
                label: Text('Tải đề'),
              ),
              TextButton.icon(
                onPressed: () => _showAnswerKeyDialog(assignment),
                icon: Icon(Icons.fact_check_outlined),
                label: Text('Đáp án'),
              ),
              ElevatedButton.icon(
                onPressed: locked && !grading
                    ? () => _gradeAssignment(id)
                    : null,
                icon: grading
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.auto_awesome_outlined),
                label: Text(grading ? 'Đang chấm' : 'Chấm AI'),
              ),
            ],
          ),
          if (submissions == null)
            Padding(
              padding: EdgeInsets.all(16),
              child: LinearProgressIndicator(),
            )
          else if (submissions.isEmpty)
            Padding(
              padding: EdgeInsets.all(12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Chưa có học sinh nộp bài'),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Học sinh')),
                  DataColumn(label: Text('Nộp lúc')),
                  DataColumn(label: Text('Điểm')),
                  DataColumn(label: Text('Trạng thái')),
                  DataColumn(label: Text('Gợi ý')),
                  DataColumn(label: Text('Link ôn tập')),
                ],
                rows: submissions.map((submission) {
                  final name =
                      '${submission['lastName'] ?? ''} ${submission['firstName'] ?? ''}'
                          .trim();
                  final recommendation =
                      submission['recommendation']?.toString() ?? '';
                  final resources = _resourceList(
                    submission['recommendedResources'],
                  );
                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          name.isEmpty ? submission['username'] ?? '' : name,
                        ),
                      ),
                      DataCell(Text(_formatInstant(submission['submittedAt']))),
                      DataCell(Text(submission['score']?.toString() ?? '-')),
                      DataCell(Text(submission['status']?.toString() ?? '-')),
                      DataCell(
                        SizedBox(
                          width: 420,
                          child: Tooltip(
                            message: recommendation,
                            child: Text(
                              recommendation,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 360,
                          child: _buildResourceLinks(resources),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResourceLinks(List<Map<String, dynamic>> resources) {
    if (resources.isEmpty) {
      return Text('Chưa có');
    }
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: resources.take(3).map((resource) {
        final title = resource['title']?.toString() ?? 'Tài liệu ôn tập';
        final url = resource['url']?.toString() ?? '';
        final source = resource['source']?.toString() ?? '';
        return Tooltip(
          message: resource['description']?.toString() ?? title,
          child: TextButton.icon(
            onPressed: url.isEmpty ? null : () => _openResource(url),
            icon: Icon(Icons.open_in_new_outlined, size: 16),
            label: Text(source.isEmpty ? title : source),
          ),
        );
      }).toList(),
    );
  }
}
