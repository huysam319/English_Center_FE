import 'package:english_center_fe/widgets/menu/side_menu.dart';
import 'package:flutter/material.dart';

// import 'top_nav.dart';

class LargeScreen extends StatelessWidget {
  const LargeScreen({super.key, required this.order, required this.content});
  final int order;
  final Widget content;
  
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
          child: content,
        )
      ],
    );
  }
}