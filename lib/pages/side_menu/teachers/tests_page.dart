import 'package:flutter/material.dart';

import '../../teachers/ai_reading_assignments_page.dart';

class TestsPage extends StatelessWidget {
  const TestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AiReadingAssignmentsPage(kind: 'TEST', menuNo: 11);
  }
}
