import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/student_tests/student_tests_list.dart';
import '../../../exceptions/unauthorized_exception.dart';
import '../../../widgets/layout/layout.dart';

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

Future<Map<String, dynamic>> _loadTests() async {
  var response = testsList;
  return response;
}

class _TestPageState extends State<TestPage> {
  late final Future<Map<String, dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadTests();
  }

  @override
  Widget build(BuildContext context) {
    return Title(
      color: Colors.black,
      title: "Danh sách đề thi",
      child: SiteLayout(
        menuNo: 6,
        content: Container(
          color: Colors.white,
          child: Padding(
            padding: EdgeInsets.fromLTRB(50, 16, 50, 16),
            child: Column(
              children: [
                Expanded(
                  child: FutureBuilder<Map<String, dynamic>>(
                    future: _dataFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        final err = snapshot.error;
                        if (err is UnauthorizedException) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) context.go('/login');
                          });
                          return SizedBox.shrink();
                        }
                        return Center(
                          child: Text('Lỗi tải thông tin đề thi'),
                        );
                      } else if (snapshot.hasData) {
                        final result = snapshot.data!['result']['content'];
                        if (result is! List) {
                          return Center(
                            child: Text('Dữ liệu đề thi không hợp lệ'),
                          );
                        }

                        final tests = result
                            .whereType<Map>()
                            .map(
                              (e) => e.map((k, v) => MapEntry(k.toString(), v)),
                            )
                            .toList();

                        if (tests.isEmpty) {
                          return Center(
                            child: Text('Chưa có đề thi nào'),
                          );
                        }

                        return GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.5,
                          ),
                          itemCount: tests.length,
                          itemBuilder: (context, index) {
                            final classItem = tests[index];
                            return Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () {
                                  context.go('/test/${classItem['id']}');
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.blue.shade300,
                                              Colors.blue.shade500,
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            classItem['name'] ?? '',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      } else {
                        return Center(child: Text('Không có dữ liệu'));
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}