import 'package:flutter/material.dart';

class SideMenuGroupItem extends StatelessWidget {
  final String title;
  final VoidCallback func;
  final bool isActive;

  const SideMenuGroupItem({
    super.key,
    required this.title,
    required this.func,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: func,
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color>(
          (states) {
            if (states.contains(WidgetState.hovered)) return Colors.grey.shade300;
            return Color(0xFFF1F4F5);
          }
        ),
        foregroundColor: isActive? WidgetStateProperty.all(Color(0xFF1E40AF)): WidgetStateProperty.all(Colors.black),
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        minimumSize: WidgetStateProperty.all(Size(double.infinity, 48),),
        elevation: WidgetStateProperty.all(0),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            SizedBox(width: 15,),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1, 
                overflow: TextOverflow.ellipsis, 
                softWrap: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}