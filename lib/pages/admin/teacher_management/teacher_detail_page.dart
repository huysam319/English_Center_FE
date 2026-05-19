import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../exceptions/unauthorized_exception.dart';
import '../../../helpers/convert_date_time_format.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/layout/layout.dart';
import '../../../widgets/login/password_field.dart';

class TeacherDetailPage extends StatefulWidget {
  final String id;

  const TeacherDetailPage({super.key, required this.id});

  @override
  State<TeacherDetailPage> createState() => _TeacherDetailPageState();
}

Future<Map<String, dynamic>> _loadTeacherInfo(String id) async {
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

class _TeacherDetailPageState extends State<TeacherDetailPage> {
  late Future<Map<String, dynamic>> _dataFuture;
  final _lastNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _initialized = false;
  bool _savingInfo = false;
  bool _savingPassword = false;
  bool _isPickingDate = false;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadTeacherInfo(widget.id);
  }

  @override
  void dispose() {
    _lastNameController.dispose();
    _firstNameController.dispose();
    _dobController.dispose();
    _passwordController.dispose();
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
      '/identity/users/${widget.id}',
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
          '/identity/users/${widget.id}',
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

  Future<void> _pickDob() async {
    if (_isPickingDate) return;
    _isPickingDate = true;
    try {
      final now = DateTime.now();
      final selected = await showDatePicker(
        context: context,
        initialDate: DateTime.tryParse(_dobController.text) ?? now,
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
      _showSnackBar('Vui lòng nhập đủ thông tin giáo viên');
      return;
    }

    setState(() => _savingInfo = true);
    try {
      final data = await _putUser({
        'lastName': _lastNameController.text.trim(),
        'firstName': _firstNameController.text.trim(),
        'dob': convertDateFormat(_dobController.text.trim()),
      });
      if (data['code'] == 1000) {
        _showSnackBar('Đã cập nhật thông tin giáo viên');
        setState(() {
          _initialized = false;
          _dataFuture = _loadTeacherInfo(widget.id);
        });
      } else {
        _showSnackBar(data['message']?.toString() ?? 'Cập nhật thất bại');
      }
    } finally {
      if (mounted) setState(() => _savingInfo = false);
    }
  }

  Future<void> _changePassword() async {
    if (_passwordController.text.trim().length < 6) {
      _showSnackBar('Mật khẩu phải có ít nhất 6 ký tự');
      return;
    }

    setState(() => _savingPassword = true);
    try {
      final data = await _putUser({
        'password': _passwordController.text.trim(),
      });
      if (data['code'] == 1000) {
        _passwordController.clear();
        _showSnackBar('Đã đổi mật khẩu giáo viên');
      } else {
        _showSnackBar(data['message']?.toString() ?? 'Đổi mật khẩu thất bại');
      }
    } finally {
      if (mounted) setState(() => _savingPassword = false);
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
    return Title(
      color: Colors.black,
      title: 'Thông tin giáo viên',
      child: SiteLayout(
        menuNo: 15,
        content: Container(
          color: Colors.white,
          child: FutureBuilder<Map<String, dynamic>>(
            future: _dataFuture,
            builder: (context, snapshot) {
              if (snapshot.hasError &&
                  snapshot.error is UnauthorizedException) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) context.go('/login');
                });
              }

              final result = snapshot.data?['result'];
              if (result is Map<String, dynamic>) {
                _initControllers(result);
              }

              return ListView(
                padding: EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_circle_left_outlined, size: 32),
                        onPressed: () => context.go('/teacher-management'),
                      ),
                      Text(
                        'Thông tin giáo viên',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    Center(child: CircularProgressIndicator())
                  else if (snapshot.hasError || result is! Map<String, dynamic>)
                    Center(child: Text('Lỗi tải thông tin giáo viên'))
                  else ...[
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 50),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                              onPressed: _savingInfo ? null : _saveInfo,
                              icon: _savingInfo
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
                          Divider(height: 40),
                          SizedBox(
                            width: 420,
                            child: PasswordField(
                              controller: _passwordController,
                              showError: false,
                              labelText: 'Mật khẩu mới',
                              errorText: '',
                            ),
                          ),
                          SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _savingPassword ? null : _changePassword,
                            icon: _savingPassword
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(Icons.lock_reset_outlined),
                            label: Text('Đổi mật khẩu'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
