import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../exceptions/unauthorized_exception.dart';
import '../../../helpers/convert_date_time_format.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/layout/layout.dart';

class StudentDetailPage extends StatefulWidget {
  final String studentId;

  const StudentDetailPage({super.key, required this.studentId});

  @override
  State<StudentDetailPage> createState() => _StudentDetailPageState();
}

Future<Map<String, dynamic>> _loadStudentInfo(String id) async {
  var response = await ApiService.get(
    '/identity/users/$id',
    token: authService.accessToken,
  );

  if (response.statusCode == 401) {
    final refreshResponse = await ApiService.post(
      '/identity/auth/refresh',
      body: {'token': authService.accessToken},
    );
    final refreshData = jsonDecode(refreshResponse.body);
    if (refreshData['code'] == 1000) {
      await authService.setAuth(refreshData['result']['token']);
      response = await ApiService.get(
        '/identity/users/$id',
        token: authService.accessToken,
      );
    } else {
      await authService.clearAuth();
      throw UnauthorizedException();
    }
  }

  return jsonDecode(response.body);
}

class _StudentDetailPageState extends State<StudentDetailPage> {
  late Future<Map<String, dynamic>> _dataFuture;
  final _lastNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _dobController = TextEditingController();
  bool _initialized = false;
  bool _saving = false;
  bool _deleting = false;
  bool _isPickingDate = false;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadStudentInfo(widget.studentId);
  }

  @override
  void dispose() {
    _lastNameController.dispose();
    _firstNameController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  void _initControllers(Map<String, dynamic> result) {
    if (_initialized) return;
    _lastNameController.text = result['lastName']?.toString() ?? '';
    _firstNameController.text = result['firstName']?.toString() ?? '';
    final dob = DateTime.tryParse(result['dob']?.toString() ?? '');
    _dobController.text = dob == null ? '' : formatDate(dob);
    _initialized = true;
  }

  Future<Map<String, dynamic>> _putUser(Map<String, dynamic> body) async {
    var response = await ApiService.put(
      '/identity/users/${widget.studentId}',
      token: authService.accessToken,
      body: body,
    );
    if (response.statusCode == 401) {
      final refreshResponse = await ApiService.post(
        '/identity/auth/refresh',
        body: {'token': authService.accessToken},
      );
      final refreshData = jsonDecode(refreshResponse.body);
      if (refreshData['code'] == 1000) {
        await authService.setAuth(refreshData['result']['token']);
        response = await ApiService.put(
          '/identity/users/${widget.studentId}',
          token: authService.accessToken,
          body: body,
        );
      } else {
        await authService.clearAuth();
        throw UnauthorizedException();
      }
    }
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> _deleteUser() async {
    var response = await ApiService.delete(
      '/identity/users/${widget.studentId}',
      token: authService.accessToken,
    );
    if (response.statusCode == 401) {
      final refreshResponse = await ApiService.post(
        '/identity/auth/refresh',
        body: {'token': authService.accessToken},
      );
      final refreshData = jsonDecode(refreshResponse.body);
      if (refreshData['code'] == 1000) {
        await authService.setAuth(refreshData['result']['token']);
        response = await ApiService.delete(
          '/identity/users/${widget.studentId}',
          token: authService.accessToken,
        );
      } else {
        await authService.clearAuth();
        throw UnauthorizedException();
      }
    }
    return jsonDecode(response.body);
  }

  Future<void> _pickDob() async {
    if (_isPickingDate) return;
    _isPickingDate = true;
    try {
      final selected = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(1900),
        lastDate: DateTime(2100),
      );
      if (selected != null) {
        _dobController.text = formatDate(selected);
      }
    } finally {
      _isPickingDate = false;
    }
  }

  Future<void> _saveInfo() async {
    if (_lastNameController.text.trim().isEmpty ||
        _firstNameController.text.trim().isEmpty ||
        _dobController.text.trim().isEmpty) {
      _showSnackBar('Vui lòng nhập đủ thông tin học viên');
      return;
    }

    setState(() => _saving = true);
    try {
      final data = await _putUser({
        'lastName': _lastNameController.text.trim(),
        'firstName': _firstNameController.text.trim(),
        'dob': convertDateFormat(_dobController.text.trim()),
      });
      if (data['code'] == 1000) {
        _showSnackBar('Đã cập nhật học viên');
        setState(() {
          _initialized = false;
          _dataFuture = _loadStudentInfo(widget.studentId);
        });
      } else {
        _showSnackBar(data['message']?.toString() ?? 'Cập nhật thất bại');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Xóa học viên'),
        content: Text('Học viên sẽ bị xóa khỏi tài khoản và các lớp đang học.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Xóa'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _deleting = true);
    try {
      final data = await _deleteUser();
      if (data['code'] == 1000) {
        if (!mounted) return;
        _showSnackBar('Đã xóa học viên');
        context.go('/student-management');
      } else {
        _showSnackBar(data['message']?.toString() ?? 'Xóa học viên thất bại');
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError && snapshot.error is UnauthorizedException) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.go('/login');
          });
        }

        final result = snapshot.data?['result'];
        if (result is Map<String, dynamic>) {
          _initControllers(result);
        }
        final studentName = result is Map<String, dynamic>
            ? '${result['lastName'] ?? ''} ${result['firstName'] ?? ''}'.trim()
            : '';

        return Title(
          color: Colors.black,
          title: studentName.isEmpty
              ? 'Thông tin học viên'
              : 'Học viên $studentName',
          child: SiteLayout(
            menuNo: 16,
            content: Container(
              color: Colors.white,
              child: ListView(
                padding: EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_circle_left_outlined, size: 32),
                        onPressed: () => context.go('/student-management'),
                      ),
                      Text(
                        'Thông tin học viên',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Spacer(),
                      ElevatedButton.icon(
                        onPressed: () => context.go(
                          '/student-management/${widget.studentId}/add-enrolment',
                        ),
                        icon: Icon(Icons.add_outlined, size: 20),
                        label: Text('Thêm vào lớp học'),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _deleting ? null : _confirmDelete,
                        icon: _deleting
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(Icons.delete_outline),
                        label: Text('Xóa học viên'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    Center(child: CircularProgressIndicator())
                  else if (snapshot.hasError || result is! Map<String, dynamic>)
                    Center(child: Text('Lỗi tải thông tin học viên'))
                  else
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 50),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ID: ${result['id'] ?? ''}'),
                          SizedBox(height: 8),
                          Text('Tên đăng nhập: ${result['username'] ?? ''}'),
                          SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _lastNameController,
                                  decoration: InputDecoration(
                                    labelText: 'Họ và tên lót',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _firstNameController,
                                  decoration: InputDecoration(
                                    labelText: 'Tên',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _dobController,
                                  readOnly: true,
                                  onTap: _pickDob,
                                  decoration: InputDecoration(
                                    labelText: 'Ngày sinh',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    suffixIcon: Icon(
                                      Icons.calendar_month_outlined,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton.icon(
                              onPressed: _saving ? null : _saveInfo,
                              icon: _saving
                                  ? SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(Icons.save_outlined),
                              label: Text('Lưu thông tin'),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
