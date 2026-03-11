import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../exceptions/unauthorized_exception.dart';
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
    var refreshResponse = await ApiService.post(
      '/identity/auth/refresh',
      body: {'token': authService.accessToken},
    );

    var refreshData = jsonDecode(refreshResponse.body);
    if (refreshData['code'] == 1000) {
      final newToken = refreshData['result']['token'];
      await authService.setAuth(newToken);

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
  late final Future<Map<String, dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadStudentInfo(widget.studentId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _dataFuture,
      builder: (context, snapshot) {
        Widget content = Container();
        String studentName = "";
        if (snapshot.connectionState == ConnectionState.waiting) {
          content = Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          final err = snapshot.error;
          if (err is UnauthorizedException) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) context.go('/login');
            });
            content = SizedBox.shrink();
          } else {
            content = Center(
              child: Text('Lỗi tải thông tin lớp học'),
            );
          }
        } else if (snapshot.hasData) {
          final result = snapshot.data!['result'];
          studentName = '${result['lastName']} ${result['firstName']}';

          content = Column(
            children: [
              Row(
                children: [
                  SizedBox(width: 150, child: Text('ID'),),
                  Text('${result['id']}'),
                ],
              ),
              Row(
                children: [
                  SizedBox(width: 150, child: Text('Tên đăng nhập'),),
                  Text('${result['username']}'),
                ],
              ),
              Row(
                children: [
                  SizedBox(width: 150, child: Text('Họ và tên'),),
                  Text('${result['lastName']} ${result['firstName']}'),
                ],
              ),
              Row(
                children: [
                  SizedBox(width: 150, child: Text('Ngày sinh'),),
                  Text(result['dob']),
                ],
              ),
            ],
          );
        }

        return Title(
          color: Colors.black,
          title: "Học viên $studentName",
          child: SiteLayout(
            menuNo: 16,
            content: widget.studentId.isEmpty? 
              Container(
                color: Colors.white,
              ) :
              Container(
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
                              context.go('/student-management');
                            },
                          ),
                          Text(
                            "Thông tin học viên",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      Row(
                        children: [
                          Expanded(child: Container(),),
                          ElevatedButton(
                            onPressed: () {
                              context.go('/student-management/${widget.studentId}/add-enrolment');
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
                            child: Row(
                              children: [
                                Icon(Icons.add_outlined, size: 20),
                                SizedBox(width: 4),
                                Text('Thêm vào lớp học'),
                              ],
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 20,),

                      Padding(
                        padding: EdgeInsets.fromLTRB(30, 0, 30, 0),
                        child: content,
                      ),
                    ],
                  ),
                ),
              ),
          ),
        );
      }
    );
  }
}