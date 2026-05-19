import 'package:english_center_fe/widgets/layout/layout.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LearningSupportPage extends StatefulWidget {
  const LearningSupportPage({super.key});

  @override
  State<LearningSupportPage> createState() => _LearningSupportPageState();
}

class _LearningSupportPageState extends State<LearningSupportPage> {
  @override
  Widget build(BuildContext context) {
    return Title(
      color: Colors.black,
      title: "Hỗ trợ học tập",
      child: SiteLayout(
        menuNo: 9,
        content: Container(
          color: Colors.white,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Bạn đang cần hỗ trợ gì?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'Nếu bạn gặp khó khăn trong việc khắc phục các lỗi sai trong quá trình học tập, chúng tôi sẵn sàng hỗ trợ bạn.',
                style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
              ),

              SizedBox(height: 20),

              ElevatedButton(
                onPressed: () {
                  showDialog<bool>(
                    context: context,
                    barrierDismissible: true,
                    builder: (context) {
                      return AlertDialog(
                        title: Text("Xác nhận ôn tập"),
                        content: Text("Bạn đã sẵn sàng ôn tập lỗi sai chưa?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.all(
                                Color(0xFFF1F3F4),
                              ),
                              foregroundColor: WidgetStateProperty.all(
                                Colors.black,
                              ),
                              overlayColor: WidgetStateProperty.all(
                                Colors.transparent,
                              ),
                              minimumSize: WidgetStateProperty.all(
                                Size(75, 35),
                              ),
                              elevation: WidgetStateProperty.all(0),
                              shape: WidgetStateProperty.all(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            child: Text("Hủy"),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(context, true);

                              final router = GoRouter.of(context);
                              router.go('/learning-support/quiz');
                            },
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.all(
                                Color(0xFF1E40AF),
                              ),
                              foregroundColor: WidgetStateProperty.all(
                                Colors.white,
                              ),
                              overlayColor: WidgetStateProperty.all(
                                Colors.transparent,
                              ),
                              minimumSize: WidgetStateProperty.all(
                                Size(75, 35),
                              ),
                              elevation: WidgetStateProperty.all(0),
                              shape: WidgetStateProperty.all(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            child: Text("Bắt đầu"),
                          ),
                        ],
                      );
                    },
                  );
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(Color(0xFF1E40AF)),
                  foregroundColor: WidgetStateProperty.all(Colors.white),
                  overlayColor: WidgetStateProperty.all(Colors.transparent),
                  minimumSize: WidgetStateProperty.all(Size(150, 50)),
                  elevation: WidgetStateProperty.all(0),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                child: Text('Tạo quiz ôn tập'),
              ),

              SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: () {
                  context.go('/notification');
                },
                icon: Icon(Icons.support_agent_outlined),
                label: Text('Gửi ticket cho admin'),
                style: ButtonStyle(
                  foregroundColor: WidgetStateProperty.all(Color(0xFF1E40AF)),
                  minimumSize: WidgetStateProperty.all(Size(150, 50)),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
