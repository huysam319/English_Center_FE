import 'dart:convert';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/days_list.dart';
import '../../../exceptions/unauthorized_exception.dart';
import '../../../helpers/convert_date_time_format.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/layout/layout.dart';

class CreateClassPage extends StatefulWidget {
  const CreateClassPage({super.key});

  @override
  State<CreateClassPage> createState() => _CreateClassPageState();
}

Future<Map<String, dynamic>> _loadAllTeachers(int page, int size) async {
  var response = await ApiService.get(
    '/identity/users/teachers?page=$page&size=$size',
    token: authService.accessToken,
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

      response = await ApiService.get(
        '/identity/users/teachers?page=$page&size=$size',
        token: authService.accessToken,
      );
    } else {
      await authService.clearAuth();
      throw UnauthorizedException();
    }
  }

  return jsonDecode(response.body);
}

class _CreateClassPageState extends State<CreateClassPage> {
  final TextEditingController _classNameController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _sessionStartTimeController =
      TextEditingController();
  final TextEditingController _sessionEndTimeController =
      TextEditingController();
  final TextEditingController _sessionTopicController = TextEditingController();
  final List<Map<String, String>> _sessionDrafts = [];

  bool _classNameError = false;
  bool _startDateError = false;
  bool _endDateError = false;
  bool _isPickingDate = false;
  bool _isPickingTime = false;

  String? _selectedTeacherId;
  String? _selectedSessionDay;
  bool _teacherError = false;

  late final Future<Map<String, dynamic>> _teachersFuture;

  @override
  void initState() {
    super.initState();
    _teachersFuture = _loadAllTeachers(0, 10);
    _classNameController.addListener(_onClassNameChanged);
    _startDateController.addListener(_onStartDateChanged);
    _endDateController.addListener(_onEndDateChanged);
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
    _sessionStartTimeController.dispose();
    _sessionEndTimeController.dispose();
    _sessionTopicController.dispose();

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

  Future<void> _pickTime({required TextEditingController controller}) async {
    if (_isPickingTime) return;
    _isPickingTime = true;

    try {
      FocusManager.instance.primaryFocus?.unfocus();
      final selected = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (selected == null) return;
      if (!mounted) return;
      controller.text = selected.format(context);
    } finally {
      _isPickingTime = false;
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  void _addSessionDraft() {
    if (_selectedSessionDay == null ||
        _sessionStartTimeController.text.trim().isEmpty ||
        _sessionEndTimeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng chọn ngày và giờ buổi học')),
      );
      return;
    }

    setState(() {
      _sessionDrafts.add({
        'daysOfWeek': _selectedSessionDay!,
        'startTime': _sessionStartTimeController.text.trim(),
        'endTime': _sessionEndTimeController.text.trim(),
        'topic': _sessionTopicController.text.trim(),
      });
      _selectedSessionDay = null;
      _sessionStartTimeController.clear();
      _sessionEndTimeController.clear();
      _sessionTopicController.clear();
    });
  }

  Future<void> _createSessionsForClass(String classId) async {
    for (final session in _sessionDrafts) {
      await ApiService.post(
        '/identity/class_sessions',
        token: authService.accessToken,
        body: {
          'classId': classId,
          'startTime': formatTime(session['startTime']!),
          'endTime': formatTime(session['endTime']!),
          'daysOfWeek': session['daysOfWeek'],
          'topic': session['topic'] ?? '',
        },
      );
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
                        child: FutureBuilder<Map<String, dynamic>>(
                          future: _teachersFuture,
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return DropdownButtonFormField2<String>(
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
                                ),
                                hint: Text('Chọn giáo viên'),
                                isExpanded: true,
                                items: (snapshot.data!['result']['content'] as List)
                                    .map<DropdownMenuItem<String>>((teacher) {
                                      return DropdownMenuItem<String>(
                                        value: teacher['id']?.toString(),
                                        child: Text(
                                          '${teacher['lastName'] ?? ''} ${teacher['firstName'] ?? ''}',
                                        ),
                                      );
                                    })
                                    .toList(),
                                onChanged: (value) {
                                  _selectedTeacherId = value;
                                },
                              );
                            } else {
                              return Center(
                                child: const CircularProgressIndicator(),
                              );
                            }
                          },
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(child: Container()),
                      SizedBox(width: 12),
                      Expanded(child: Container()),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                Padding(
                  padding: EdgeInsets.only(left: 50, right: 50),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Buổi học',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: DropdownButtonFormField2<String>(
                              value: _selectedSessionDay,
                              decoration: InputDecoration(
                                labelText: 'Ngày trong tuần',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              hint: Text('Chọn ngày'),
                              isExpanded: true,
                              items: days.map((day) {
                                return DropdownMenuItem<String>(
                                  value: day['id']?.toString(),
                                  child: Text(day['name'] ?? ''),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() => _selectedSessionDay = value);
                              },
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _sessionStartTimeController,
                              readOnly: true,
                              onTap: () async => _pickTime(
                                controller: _sessionStartTimeController,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Giờ bắt đầu',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                suffixIcon: Icon(Icons.access_time),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _sessionEndTimeController,
                              readOnly: true,
                              onTap: () async => _pickTime(
                                controller: _sessionEndTimeController,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Giờ kết thúc',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                suffixIcon: Icon(Icons.access_time),
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
                              controller: _sessionTopicController,
                              decoration: InputDecoration(
                                labelText: 'Chủ đề',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _addSessionDraft,
                            icon: Icon(Icons.add_outlined),
                            label: Text('Thêm buổi học'),
                          ),
                        ],
                      ),
                      if (_sessionDrafts.isNotEmpty) ...[
                        SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (var i = 0; i < _sessionDrafts.length; i++)
                              InputChip(
                                label: Text(
                                  '${getDayShortName(_sessionDrafts[i]['daysOfWeek'] ?? '')} '
                                  '${_sessionDrafts[i]['startTime']} - ${_sessionDrafts[i]['endTime']}',
                                ),
                                onDeleted: () {
                                  setState(() {
                                    _sessionDrafts.removeAt(i);
                                  });
                                },
                              ),
                          ],
                        ),
                      ],
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
                          _classNameError = _classNameController.text
                              .trim()
                              .isEmpty;
                          _startDateError = _startDateController.text
                              .trim()
                              .isEmpty;
                          _endDateError = _endDateController.text
                              .trim()
                              .isEmpty;
                          _teacherError = _selectedTeacherId == null;
                        });

                        if (_classNameError ||
                            _startDateError ||
                            _endDateError ||
                            _teacherError) {
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
                          final classId = data['result']?['id']?.toString();
                          if (classId != null && _sessionDrafts.isNotEmpty) {
                            await _createSessionsForClass(classId);
                          }
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
