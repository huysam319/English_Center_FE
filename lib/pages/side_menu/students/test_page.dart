import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../exceptions/unauthorized_exception.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/layout/layout.dart';

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  late final Future<List<Map<String, dynamic>>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadTests();
  }

  Future<List<Map<String, dynamic>>> _loadTests() async {
    final response = await ApiService.get(
      '/identity/ai-reading-assignments/student?kind=TEST',
      token: authService.accessToken,
    );
    if (response.statusCode == 401) {
      await authService.clearAuth();
      throw UnauthorizedException();
    }
    final decoded = jsonDecode(response.body);
    final result = decoded['result'];
    if (result is List) {
      return result
          .whereType<Map>()
          .map((item) => item.map((key, value) => MapEntry('$key', value)))
          .toList();
    }
    return [];
  }

  String _formatInstant(dynamic value) {
    if (value == null) return '';
    final date = DateTime.tryParse(value.toString());
    if (date == null) return value.toString();
    return DateFormat('dd/MM/yyyy HH:mm').format(date.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    return Title(
      color: Colors.black,
      title: 'Danh sách đề thi',
      child: SiteLayout(
        menuNo: 6,
        content: Container(
          color: Colors.white,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _dataFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                final err = snapshot.error;
                if (err is UnauthorizedException) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) context.go('/login');
                  });
                  return const SizedBox.shrink();
                }
                return const Center(child: Text('Lỗi tải danh sách đề thi'));
              }

              final tests = snapshot.data ?? [];
              if (tests.isEmpty) {
                return const Center(child: Text('Chưa có đề thi nào'));
              }

              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const Text(
                    'Đề thi được giao',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: tests.map((test) {
                      final locked = test['locked'] == true;
                      final submitted = test['mySubmissionStatus'] != null;
                      final score = test['myScore'];
                      return SizedBox(
                        width: 360,
                        child: Material(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(color: Color(0xFFE0E0E0)),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => context.go('/test/${test['id']}'),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          test['title']?.toString() ?? '',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      Chip(
                                        label: Text(
                                          locked ? 'Đã khóa' : 'Đang mở',
                                        ),
                                        backgroundColor: locked
                                            ? const Color(0xFFFFE7E7)
                                            : const Color(0xFFE8F5E9),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text('Lớp: ${test['className'] ?? ''}'),
                                  Text(
                                    'Hạn nộp: ${_formatInstant(test['dueAt'])}',
                                  ),
                                  const SizedBox(height: 12),
                                  if (score != null)
                                    Text(
                                      'Điểm: $score / 100',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    )
                                  else if (submitted)
                                    const Text('Đã nộp, đang chờ chấm')
                                  else
                                    const Text('Chưa nộp bài'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
