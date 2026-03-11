import 'package:english_center_fe/widgets/layout/layout.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TestsPage extends StatefulWidget {
  const TestsPage({super.key});

  @override
  State<TestsPage> createState() => _TestsPageState();
}

class _TestsPageState extends State<TestsPage> {
  @override
  Widget build(BuildContext context) {
    return Title(
      color: Colors.black,
      title: "Đề thi",
      child: SiteLayout(
        menuNo: 11,
        content: Container(
          color: Colors.white,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: Container()),
                    ElevatedButton(
                      onPressed: () {
                        context.go('/tests/create');
                      },
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all(
                          Color(0xFF1E40AF),
                        ),
                        foregroundColor: WidgetStateProperty.all(Colors.white),
                        overlayColor: WidgetStateProperty.all(
                          Colors.transparent,
                        ),
                        minimumSize: WidgetStateProperty.all(Size(150, 50)),
                        elevation: WidgetStateProperty.all(0),
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.add_outlined, size: 20),
                          SizedBox(width: 4),
                          Text('Thêm đề thi'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}