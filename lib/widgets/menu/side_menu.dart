import 'package:english_center_fe/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import 'menu_btn_group.dart';
import 'menu_btn_group_item.dart';
import 'menu_btn_single.dart';

class SideMenu extends StatelessWidget {
  const SideMenu({super.key, required this.order});
  final int order;

  @override
  Widget build(BuildContext context) {
    final decoded = JwtDecoder.decode(authService.accessToken ?? "");
    const sideBorder = BorderSide(color: Color(0xFFE0E0E0), width: 1);
    if (decoded['scope'].contains('ROLE_STUDENT')) {
      return Container(
        decoration: const BoxDecoration(border: Border(right: sideBorder)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            children: [
              SizedBox(height: 45),

              SingleMenuButton(
                icon: Icons.home_outlined,
                label: "Trang chủ",
                func: () {
                  context.go("/");
                },
                isActive: (order == 1) ? true : false,
              ),

              SizedBox(height: 5),

              SingleMenuButton(
                icon: Icons.notifications_outlined,
                label: "Thông báo",
                func: () {
                  context.go("/notification");
                },
                isActive: (order == 2) ? true : false,
              ),

              SizedBox(height: 5),

              SingleMenuButton(
                icon: Icons.class_outlined,
                label: "Lớp của tôi",
                func: () {
                  context.go("/class");
                },
                isActive: (order == 3) ? true : false,
              ),

              SizedBox(height: 5),

              SideMenuGroup(
                icon: Icons.assignment_outlined,
                title: "Bài tập",
                isActive: (order == 4 || order == 5) ? true : false,
                children: [
                  SideMenuGroupItem(
                    title: "Bài tập tự chọn",
                    isActive: (order == 4) ? true : false,
                    func: () {
                      context.go("/exercise");
                    },
                  ),
                  SideMenuGroupItem(
                    title: "Bài tập của bạn",
                    isActive: (order == 5) ? true : false,
                    func: () {
                      context.go("/class/exercise");
                    },
                  ),
                ],
              ),

              SizedBox(height: 5),

              SideMenuGroup(
                icon: Icons.fact_check_outlined,
                title: "Đề thi",
                isActive: (order == 6 || order == 7) ? true : false,
                children: [
                  SideMenuGroupItem(
                    title: "Danh sách đề thi",
                    isActive: (order == 6) ? true : false,
                    func: () {
                      context.go("/test");
                    },
                  ),
                  SideMenuGroupItem(
                    title: "Lịch sử làm bài",
                    isActive: (order == 7) ? true : false,
                    func: () {
                      context.go("/test/history");
                    },
                  ),
                ],
              ),

              SizedBox(height: 5),

              SingleMenuButton(
                icon: Icons.style_outlined,
                label: "Flashcards",
                func: () {
                  context.go("/flashcard");
                },
                isActive: (order == 8) ? true : false,
              ),

              SizedBox(height: 5),

              SingleMenuButton(
                icon: Icons.mail_outlined,
                label: "Ticket",
                func: () {
                  context.go("/ticket");
                },
                isActive: (order == 9) ? true : false,
              ),
            ],
          ),
        ),
      );
    } else if (decoded['scope'].contains('ROLE_TEACHER')) {
      return Container(
        decoration: const BoxDecoration(border: Border(right: sideBorder)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            children: [
              SizedBox(height: 45),

              SingleMenuButton(
                icon: Icons.home_outlined,
                label: "Trang chủ",
                func: () {
                  context.go("/");
                },
                isActive: (order == 1) ? true : false,
              ),

              SizedBox(height: 5),

              SingleMenuButton(
                icon: Icons.assignment_outlined,
                label: "Bài tập",
                func: () {
                  context.go("/exercises");
                },
                isActive: (order == 10) ? true : false,
              ),

              SizedBox(height: 5),

              SingleMenuButton(
                icon: Icons.folder_outlined,
                label: "Đề thi",
                func: () {
                  context.go("/tests");
                },
                isActive: (order == 11) ? true : false,
              ),

              SizedBox(height: 5),

              SingleMenuButton(
                icon: Icons.account_balance_outlined,
                label: "Ngân hàng câu hỏi",
                func: () {
                  context.go("/questions");
                },
                isActive: (order == 12) ? true : false,
              ),

              SizedBox(height: 5),

              SingleMenuButton(
                icon: Icons.library_books_outlined,
                label: "Quản lý lớp",
                func: () {
                  context.go("/classes");
                },
                isActive: (order == 13) ? true : false,
              ),
            ],
          ),
        ),
      );
    } else if (decoded['scope'].contains('ROLE_ADMIN')) {
      return Container(
        decoration: const BoxDecoration(border: Border(right: sideBorder)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            children: [
              SizedBox(height: 45),

              SingleMenuButton(
                icon: Icons.home_outlined,
                label: "Trang chủ",
                func: () {
                  context.go("/");
                },
                isActive: (order == 1) ? true : false,
              ),

              SizedBox(height: 5),

              SingleMenuButton(
                icon: Icons.class_outlined,
                label: "Quản lý lớp học",
                func: () {
                  context.go("/class-management");
                },
                isActive: (order == 14) ? true : false,
              ),

              SizedBox(height: 5),

              SingleMenuButton(
                icon: Icons.school_outlined,
                label: "Quản lý giáo viên",
                func: () {
                  context.go("/teacher-management");
                },
                isActive: (order == 15) ? true : false,
              ),

              SizedBox(height: 5),

              SingleMenuButton(
                icon: Icons.person_outlined,
                label: "Quản lý học viên",
                func: () {
                  context.go("/student-management");
                },
                isActive: (order == 16) ? true : false,
              ),
            ],
          ),
        ),
      );
    } else {
      return Container();
    }
  }
}
