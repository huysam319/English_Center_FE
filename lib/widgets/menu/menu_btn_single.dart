import 'package:flutter/material.dart';

class SingleMenuButton extends StatelessWidget {
  const SingleMenuButton({super.key, required this.icon, required this.label, required this.func, required this.isActive});
  final IconData icon;
  final String label;
  final VoidCallback func;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: func,
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color>(
          (states) {
            if (isActive) {
              if (states.contains(WidgetState.hovered)) return Color(0xDD1E40AF);
              return Color(0xFF1E40AF);
            }
            if (states.contains(WidgetState.hovered)) return Colors.grey.shade300;
            return Color(0xFFF1F4F5);
          }
        ),
        foregroundColor: isActive? WidgetStateProperty.all(Colors.white): WidgetStateProperty.all(Colors.black),
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
            Icon(icon, size: 24,),
            SizedBox(width: 8,),
            Flexible(
              child: Text(
                label, 
                style: TextStyle(
                  fontSize: 14, 
                  fontWeight: FontWeight.w600,
                ), 
                maxLines: 1, 
                overflow: TextOverflow.ellipsis, 
                softWrap: false,
              ),
            )
          ],
        ),
      ),
    );
  }
}