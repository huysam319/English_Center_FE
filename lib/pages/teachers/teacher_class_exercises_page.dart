import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../exceptions/unauthorized_exception.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/layout/layout.dart';

class TeacherClassExercisesPage extends StatefulWidget {
  const TeacherClassExercisesPage({super.key, required this.classId});

  final String classId;

  @override
  State<TeacherClassExercisesPage> createState() => _TeacherClassExercisesPageState();
}

class _TeacherClassExercisesPageState extends State<TeacherClassExercisesPage> {
  late final Future<Map<String, dynamic>> _classDataFuture;
  late final Future<Map<String, dynamic>> _exercisesFuture;

  @override
  void initState() {
    super.initState();
    _classDataFuture = _loadClassInfo(widget.classId);
    _exercisesFuture = _loadExercises(widget.classId);
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

  Future<Map<String, dynamic>> _loadExercises(String classId) async {
    var response = await ApiService.get(
      '/identity/assessments/class/$classId',
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
          '/identity/assessments/class/$classId',
          token: authService.accessToken,
        );
      } else {
        await authService.clearAuth();
        throw UnauthorizedException();
      }
    }

    return jsonDecode(response.body);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _classDataFuture,
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
                  Expanded(child: Container()),
                  ElevatedButton(
                    onPressed: () {
                      context.go('/classes/${widget.classId}/create-exercise');
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
                        Text('Thêm bài tập'),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20),

              FutureBuilder(
                future: _exercisesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Lỗi tải danh sách bài tập'));
                  } else if (snapshot.hasData) {
                    final result = snapshot.data!['result'];
                    if (result is! List) {
                      return Center(
                        child: Text('Dữ liệu bài tập không hợp lệ'),
                      );
                    }

                    final exercises = result
                        .whereType<Map>()
                        .map(
                          (e) => e.map((k, v) => MapEntry(k.toString(), v)),
                        )
                        .toList();
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) => Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: ListTile(
                          title: Text(
                            exercises[index]['title']?.toString() ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () {
                            context.go('/classes/${widget.classId}/exercises/${exercises[index]['id']}');
                          },
                        ),
                      ),
                      separatorBuilder: (context, index) => SizedBox(
                        height: 10,
                      ),
                      itemCount: exercises.length,
                    );
                  }
                  return SizedBox.shrink();
                },
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
                child: ListView(
                  children: [
                    Padding(
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
                                  context.go('/classes/${widget.classId}/exercises');
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
                                child: Text("Bài tập"),
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