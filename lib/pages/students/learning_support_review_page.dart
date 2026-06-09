import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../exceptions/unauthorized_exception.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/layout/layout.dart';

class LearningSupportReviewPage extends StatefulWidget {
  const LearningSupportReviewPage({super.key});

  @override
  State<LearningSupportReviewPage> createState() => _LearningSupportReviewPageState();
}

class _LearningSupportReviewPageState extends State<LearningSupportReviewPage> {
  late final Future<Map<String, dynamic>> _reviewDataFuture;

  @override
  void initState() {
    super.initState();
    _reviewDataFuture = _loadReviewData();
  }

  Future<Map<String, dynamic>> _loadReviewData() async {
    var response = await ApiService.get(
      "/identity/learning-support/review",
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
          "/identity/learning-support/review",
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
    return Title(
      color: Colors.black,
      title: "Hỗ trợ ôn tập lỗi sai",
      child: SiteLayout(
        menuNo: 9,
        content: Container(
          color: Colors.white,
          child: SelectionArea(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _reviewDataFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text("Không thể tải nội dung ôn tập"),
                  );
                }

                if (!snapshot.hasData) {
                  return Center(
                    child: Text("Không có dữ liệu"),
                  );
                };

                final data = snapshot.data!['result'];
                final List skills = data['errorsToReview'];
                final Map<String, dynamic> reviewContent = data['reviewContent'];

                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      "Nội dung ôn tập lỗi sai",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E40AF),
                      ),
                    ),

                    SizedBox(height: 10),

                    Text(
                      'Hãy bắt đầu ôn tập để khắc phục các lỗi sai trong quá trình học tập của bạn.',
                      style: TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                      ),
                    ),

                    SizedBox(height: 20),

                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: skills.map((skill) {
                        return Chip(
                          label: Text(skill['description']),
                          backgroundColor:
                            skill['errorType'].toString().startsWith('GRAMMAR') ? Colors.red.shade50
                              : skill['errorType'].toString().startsWith('VOCAB') ? Colors.green.shade50
                              : skill['errorType'].toString().startsWith('COHERENCE') ? Colors.orange.shade50
                              : skill['errorType'].toString().startsWith('TASK') ? Colors.purple.shade50
                              : Colors.blue.shade50,
                        );
                      }).toList(),
                    ),

                    SizedBox(height: 30),

                    ...skills.map((skill) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          skill['description'] ?? "",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: 10),

                        Text(
                          reviewContent[skill['errorType']]['answer'] ?? "Không có nội dung ôn tập cho lỗi này.",
                          style: TextStyle(fontSize: 16),
                        ),

                        SizedBox(height: 10),

                        if ((reviewContent[skill['errorType']]['results'] as List<dynamic>).isNotEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Nguồn tham khảo',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ...(reviewContent[skill['errorType']]['results'] as List<dynamic>).map((result) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "- ${result['title']}",
                                        style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(left: 4),
                                        child: GestureDetector(
                                          onTap: () async {
                                            await launchUrl(
                                              Uri.parse(result['url'] as String),
                                              mode: LaunchMode.externalApplication,
                                            );
                                          },
                                          child: Text(
                                            result['url'] ?? "",
                                            style: TextStyle(
                                              color: Colors.blue,
                                              decoration: TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                              ],
                            ),
                          ),

                        SizedBox(height: 30),
                      ],
                    ))
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