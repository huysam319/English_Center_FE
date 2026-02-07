import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/layout/layout.dart';

class TeacherDetailPage extends StatefulWidget {
  final String id;

  const TeacherDetailPage({super.key, required this.id});

  @override
  State<TeacherDetailPage> createState() => _TeacherDetailPageState();
}

class _TeacherDetailPageState extends State<TeacherDetailPage> {
  @override
  Widget build(BuildContext context) {
    return Title(
      color: Colors.black,
      title: "Thông tin giáo viên",
      child: SiteLayout(
        menuNo: 15,
        content: widget.id.isEmpty? 
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
                          context.go('/teacher-management');
                        },
                      ),
                      Text(
                        "Thông tin giáo viên",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
      ),
    );
  }
}