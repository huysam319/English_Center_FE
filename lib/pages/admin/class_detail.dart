import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/layout/layout.dart';

class ClassDetailPage extends StatefulWidget {
  final String id;

  const ClassDetailPage({super.key, required this.id});

  @override
  State<ClassDetailPage> createState() => _ClassDetailPageState();
}

class _ClassDetailPageState extends State<ClassDetailPage> {
  @override
  Widget build(BuildContext context) {
    return Title(
      color: Colors.black,
      title: "Thông tin lớp học",
      child: SiteLayout(
        menuNo: 14,
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
                          context.go('/class-management');
                        },
                      ),
                      Text(
                        "Thông tin lớp học",
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