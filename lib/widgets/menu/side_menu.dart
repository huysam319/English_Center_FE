import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'menu_btn_group.dart';
import 'menu_btn_group_item.dart';
import 'menu_btn_single.dart';

class SideMenu extends StatelessWidget {
  const SideMenu({super.key, required this.order});
  final int order;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          SizedBox(height: 45,),

          SingleMenuButton(
            icon: Icons.home_outlined,
            label: "Trang chủ",
            func: () {
              context.go("/");
            },
            isActive: order == 1? true: false,
          ),

          SizedBox(height: 5,),

          SingleMenuButton(
            icon: Icons.notifications_outlined,
            label: "Thông báo",
            func: () {
              context.go("/notification");
            },
            isActive: order == 2? true: false,
          ),

          SizedBox(height: 5,),

          SingleMenuButton(
            icon: Icons.class_outlined,
            label: "Lớp của tôi",
            func: () {
              context.go("/class");
            },
            isActive: order == 3? true: false,
          ),

          SizedBox(height: 5,),

          SideMenuGroup(
            icon: Icons.assignment_outlined,
            title: "Bài tập",
            isActive: (order == 4 || order == 5)? true: false,
            children: [
              SideMenuGroupItem(
                title: "Bài tập tự chọn",
                isActive: order == 4? true: false,
                func: () {
                  context.go("/exercise");
                },
              ),
              SideMenuGroupItem(
                title: "Bài tập của bạn",
                isActive: order == 5? true: false,
                func: () {
                  context.go("/class/exercise");
                },
              ),
            ],
          ),

          SizedBox(height: 5,),

          SideMenuGroup(
            icon: Icons.fact_check_outlined,
            title: "Đề thi",
            isActive: (order == 6 || order == 7)? true: false,
            children: [
              SideMenuGroupItem(
                title: "Danh sách đề thi",
                isActive: order == 6? true: false,
                func: () {
                  context.go("/test");
                },
              ),
              SideMenuGroupItem(
                title: "Lịch sử làm bài",
                isActive: order == 7? true: false,
                func: () {
                  context.go("/test/history");
                },
              ),
            ],
          ),

          SizedBox(height: 5,),

          SingleMenuButton(
            icon: Icons.style_outlined,
            label: "Flashcards",
            func: () {
              context.go("/flashcard");
            },
            isActive: order == 8? true: false,
          ),

          SizedBox(height: 5,),

          SingleMenuButton(
            icon: Icons.mail_outlined,
            label: "Ticket",
            func: () {
              context.go("/ticket");
            },
            isActive: order == 9? true: false,
          ),
        ],
      ),
    );
  }
}