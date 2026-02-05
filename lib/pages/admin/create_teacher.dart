import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../exceptions/unauthorized_exception.dart';
import '../../helpers/convert_date_format.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/layout/layout.dart';
import '../../widgets/login/password_field.dart';

class CreateTeacherPage extends StatefulWidget {
  const CreateTeacherPage({super.key});

  @override
  State<CreateTeacherPage> createState() => _CreateTeacherPageState();
}

class _CreateTeacherPageState extends State<CreateTeacherPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();

  bool _usernameError = false;
  bool _passwordError = false;
  bool _dobError = false;
  bool _lastNameError = false;
  bool _firstNameError = false;
  bool _isPickingDate = false;

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_onUsernameChanged);
    _passwordController.addListener(_onPasswordChanged);
    _dobController.addListener(_onDobChanged);
    _lastNameController.addListener(_onLastNameChanged);
    _firstNameController.addListener(_onFirstNameChanged);
  }

  void _onUsernameChanged() {
    if (_usernameError && _usernameController.text.trim().isNotEmpty) {
      setState(() {
        _usernameError = false;
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

  void _onDobChanged() {
    if (_dobError && _dobController.text.trim().isNotEmpty) {
      setState(() {
        _dobError = false;
      });
    }
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

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _dobController.dispose();
    _lastNameController.dispose();
    _firstNameController.dispose();

    _usernameController.removeListener(_onUsernameChanged);
    _passwordController.removeListener(_onPasswordChanged);
    _dobController.removeListener(_onDobChanged);
    _lastNameController.removeListener(_onLastNameChanged);
    _firstNameController.removeListener(_onFirstNameChanged);
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
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
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );

      if (selected == null) return;
      controller.text = _formatDate(selected);
    } finally {
      _isPickingDate = false;
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Title(
      color: Colors.black,
      title: "Tạo giáo viên",
      child: SiteLayout(
        menuNo: 15,
        content: Container(
          color: Colors.white,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_circle_left_outlined, size: 32),
                      onPressed: () {
                        context.go('/teacher-management');
                      },
                    ),
                    Text(
                      "Tạo giáo viên",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 20),

                Padding(
                  padding: EdgeInsets.only(left: 50, right: 50),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: 'Tên đăng nhập',
                            errorText: _usernameError
                                ? 'Vui lòng nhập tên đăng nhập'
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.red),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.red,
                                width: 2,
                              ),
                            ),
                          ),
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: PasswordField(
                          controller: _passwordController,
                          showError: _passwordError,
                          labelText: 'Mật khẩu',
                          errorText: 'Vui lòng nhập mật khẩu',
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _dobController,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Ngày sinh',
                            errorText: _dobError
                                ? 'Vui lòng chọn ngày sinh'
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.red),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.red,
                                width: 2,
                              ),
                            ),
                            suffixIcon: IconButton(
                              tooltip: 'Chọn ngày sinh',
                              icon: Icon(Icons.calendar_month_outlined),
                              onPressed: () async {
                                await _pickDate(controller: _dobController);
                              },
                            ),
                          ),
                          onTap: () async {
                            await _pickDate(controller: _dobController);
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 12),

                Padding(
                  padding: EdgeInsets.only(left: 50, right: 50),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _lastNameController,
                          decoration: InputDecoration(
                            labelText: 'Họ và tên lót',
                            errorText: _lastNameError
                                ? 'Vui lòng nhập họ và tên lót'
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.red),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.red,
                                width: 2,
                              ),
                            ),
                          ),
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _firstNameController,
                          decoration: InputDecoration(
                            labelText: 'Tên',
                            errorText: _firstNameError
                                ? 'Vui lòng nhập tên'
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.red),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.red,
                                width: 2,
                              ),
                            ),
                          ),
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(child: Container()),
                    ],
                  ),
                ),

                SizedBox(height: 20,),

                Row(
                  children: [
                    Expanded(child: Container()),
                    ElevatedButton(
                      onPressed: () async {
                        setState(() {
                          _usernameError = _usernameController.text.trim().isEmpty;
                          _passwordError = _passwordController.text.trim().isEmpty;
                          _dobError = _dobController.text.trim().isEmpty;
                          _lastNameError = _lastNameController.text.trim().isEmpty;
                          _firstNameError = _firstNameController.text.trim().isEmpty;
                        });

                        if (_usernameError || _passwordError || _dobError || _lastNameError || _firstNameError) {
                          return;
                        }

                        var creationResponse = await ApiService.post(
                          '/identity/users',
                          token: authService.accessToken,
                          body: {
                            'username': _usernameController.text,
                            'password': _passwordController.text,
                            'dob': convertDateFormat(_dobController.text),
                            'lastName': _lastNameController.text,
                            'firstName': _firstNameController.text,
                          },
                        );

                        if (creationResponse.statusCode == 401) {
                          var refreshResponse = await ApiService.post(
                            '/identity/auth/refresh',
                            body: {'token': authService.accessToken},
                          );

                          var refreshData = jsonDecode(refreshResponse.body);
                          if (refreshData['code'] == 1000) {
                            final newToken = refreshData['result']['token'];
                            await authService.setAuth(newToken);

                            creationResponse = await ApiService.post(
                              '/identity/users',
                              token: authService.accessToken,
                              body: {
                                'username': _usernameController.text,
                                'password': _passwordController.text,
                                'dob': convertDateFormat(_dobController.text),
                                'lastName': _lastNameController.text,
                                'firstName': _firstNameController.text,
                              },
                            );
                          } else {
                            await authService.clearAuth();
                            throw UnauthorizedException();
                          }
                        }

                        final creationData = jsonDecode(creationResponse.body);
                        if (creationData != null && creationData['code'] == 1000) {
                          var roleResponse = await ApiService.post(
                            '/identity/users/${creationData['result']['id']}/roles',
                            token: authService.accessToken,
                            body: {
                              'role': 'TEACHER',
                            },
                          );

                          if (creationResponse.statusCode == 401) {
                            var refreshResponse = await ApiService.post(
                              '/identity/auth/refresh',
                              body: {'token': authService.accessToken},
                            );

                            var refreshData = jsonDecode(refreshResponse.body);
                            if (refreshData['code'] == 1000) {
                              final newToken = refreshData['result']['token'];
                              await authService.setAuth(newToken);

                              roleResponse = await ApiService.post(
                                '/identity/users/${creationData['result']['id']}/roles',
                                token: authService.accessToken,
                                body: {
                                  'role': 'TEACHER',
                                },
                              );
                            } else {
                              await authService.clearAuth();
                              throw UnauthorizedException();
                            }
                          }

                          final roleData = jsonDecode(roleResponse.body);

                          if (roleData != null && roleData['code'] == 1000) {

                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Tạo giáo viên thành công')),
                            );
                            context.go('/teacher-management');

                          } else {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Tạo giáo viên thất bại')),
                            );
                          }
                        } else {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Tạo giáo viên thất bại')),
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
                      child: Text('Tạo giáo viên'),
                    ),
                    Expanded(child: Container()),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}