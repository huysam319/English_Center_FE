import 'dart:convert';

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/days_list.dart';
import '../../../exceptions/unauthorized_exception.dart';
import '../../../router/app_router.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/layout/layout.dart';

class AddEnrolmentPage extends StatefulWidget {
  final String studentId;

  const AddEnrolmentPage({super.key, required this.studentId});

  @override
  State<AddEnrolmentPage> createState() => _AddEnrolmentPageState();
}

Future<List<Map<String, dynamic>>> _loadAllClasses(String filter, int skip, int take) async {
  final page = skip ~/ take;
  try {
    var response = await ApiService.get(
      "/identity/courses/allcourses?page=$page&size=$take",
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
          '/identity/courses/allcourses?page=$page&size=$take',
          token: authService.accessToken,
        );
      } else {
        await authService.clearAuth();
        throw UnauthorizedException();
      }
    }

    final data = jsonDecode(response.body);
    if (data != null && data['result'] != null && data['result']['content'] != null) {
      return List<Map<String, dynamic>>.from(data['result']['content']);
    }
    return [];
  } on UnauthorizedException {
    await authService.clearAuth();
    appRouter.go('/login');
    return <Map<String, dynamic>>[];
  } catch (e) {
    return <Map<String, dynamic>>[];
  }
}

Future<List<Map<String, dynamic>>> _loadAllClassSessions(String classId, String filter, int skip, int take) async {
  final page = skip ~/ take;
  try {
    var response = await ApiService.get(
      "/identity/class_sessions/allclasssessions/$classId?page=$page&size=$take",
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
          '/identity/class_sessions/allclasssessions/$classId?page=$page&size=$take',
          token: authService.accessToken,
        );
      } else {
        await authService.clearAuth();
        throw UnauthorizedException();
      }
    }

    final data = jsonDecode(response.body);
    if (data != null && data['result'] != null && data['result']['content'] != null) {
      return List<Map<String, dynamic>>.from(data['result']['content']);
    }
    return [];
  } on UnauthorizedException {
    await authService.clearAuth();
    appRouter.go('/login');
    return <Map<String, dynamic>>[];
  } catch (e) {
    return <Map<String, dynamic>>[];
  }
}

class _AddEnrolmentPageState extends State<AddEnrolmentPage> {
  final _formKey = GlobalKey<FormState>();
  final _classSessionDropdownKey = GlobalKey<DropdownSearchState<Map<String, dynamic>>>();
  String? _selectedClassId;
  Map<String, dynamic>? _selectedClass;
  List<Map<String, dynamic>> _selectedClassSessions = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Title(
      color: Colors.black,
      title: 'Thêm vào lớp học',
      child: SiteLayout(
        menuNo: 16,
        content: SelectionArea(
          child: Container(
            color: Colors.white,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_circle_left_outlined, size: 32),
                          onPressed: () {
                            context.go('/student-management/${widget.studentId}');
                          },
                        ),
                        Text(
                          "Thêm vào lớp học",
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
                            child: DropdownSearch<Map<String, dynamic>>(
                              items: (filter, loadProps) => _loadAllClasses(filter, loadProps!.skip, loadProps.take),
                              itemAsString: (item) => item['name'] ?? '',
                              compareFn: (a, b) => a['id'] == b['id'],
                              popupProps: PopupProps.menu(
                                disableFilter: true,
                                showSearchBox: false,
                                infiniteScrollProps: InfiniteScrollProps(
                                  loadProps: LoadProps(skip: 0, take: 10),
                                ),
                                constraints: BoxConstraints(maxHeight: 150),
                                scrollbarProps: ScrollbarProps(
                                  thumbVisibility: true,
                                ),
                                containerBuilder: (context, popupWidget) => Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: Colors.white,
                                  ),
                                  child: popupWidget,
                                ),
                                itemBuilder: (context, item, isDisabled, isSelected) => Container(
                                  height: 40,
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    item['name'] ?? '',
                                    style: TextStyle(
                                      color: isSelected ? Color(0xFF1E40AF) : Colors.black,
                                      fontSize: 14,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                              autoValidateMode: AutovalidateMode.onUserInteraction,
                              decoratorProps: DropDownDecoratorProps(
                                decoration: InputDecoration(
                                  labelText: 'Lớp học',
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
                              ),
                              selectedItem: _selectedClass,
                              onChanged: (value) {
                                _selectedClass = value;
                                _selectedClassId = value?['id']?.toString();
                              },
                              validator: (value) => value == null ? 'Vui lòng chọn lớp học' : null,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: DropdownSearch<Map<String, dynamic>>.multiSelection(
                              key: _classSessionDropdownKey,
                              items: (filter, loadProps) => _loadAllClassSessions(_selectedClassId ?? '', filter, loadProps!.skip, loadProps.take),
                              itemAsString: (item) => '${getDayShortName(item['daysOfWeek'])} ${item['startTime']} - ${item['endTime']}',
                              compareFn: (a, b) => a['id'] == b['id'],
                              dropdownBuilder: (context, selectedItems) {
                                if (selectedItems.isEmpty) {
                                  return SizedBox.shrink();
                                }
                                return Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: selectedItems.map((item) {
                                    return Chip(
                                      label: Text(
                                        '${getDayShortName(item['daysOfWeek'])} ${item['startTime']} - ${item['endTime']}',
                                        style: TextStyle(fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      padding: EdgeInsets.symmetric(horizontal: 4),
                                      visualDensity: VisualDensity.compact,
                                    );
                                  }).toList(),
                                );
                              },
                              popupProps: PopupPropsMultiSelection.menu(
                                disableFilter: true,
                                showSearchBox: false,
                                validationBuilder: (context, selectedItems) {
                                  return Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          _classSessionDropdownKey.currentState?.changeSelectedItems(selectedItems);
                                          _classSessionDropdownKey.currentState?.closeDropDownSearch();
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Color(0xFF1E40AF),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                                          elevation: 0,
                                        ),
                                        child: Text('OK'),
                                      ),
                                    ),
                                  );
                                },
                                infiniteScrollProps: InfiniteScrollProps(
                                  loadProps: LoadProps(skip: 0, take: 10),
                                ),
                                constraints: BoxConstraints(maxHeight: 150),
                                scrollbarProps: ScrollbarProps(
                                  thumbVisibility: true,
                                ),
                                containerBuilder: (context, popupWidget) => Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: Colors.white,
                                  ),
                                  child: popupWidget,
                                ),
                                itemBuilder: (context, item, isDisabled, isSelected) => Container(
                                  height: 40,
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    '${getDayShortName(item['daysOfWeek'])} ${item['startTime']} - ${item['endTime']}',
                                    style: TextStyle(
                                      color: isSelected ? Color(0xFF1E40AF) : Colors.black,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                              autoValidateMode: AutovalidateMode.onUserInteraction,
                              decoratorProps: DropDownDecoratorProps(
                                decoration: InputDecoration(
                                  labelText: 'Buổi học',
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
                              ),
                              selectedItems: _selectedClassSessions,
                              onChanged: (value) {
                                _selectedClassSessions = value;
                              },
                              validator: (value) => value == null || value.isEmpty ? 'Vui lòng chọn buổi học' : null,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Container(),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(child: Container()),
                        ElevatedButton(
                          onPressed: () async {
                            if (!_formKey.currentState!.validate()) {
                              return;
                            }

                            for (var classSession in _selectedClassSessions) {
                              var response = await ApiService.post(
                                '/identity/enrolls',
                                token: authService.accessToken,
                                body: {
                                  'studentId': widget.studentId,
                                  'classId': _selectedClassId,
                                  'classSessionId': classSession['id'],
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
                                    '/identity/enrolls',
                                    token: authService.accessToken,
                                    body: {
                                      'studentId': widget.studentId,
                                      'classId': _selectedClassId,
                                      'classSessionId': classSession['id'],
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
                                  SnackBar(content: Text('Thêm học viên vào lớp học thành công')),
                                );
                                context.go('/student-management/${widget.studentId}');
                              } else {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Thêm học viên vào lớp học thất bại')),
                                );
                              }
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
                          child: Text('Thêm vào lớp học'),
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
      ),
    );
  }
}