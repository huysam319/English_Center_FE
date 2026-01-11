import 'package:english_center_fe/constants/menu_list.dart';
import 'package:english_center_fe/widgets/layout/layout.dart';
import 'package:flutter/material.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key, required this.order,});
  final int order;

  @override
  Widget build(BuildContext context) {
    return Title(
      color: Colors.black,
      title: studentMenuList[order-1],
      child: SiteLayout(menuNo: order,),
    );
  }
}