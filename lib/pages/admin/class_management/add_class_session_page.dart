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

class AddClassSessionPage extends StatefulWidget {
  final String classId;

  const AddClassSessionPage({super.key, required this.classId});

  @override
  State<AddClassSessionPage> createState() => _AddClassSessionPageState();
}

class _AddClassSessionPageState extends State<AddClassSessionPage> {
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();
  final TextEditingController _topicController = TextEditingController();

  bool _startTimeError = false;
  bool _endTimeError = false;
  bool _topicError = false;
  bool _isPickingTime = false;

  String? _selectedDay;
  bool _dayError = false;

  @override
  void initState() {
    super.initState();
    _startTimeController.addListener(_onStartTimeChanged);
    _endTimeController.addListener(_onEndTimeChanged);
  }

  void _onStartTimeChanged() {
    if (_startTimeError && _startTimeController.text.trim().isNotEmpty) {
      setState(() {
        _startTimeError = false;
      });
    }
  }

  void _onEndTimeChanged() {
    if (_endTimeError && _endTimeController.text.trim().isNotEmpty) {
      setState(() {
        _endTimeError = false;
      });
    }
  }

  @override
  void dispose() {
    _startTimeController.dispose();
    _endTimeController.dispose();

    _startTimeController.removeListener(_onStartTimeChanged);
    _endTimeController.removeListener(_onEndTimeChanged);
    super.dispose();
  }

  Future<void> _pickTime({
    required TextEditingController controller,
    TimeOfDay? initialTime,
  }) async {
    if (_isPickingTime) return;
    _isPickingTime = true;

    try {
      FocusManager.instance.primaryFocus?.unfocus();
      final selected = await showTimePicker(
        context: context,
        initialTime: initialTime ?? TimeOfDay.now(),
      );

      if (selected == null) return;
      controller.text = selected.format(context);
    } finally {
      _isPickingTime = false;
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Title(
      color: Colors.black,
      title: "Thêm buổi học",
      child: SiteLayout(
        menuNo: 14,
        content: SelectionArea(
          child: Container(
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
                          context.go('/class-management/${widget.classId}');
                        },
                      ),
                      Text(
                        "Thêm buổi học",
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
                            controller: _startTimeController,
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: 'Giờ bắt đầu',
                              errorText: _startTimeError
                                  ? 'Vui lòng chọn giờ bắt đầu'
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
                              suffixIcon: Icon(Icons.access_time),
                            ),
                            onTap: () async {
                              await _pickTime(controller: _startTimeController);
                            },
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _endTimeController,
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: 'Giờ kết thúc',
                              errorText: _endTimeError
                                  ? 'Vui lòng chọn giờ kết thúc'
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
                              suffixIcon: Icon(Icons.access_time),
                            ),
                            onTap: () async {
                              await _pickTime(controller: _endTimeController);
                            },
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField2<String>(
                            value: _selectedDay,
                            decoration: InputDecoration(
                              labelText: 'Ngày trong tuần',
                              errorText: _dayError
                                  ? 'Vui lòng chọn ngày trong tuần'
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
                            items: days.map((day) {
                              return DropdownMenuItem<String>(
                                value: day['id']?.toString(),
                                child: Text(day['name'] ?? ''),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedDay = value;
                                if (value != null) { _dayError = false; }
                              });
                            },
                            hint: Text('Chọn ngày trong tuần'),
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
                            controller: _topicController,
                            decoration: InputDecoration(
                              labelText: 'Chủ đề',
                              errorText: _topicError
                                  ? 'Vui lòng nhập chủ đề'
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
                        Expanded(child: Container(),),
                        SizedBox(width: 12),
                        Expanded(child: Container(),),
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
                            _startTimeError = _startTimeController.text.trim().isEmpty;
                            _endTimeError = _endTimeController.text.trim().isEmpty;
                            _dayError = _selectedDay == null;
                            _topicError = _topicController.text.trim().isEmpty;
                          });

                          if (_startTimeError || _endTimeError || _dayError || _topicError) {
                            return;
                          }

                          var response = await ApiService.post(
                            '/identity/class_sessions',
                            token: authService.accessToken,
                            body: {
                              'classId': widget.classId,
                              'startTime': formatTime(_startTimeController.text),
                              'endTime': formatTime(_endTimeController.text),
                              'daysOfWeek': _selectedDay,
                              'topic': _topicController.text,
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
                                '/identity/class_sessions',
                                token: authService.accessToken,
                                body: {
                                  'classId': widget.classId,
                                  'startTime': formatTime(_startTimeController.text),
                                  'endTime': formatTime(_endTimeController.text),
                                  'daysOfWeek': _selectedDay,
                                  'topic': _topicController.text,
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
                              SnackBar(content: Text('Tạo buổi học thành công')),
                            );
                            context.go('/class-management/${widget.classId}');
                          } else {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Tạo buổi học thất bại')),
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
                        child: Text('Tạo buổi học'),
                      ),
                      Expanded(child: Container()),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}