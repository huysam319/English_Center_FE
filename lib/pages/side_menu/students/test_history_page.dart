import 'package:flutter/material.dart';

import '../../../widgets/layout/layout.dart';

class TestHistoryPage extends StatelessWidget {
  const TestHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Title(
      color: Colors.black,
      title: 'Lịch sử làm bài',
      child: SiteLayout(
        menuNo: 7,
        content: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(32),
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.history_outlined,
                  size: 48,
                  color: Color(0xFF6B7280),
                ),
                SizedBox(height: 12),
                Text(
                  'Chưa có lịch sử làm bài',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Khi học viên nộp bài hoặc làm đề, kết quả sẽ hiển thị tại đây.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
