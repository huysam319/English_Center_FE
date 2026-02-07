import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../exceptions/unauthorized_exception.dart';
import '../../helpers/convert_date_format.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/login/password_field.dart';

class UpdateAccountPage extends StatefulWidget {
  const UpdateAccountPage({super.key});

  @override
  State<UpdateAccountPage> createState() => _UpdateAccountPageState();
}

Future<Map<String, dynamic>> _loadAccountInfo() async {
  var response = await ApiService.get(
    '/identity/users/my-info',
    token: authService.accessToken,
  );

  if (response.statusCode == 401) {
    var refreshResponse = await ApiService.post(
      '/identity/auth/refresh',
      body: { 'token': authService.accessToken },
    );

    var refreshData = jsonDecode(refreshResponse.body);
    if (refreshData['code'] == 1000) {
      final newToken = refreshData['result']['token'];
      await authService.setAuth(newToken);

      response = await ApiService.get(
        '/identity/users/my-info',
        token: authService.accessToken,
      );
    } else {
      await authService.clearAuth();
      throw UnauthorizedException();
    }
  }

  return jsonDecode(response.body);
}

class _UpdateAccountPageState extends State<UpdateAccountPage> {
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  late final Future<Map<String, dynamic>> _dataFuture;

  bool _lastNameError = false;
  bool _firstNameError = false;
  bool _dobError = false;
  bool _passwordError = false;
  bool _confirmPasswordError = false;
  bool _isPickingDate = false;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadAccountInfo();

    _lastNameController.addListener(_onLastNameChanged);
    _firstNameController.addListener(_onFirstNameChanged);
    _dobController.addListener(_onDobChanged);
    _passwordController.addListener(_onPasswordChanged);
    _confirmPasswordController.addListener(_onConfirmPasswordChanged);
  }

  void _onLastNameChanged() {
    if (_lastNameError && _lastNameController.text.trim().isNotEmpty) {
      setState(() {
        _lastNameError = false;
      });
    }
  }

  void _onFirstNameChanged() {
    if (_firstNameError && _firstNameController.text.trim().isNotEmpty) {
      setState(() {
        _firstNameError = false;
      });
    }
  }

  void _onDobChanged() {
    if (_dobError && _dobController.text.trim().isNotEmpty) {
      setState(() {
        _dobError = false;
      });
    }
  }

  void _onPasswordChanged() {
    if (_passwordError && _passwordController.text.trim().isNotEmpty) {
      setState(() {
        _passwordError = false;
      });
    }
  }

  void _onConfirmPasswordChanged() {
    if (_confirmPasswordError && _confirmPasswordController.text.trim().isNotEmpty) {
      setState(() {
        _confirmPasswordError = false;
      });
    }
  }

  @override
  void dispose() {
    _lastNameController.dispose();
    _firstNameController.dispose();
    _dobController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    _lastNameController.removeListener(_onLastNameChanged);
    _firstNameController.removeListener(_onFirstNameChanged);
    _dobController.removeListener(_onDobChanged);
    _passwordController.removeListener(_onPasswordChanged);
    _confirmPasswordController.removeListener(_onConfirmPasswordChanged);
    super.dispose();
  }

  Future<void> _pickDate({
    required TextEditingController controller,
    DateTime? initialDate,
  }) async {
    if (_isPickingDate) return;
    _isPickingDate = true;

    final now = DateTime.now();
    try {
      FocusManager.instance.primaryFocus?.unfocus();
      final selected = await showDatePicker(
        context: context,
        initialDate: initialDate ?? now,
        firstDate: DateTime(1900),
        lastDate: DateTime(2100),
      );

      if (selected == null) return;
      controller.text = formatDate(selected);
    } finally {
      _isPickingDate = false;
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Title(
      color: Colors.black,
      title: "Cập nhật tài khoản",
      child: Scaffold(
        backgroundColor: Color(0xFFF1F5F9),
        body: Center(
          child: FutureBuilder<Map<String, dynamic>>(
            future: _dataFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                final err = snapshot.error;
                if (err is UnauthorizedException) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) context.go('/login');
                  });
                  return SizedBox.shrink();
                }
                return Center(child: Text('Lỗi tải thông tin người dùng'));
              }

              final accountData = snapshot.data!;
              _lastNameController.text = accountData['result']['lastName'] ?? '';
              _firstNameController.text = accountData['result']['firstName'] ?? '';

              return Container(
                width: 900,
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05,),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text("Cập nhật tài khoản",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),

                    SizedBox(height: 24,),

                    Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(left: 6, right: 6),
                            child: TextField(
                              controller: _lastNameController,
                              decoration: InputDecoration(
                                labelText: 'Họ và tên lót',
                                errorText: _lastNameError ? 'Vui lòng nhập họ và tên lót' : null,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.red),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.red, width: 2),
                                ),
                              ),
                              textInputAction: TextInputAction.next,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(left: 6, right: 6),
                            child: TextField(
                              controller: _firstNameController,
                              decoration: InputDecoration(
                                labelText: 'Tên',
                                errorText: _firstNameError ? 'Vui lòng nhập tên' : null,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.red),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.red, width: 2),
                                ),
                              ),
                              textInputAction: TextInputAction.next,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(left: 6, right: 6),
                            child: TextField(
                              controller: _dobController,
                              readOnly: true,
                              decoration: InputDecoration(
                                labelText: 'Ngày sinh',
                                errorText: _dobError ? 'Vui lòng chọn ngày sinh' : null,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.red),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.red, width: 2),
                                ),
                                suffixIcon: IconButton(
                                tooltip: 'Chọn ngày sinh',
                                icon: Icon(Icons.calendar_month_outlined),
                                onPressed: () async {
                                  await _pickDate(controller: _dobController);
                                },
                              ),
                              ),
                              textInputAction: TextInputAction.next,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(left: 6, right: 6),
                            child: PasswordField(
                              controller: _passwordController,
                              showError: _passwordError,
                              labelText: 'Mật khẩu',
                              errorText: 'Vui lòng nhập mật khẩu',
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(left: 6, right: 6),
                            child: PasswordField(
                              controller: _confirmPasswordController,
                              showError: _confirmPasswordError,
                              labelText: 'Xác nhận mật khẩu',
                              errorText: 'Vui lòng xác nhận mật khẩu',
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(left: 6, right: 6),
                            child: Container(),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Container(),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            setState(() {
                              _lastNameError = _lastNameController.text.trim().isEmpty;
                              _firstNameError = _firstNameController.text.trim().isEmpty;
                              _dobError = _dobController.text.trim().isEmpty;
                              _passwordError = _passwordController.text.trim().isEmpty;
                              _confirmPasswordError = _confirmPasswordController.text.trim().isEmpty;
                            });

                            if (_lastNameError || _firstNameError || _dobError || _passwordError || _confirmPasswordError) return;
                            if (_passwordController.text.trim() != _confirmPasswordController.text.trim()) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Xác nhận mật khẩu không khớp')),
                              );
                              return;
                            }

                            var response = await ApiService.put(
                              '/identity/users/${accountData['result']['id']}',
                              token: authService.accessToken,
                              body: {
                                'lastName': _lastNameController.text.trim(),
                                'firstName': _firstNameController.text.trim(),
                                'dob': convertDateFormat(_dobController.text.trim()),
                                'password': _passwordController.text.trim(),
                                'roles': ['USER', 'ADMIN'],
                              },
                            );

                            if (response.statusCode == 401) {
                                var refreshResponse = await ApiService.post(
                                  '/identity/auth/refresh',
                                  body: {'token': authService.accessToken},
                                );

                                var refreshData = jsonDecode(refreshResponse.body);
                                if (refreshData['code'] == 1000) {
                                  final newToken = refreshData['result']['token'];
                                  await authService.setAuth(newToken);

                                  response = await ApiService.put(
                                    '/identity/users/${accountData['result']['id']}',
                                    token: authService.accessToken,
                                    body: {
                                      'lastName': _lastNameController.text.trim(),
                                      'firstName': _firstNameController.text.trim(),
                                      'dob': convertDateFormat(_dobController.text.trim()),
                                      'password': _passwordController.text.trim(),
                                      'roles': ['USER', 'ADMIN'],
                                    },
                                  );
                                } else {
                                  await authService.clearAuth();
                                  throw UnauthorizedException();
                                }
                              }

                              final data = jsonDecode(response.body);
                              if (data != null && data['code'] == 1000) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Cập nhật thành công')),
                                );
                                context.go('/');
                              } else {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Cập nhật thất bại')),
                                );
                              }
                          },
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all(
                              Color(0xFF1E40AF),
                            ),
                            foregroundColor: WidgetStateProperty.all(Colors.white),
                            overlayColor: WidgetStateProperty.all(
                              Colors.transparent,
                            ),
                            minimumSize: WidgetStateProperty.all(Size(150, 50)),
                            elevation: WidgetStateProperty.all(0),
                            shape: WidgetStateProperty.all(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          child: Text('Cập nhật'),
                        ),
                        Expanded(
                          child: Container(),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }
          ),
        ),
      ),
    );
  }
}