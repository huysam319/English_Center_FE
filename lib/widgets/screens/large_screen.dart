import 'package:english_center_fe/widgets/menu/side_menu.dart';
import 'package:flutter/material.dart';

// import 'top_nav.dart';

class LargeScreen extends StatelessWidget {
  const LargeScreen({super.key, required this.order});
  final int order;
  
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            color: Colors.white,
            child: SideMenu(order: order,),
          ),
        ),
        Expanded(
          flex: 5,
          child: Container(
            color: Color(0xFFF1F3F4),
          ),
        )
      ],
    );
  }
}