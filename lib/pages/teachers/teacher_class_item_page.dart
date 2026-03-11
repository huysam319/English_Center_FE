import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../exceptions/unauthorized_exception.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/layout/layout.dart';

class TeacherClassItemPage extends StatefulWidget {
  final String classId;

  const TeacherClassItemPage({super.key, required this.classId});

  @override
  State<TeacherClassItemPage> createState() => _TeacherClassItemPageState();
}

Future<Map<String, dynamic>> _loadClassInfo(String id) async {
  var response = await ApiService.get(
    '/identity/courses/$id',
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
        '/identity/courses/$id',
        token: authService.accessToken,
      );
    } else {
      await authService.clearAuth();
      throw UnauthorizedException();
    }
  }

  return jsonDecode(response.body);
}

class _TeacherClassItemPageState extends State<TeacherClassItemPage> {
  late final Future<Map<String, dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadClassInfo(widget.classId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _dataFuture,
      builder: (context, snapshot) {
        Widget content = Container();
        String className = "";
        if (snapshot.connectionState == ConnectionState.waiting) {
          content = Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          final err = snapshot.error;
          if (err is UnauthorizedException) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) context.go('/login');
            });
            content = SizedBox.shrink();
          }
          content = Center(
            child: Text('Lỗi tải thông tin lớp học'),
          );
        } else if (snapshot.hasData) {
          final result = snapshot.data!['result'];
          className = result['name'];

          content = Column(
            children: [
              Row(
                children: [
                  SizedBox(width: 150, child: Text('Tên lớp'),),
                  Text('${result['name']}'),
                ],
              ),
              Row(
                children: [
                  SizedBox(width: 150, child: Text('Ngày bắt đầu'),),
                  Text('${result['startDate']}'),
                ],
              ),
              Row(
                children: [
                  SizedBox(width: 150, child: Text('Ngày kết thúc'),),
                  Text('${result['endDate']}'),
                ],
              ),
            ],
          );
        }

        return Title(
          color: Colors.black,
          title: "Lớp $className",
          child: SiteLayout(
            menuNo: 13,
            content: SelectionArea(
              child: Container(
                color: Colors.white,
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Lớp $className',
                          style: TextStyle(
                            color: Color(0xFF1E40AF),
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),

                      SizedBox(height: 20,),

                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              context.go('/classes/${widget.classId}');
                            }, 
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.all(Color(0xFF1E40AF)),
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
                            child: Text("Lớp học"),
                          ),
                          SizedBox(width: 2,),
                          ElevatedButton(
                            onPressed: () {
                              context.go('/classes/${widget.classId}/students');
                            }, 
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.all(Color(0xFFF1F3F4)),
                              foregroundColor: WidgetStateProperty.all(Color(0xFF1E40AF)),
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
                            child: Text("Học viên"),
                          ),
                          SizedBox(width: 2,),
                          ElevatedButton(
                            onPressed: () {
                              context.go('/classes/${widget.classId}/attendances');
                            }, 
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.all(Color(0xFFF1F3F4)),
                              foregroundColor: WidgetStateProperty.all(Color(0xFF1E40AF)),
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
                            child: Text("Điểm danh"),
                          ),
                        ],
                      ),

                      SizedBox(height: 20,),

                      content,
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }
    );
  }
}