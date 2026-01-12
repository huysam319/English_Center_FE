import 'package:english_center_fe/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:english_center_fe/helpers/responsiveness.dart';
import 'package:english_center_fe/services/api_service.dart';

AppBar topNavigationBar(BuildContext context, GlobalKey<ScaffoldState> key, String title) => 
    AppBar(
      leading: IconButton(
        icon: Icon(Icons.menu), 
        onPressed: (){
          if (ResponsiveWidget.isSmallScreen(context)) key.currentState?.openDrawer();
        },
      ),
      leadingWidth: 50,
      elevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: Colors.grey.shade300,
        ),
      ),
      title: Row(
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width/6-56 > 125 ? MediaQuery.of(context).size.width/6-56 : 125,
            child: Row(
              children: [
                IconButton(
                  icon: Image.asset("assets/icons/logo.png", height: 30, width: 100,),
                  onPressed: () { context.go("/"); },
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                ),
              ],
            ),
          ),
          Visibility(
            child: Text(
              title, 
              style: GoogleFonts.inter(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold,),
            ),
          ),

          Expanded(child: Container()),

          Stack(
            children: [
              IconButton(
                onPressed: (){}, 
                icon: Icon(Icons.notifications_outlined, color: Color(0xFF363740).withValues(alpha: 0.7)),
              ),
              Positioned(
                top: 7, 
                right: 7,
                child: Container(
                  width: 12,
                  height: 12,
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Color(0xFF3C19C0),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Color(0xFFF7F8FC), width: 2)
                  ),
                ),
              ),
            ],
          ),

          IconButton(onPressed: (){}, icon: Icon(Icons.light_mode_outlined, color: Color(0xFF363740).withValues(alpha: 0.7),),),

          SizedBox(
            width: 16,
          ),

          PopupMenuButton<String>(
            icon: Icon(Icons.person_outline, color: Color(0xFF363740)),
            color: Colors.white,
            position: PopupMenuPosition.under,
            offset: Offset(0, 8),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                child: Text('Thông tin'),
              ),
              PopupMenuItem(
                value: 'logout',
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                child: Text('Đăng xuất', style: TextStyle(color: Colors.red),),
              ),
            ],
            onSelected: (value) async {
              if (value == 'profile') {
                // TODO: điều hướng tới trang thông tin người dùng nếu cần
              } 
              else { // value == 'logout'
                await ApiService.post(
                  '/identity/auth/logout',
                  { 'token': authService.accessToken, },
                );
                authService.clearAuth();

                if (!context.mounted) return;
                context.go('/login');
              }
            },
          ),
        ],
      ),

      iconTheme: IconThemeData(color: Color(0xFF363740)),
      backgroundColor: Colors.white,
    );