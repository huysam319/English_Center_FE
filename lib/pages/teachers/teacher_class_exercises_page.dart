import 'package:flutter/material.dart';

import 'ai_reading_assignments_page.dart';

class TeacherClassExercisesPage extends StatelessWidget {
  const TeacherClassExercisesPage({super.key, required this.classId});

  final String classId;

  @override
  Widget build(BuildContext context) {
    return AiReadingAssignmentsPage(classId: classId);
  }
}
