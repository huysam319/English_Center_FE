import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../exceptions/unauthorized_exception.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/layout/layout.dart';

class StudentClassItemPage extends StatefulWidget {
  final String classId;

  const StudentClassItemPage({super.key, required this.classId});

  @override
  State<StudentClassItemPage> createState() => _StudentClassItemPageState();
}

class _StudentClassItemPageState extends State<StudentClassItemPage> {
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

  Map<String, dynamic>? _extractMap(dynamic value) {
    if (value is Map) {
      return value.map((key, value) => MapEntry('$key', value));
    }
    return null;
  }

  List<Map<String, dynamic>> _extractList(dynamic value) {
    final rawList = value is Map ? value['content'] : value;
    if (rawList is! List) {
      return [];
    }
    return rawList
        .whereType<Map>()
        .map((item) => item.map((key, value) => MapEntry('$key', value)))
        .toList();
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
          final result = _extractMap(snapshot.data!['result']);
          if (result == null) {
            content = Center(
              child: Text('Dá»¯ liá»‡u lá»›p há»c khÃ´ng há»£p lá»‡'),
            );
          } else {
            className = result['name']?.toString() ?? '';

          content = Column(
            children: [
              Text(
                'Danh sách bài tập',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 10),
              FutureBuilder(
                future: _exercisesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Lỗi tải danh sách bài tập'));
                  } else if (snapshot.hasData) {
                    final result = _extractList(snapshot.data!['result']);
                    if (result.isEmpty) {
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
                          border: Border.all(color: Color(0xFFE0E0E0)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          title: Text(
                            exercises[index]['title']?.toString() ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Loại: ${exercises[index]['type'] ?? 'EXERCISE'}'),
                              if (exercises[index]['skill'] != null)
                                Text('Kỹ năng: ${exercises[index]['skill']}'),
                            ],
                          ),
                          onTap: () {
                            context.go('/exercise/${exercises[index]['id']}');
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
        }

        return Title(
          color: Colors.black,
          title: "Lớp $className",
          child: SiteLayout(
            menuNo: 3,
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
