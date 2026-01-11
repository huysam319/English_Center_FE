import 'package:english_center_fe/widgets/menu/side_menu.dart';
import 'package:flutter/material.dart';

import '../../constants/menu_list.dart';
import '../../helpers/responsiveness.dart';
import '../screens/large_screen.dart';
import '../screens/small_screen.dart';
import 'top_nav.dart';

class SiteLayout extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey();
  final int menuNo;
  SiteLayout({super.key, required this.menuNo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: topNavigationBar(context, scaffoldKey, studentMenuList[menuNo-1]),
      drawer: Drawer(
        child: SideMenu(order: menuNo),
      ),
      body: ResponsiveWidget(largeScreen: LargeScreen(order: menuNo), smallScreen: SmallScreen(),),
    );
  }
}