import 'package:english_center_fe/widgets/layout/layout.dart';
import 'package:flutter/material.dart';

class TicketPage extends StatelessWidget {
  const TicketPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Title(
      color: Colors.black,
      title: "Ticket",
      child: SiteLayout(
        menuNo: 9,
        content: Container(
          color: Color(0xFFF1F3F4),
        ),
      ),
    );
  }
}