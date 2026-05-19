import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../exceptions/unauthorized_exception.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/layout/layout.dart';

class LearningProfilePage extends StatefulWidget {
  const LearningProfilePage({super.key});

  @override
  State<LearningProfilePage> createState() => _LearningProfilePageState();
}

class _LearningProfilePageState extends State<LearningProfilePage> {
  late final Future<Map<String, dynamic>> _dataFuture;
  final ScrollController _horizontalController = ScrollController();

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadUserLearningProfile();
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _loadUserLearningProfile() async {
    var response = await ApiService.get(
      '/identity/learning-profile',
      token: authService.accessToken,
    );

    if (response.statusCode == 401) {
      var refreshResponse = await ApiService.post(
        '/identity/auth/refresh',
        body: { 'token': authService.accessToken },
      );

      var refreshData = jsonDecode(refreshResponse.body);
      if (refreshData['code'] == 1000) {
        final newToken = refreshData['result']['token'];
        await authService.setAuth(newToken);

        response = await ApiService.get(
          '/identity/learning-profile',
          token: authService.accessToken,
        );
      } else {
        await authService.clearAuth();
        throw UnauthorizedException();
      }
    }

    return jsonDecode(response.body);
  }

  static String _asCellText(Object? value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is num || value is bool) return value.toString();
    return jsonEncode(value);
  }

  ButtonStyle _tabStyle(bool active) {
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.all(
        active ? Color(0xFF1E40AF) : Color(0xFFF1F3F4),
      ),
      foregroundColor: WidgetStateProperty.all(
        active ? Colors.white : Color(0xFF1E40AF),
      ),
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      minimumSize: WidgetStateProperty.all(Size(150, 50)),
      elevation: WidgetStateProperty.all(0),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    );
  }

  Widget tab(String label, String path, {bool active = false}) {
    return Padding(
      padding: EdgeInsets.only(right: 2),
      child: ElevatedButton(
        onPressed: () => context.go(path),
        style: _tabStyle(active),
        child: Text(label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Title(
      color: Colors.black,
      title: "Hồ sơ học tập",
      child: SiteLayout(
        menuNo: 0, 
        title: "Hồ sơ học tập",
        content: Container(
          color: Colors.white,
          padding: EdgeInsets.all(50),
          child: SelectionArea(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _dataFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  final err = snapshot.error;
                  if (err is UnauthorizedException) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) context.go('/login');
                    });
                    return SizedBox.shrink();
                  }
                  return Center(child: Text('Lỗi tải thông tin người dùng'));
                }
                final data = snapshot.data!['result'];
                final List errorStats = data['learningErrorStatResponses'] ?? [];
                return ListView(
                  children: [
                    Row(
                      children: [
                        tab('Thông tin cá nhân', '/profile'),
                        tab('Hồ sơ học viên', '/learning-profile', active: true),
                      ],
                    ),
                    
                    SizedBox(height: 30,),

                    Row(
                      children: [
                        SizedBox(width: 200, child: Text("Tổng số lần gây lỗi:")),
                        Text('${data['totalErrors'] ?? 0}'),
                      ],
                    ),
                    Row(
                      children: [
                        SizedBox(width: 200, child: Text("Lần cập nhật gần nhất:")),
                        Text(data['lastUpdated'] != null
                          ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(data['lastUpdated']).toLocal())
                          : ''
                        ),
                      ],
                    ),

                    SizedBox(height: 30,),

                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        "Danh sách các lỗi sai gặp phải",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 10,),

                    LayoutBuilder(
                      builder: (context, constraints) {
                        return Scrollbar(
                          controller: _horizontalController,
                          thumbVisibility: true,
                          interactive: true,
                          notificationPredicate: (notification) =>
                              notification.metrics.axis == Axis.horizontal,
                          scrollbarOrientation: ScrollbarOrientation.bottom,
                          child: SingleChildScrollView(
                            controller: _horizontalController,
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: constraints.maxWidth - 100,
                              ),
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(
                                  Color(0xFF1E40AF),
                                ),
                                headingRowHeight: 45,
                                dataRowMinHeight: 40,
                                dataRowMaxHeight: 40,
                                columns: [
                                  DataColumn(
                                    label: DefaultTextStyle.merge(
                                      child: Text(
                                        "Mã lỗi",
                                        selectionColor: Color(0xFF60A5FA),
                                      ),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: DefaultTextStyle.merge(
                                      child: Text(
                                        "Mô tả lỗi",
                                        selectionColor: Color(0xFF60A5FA),
                                      ),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: DefaultTextStyle.merge(
                                      child: Text(
                                        "Số phần phạm lỗi",
                                        selectionColor: Color(0xFF60A5FA),
                                      ),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: DefaultTextStyle.merge(
                                      child: Text(
                                        "Lần phạm lỗi gần nhất",
                                        selectionColor: Color(0xFF60A5FA),
                                      ),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),DataColumn(
                                    label: DefaultTextStyle.merge(
                                      child: Text(
                                        "Lần sửa lỗi gần nhất",
                                        selectionColor: Color(0xFF60A5FA),
                                      ),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                                rows: [
                                  for (final errorStat in errorStats)
                                  DataRow(
                                    cells: [
                                      DataCell(
                                        Text(
                                          _asCellText(errorStat['errorType']),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          _asCellText(errorStat['errorDescription']),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          _asCellText(errorStat['totalCount']),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          errorStat['lastSeen'] != null
                                            ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(errorStat['lastSeen'].toString()).toLocal())
                                            : "",
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          errorStat['lastCorrected'] != null
                                            ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(errorStat['lastCorrected'].toString()).toLocal())
                                            : "",
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}