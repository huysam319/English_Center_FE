import 'dart:convert';

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

class _AddEnrolmentPageState extends State<AddEnrolmentPage> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedClassId;
  Map<String, dynamic>? _selectedClass;

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
                            child: Container(),
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

                            var response = await ApiService.post(
                              '/identity/enrolls',
                              token: authService.accessToken,
                              body: {
                                'studentId': widget.studentId,
                                'classId': _selectedClassId,
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