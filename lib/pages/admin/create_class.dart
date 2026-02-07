import 'dart:convert';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../exceptions/unauthorized_exception.dart';
import '../../helpers/convert_date_format.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/layout/layout.dart';

class CreateClassPage extends StatefulWidget {
  const CreateClassPage({super.key});

  @override
  State<CreateClassPage> createState() => _CreateClassPageState();
}

class _CreateClassPageState extends State<CreateClassPage> {
  final TextEditingController _classNameController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  bool _classNameError = false;
  bool _startDateError = false;
  bool _endDateError = false;
  bool _isPickingDate = false;

  String? _selectedTeacherId;
  bool _teacherError = false;
  List<Map<String, dynamic>> _teachers = [];
  bool _isLoadingTeachers = false;

  @override
  void initState() {
    super.initState();
    _classNameController.addListener(_onClassNameChanged);
    _startDateController.addListener(_onStartDateChanged);
    _endDateController.addListener(_onEndDateChanged);
    _loadTeachers();
  }

  Future<void> _loadTeachers() async {
    if (_isLoadingTeachers) return;

    setState(() {
      _isLoadingTeachers = true;
    });

    try {
      final response = await ApiService.get(
        '/identity/users/teachers',
        token: authService.accessToken,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> result = data['result'] ?? [];
        setState(() {
          _teachers = result.map((e) => e as Map<String, dynamic>).toList();
          _isLoadingTeachers = false;
        });
      } else if (response.statusCode == 401) {
        throw UnauthorizedException();
      } else {
        setState(() {
          _isLoadingTeachers = false;
        });
      }
    } on UnauthorizedException {
      if (mounted) {
        context.go('/login');
      }
    } catch (e) {
      setState(() {
        _isLoadingTeachers = false;
      });
    }
  }

  void _onClassNameChanged() {
    if (_classNameError && _classNameController.text.trim().isNotEmpty) {
      setState(() {
        _classNameError = false;
      });
    }
  }

  void _onStartDateChanged() {
    if (_startDateError && _startDateController.text.trim().isNotEmpty) {
      setState(() {
        _startDateError = false;
      });
    }
  }

  void _onEndDateChanged() {
    if (_endDateError && _endDateController.text.trim().isNotEmpty) {
      setState(() {
        _endDateError = false;
      });
    }
  }

  @override
  void dispose() {
    _classNameController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();

    _classNameController.removeListener(_onClassNameChanged);
    _startDateController.removeListener(_onStartDateChanged);
    _endDateController.removeListener(_onEndDateChanged);
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
      title: "Tạo lớp học",
      child: SiteLayout(
        menuNo: 14,
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
                        context.go('/class-management');
                      },
                    ),
                    Text(
                      "Tạo lớp học",
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
                          controller: _classNameController,
                          decoration: InputDecoration(
                            labelText: 'Tên lớp',
                            errorText: _classNameError
                                ? 'Vui lòng nhập tên lớp'
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
                          controller: _startDateController,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Ngày bắt đầu',
                            errorText: _startDateError
                                ? 'Vui lòng chọn ngày bắt đầu'
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
                              tooltip: 'Chọn ngày bắt đầu',
                              icon: Icon(Icons.calendar_month_outlined),
                              onPressed: () async {
                                await _pickDate(
                                  controller: _startDateController,
                                );
                              },
                            ),
                          ),
                          onTap: () async {
                            await _pickDate(controller: _startDateController);
                          },
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _endDateController,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Ngày kết thúc',
                            errorText: _endDateError
                                ? 'Vui lòng chọn ngày kết thúc'
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
                              tooltip: 'Chọn ngày kết thúc',
                              icon: Icon(Icons.calendar_month_outlined),
                              onPressed: () async {
                                await _pickDate(controller: _endDateController);
                              },
                            ),
                          ),
                          onTap: () async {
                            await _pickDate(controller: _endDateController);
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
                        child: DropdownButtonFormField2<String>(
                          value: _selectedTeacherId,
                          decoration: InputDecoration(
                            labelText: 'Giáo viên',
                            errorText: _teacherError
                                ? 'Vui lòng chọn giáo viên'
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
                            suffixIcon: _isLoadingTeachers? 
                              Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ): null,
                          ),
                          items: _teachers.map((teacher) {
                            return DropdownMenuItem<String>(
                              value: teacher['id']?.toString(),
                              child: Text('${teacher['lastName'] ?? ''} ${teacher['firstName'] ?? ''}'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedTeacherId = value;
                              if (value != null) { _teacherError = false; }
                            });
                          },
                          onMenuStateChange: (isOpen) {
                            if (isOpen && !_isLoadingTeachers && _teachers.isEmpty) {
                              _loadTeachers();
                            }
                          },
                          hint: Text(_isLoadingTeachers ? 'Đang tải...' : 'Chọn giáo viên'),
                          dropdownStyleData: DropdownStyleData(
                            maxHeight: 200,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.white,
                            ),
                            offset: Offset(0, -10),
                          ),
                          menuItemStyleData: MenuItemStyleData(
                            height: 40,
                            padding: EdgeInsets.symmetric(horizontal: 16),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Container(),
                      ),
                      SizedBox(width: 12),
                      Expanded(child: Container()),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(child: Container()),
                    ElevatedButton(
                      onPressed: () async {
                        setState(() {
                          _classNameError = _classNameController.text.trim().isEmpty;
                          _startDateError = _startDateController.text.trim().isEmpty;
                          _endDateError = _endDateController.text.trim().isEmpty;
                          _teacherError = _selectedTeacherId == null;
                        });

                        if (_classNameError || _startDateError || _endDateError || _teacherError) {
                          return;
                        }

                        var response = await ApiService.post(
                          '/identity/courses',
                          token: authService.accessToken,
                          body: {
                            'name': _classNameController.text,
                            'startDate': convertDateFormat(
                              _startDateController.text,
                            ),
                            'endDate': convertDateFormat(
                              _endDateController.text,
                            ),
                            'teacherId': _selectedTeacherId,
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

                            response = await ApiService.post(
                              '/identity/courses',
                              token: authService.accessToken,
                              body: {
                                'name': _classNameController.text,
                                'startDate': convertDateFormat(
                                  _startDateController.text,
                                ),
                                'endDate': convertDateFormat(
                                  _endDateController.text,
                                ),
                                'teacherId': _selectedTeacherId,
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
                            SnackBar(content: Text('Tạo lớp học thành công')),
                          );
                          context.go('/class-management');
                        } else {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Tạo lớp học thất bại')),
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
                      child: Text('Tạo lớp học'),
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
