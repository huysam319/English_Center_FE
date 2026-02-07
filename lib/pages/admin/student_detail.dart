import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/layout/layout.dart';

class StudentDetailPage extends StatefulWidget {
  final String id;

  const StudentDetailPage({super.key, required this.id});

  @override
  State<StudentDetailPage> createState() => _StudentDetailPageState();
}

class _StudentDetailPageState extends State<StudentDetailPage> {
  @override
  Widget build(BuildContext context) {
    return Title(
      color: Colors.black,
      title: "Thông tin học viên",
      child: SiteLayout(
        menuNo: 16,
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
                          context.go('/student-management');
                        },
                      ),
                      Text(
                        "Thông tin học viên",
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