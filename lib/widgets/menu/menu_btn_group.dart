import 'package:flutter/material.dart';

class SideMenuGroup extends StatefulWidget {
  final IconData icon;
  final String title;
  final bool isActive;
  final List<Widget> children;

  const SideMenuGroup({
    super.key,
    required this.icon,
    required this.title,
    required this.isActive,
    required this.children,
  });

  @override
  State<SideMenuGroup> createState() => _SideMenuGroupState();
}

class _SideMenuGroupState extends State<SideMenuGroup> {
  bool expanded = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFF1F4F5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              setState(() {
                expanded = !expanded;
              });
            },
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith<Color>(
                (states) {
                  if (widget.isActive) {
                    if (states.contains(WidgetState.hovered)) return Color(0xDD1E40AF);
                    return Color(0xFF1E40AF);
                  }
                  if (states.contains(WidgetState.hovered)) return Colors.grey.shade300;
                  return Color(0xFFF1F4F5);
                }
              ),
              foregroundColor: widget.isActive? WidgetStateProperty.all(Colors.white): WidgetStateProperty.all(Colors.black),
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              elevation: WidgetStateProperty.all(0),
              minimumSize: WidgetStateProperty.all(Size(double.infinity, 48),),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(widget.icon, size: 24,),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,), 
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis, 
                    softWrap: false,
                  ),
                ),
                Icon(
                  expanded? Icons.keyboard_arrow_up: Icons.keyboard_arrow_down,
                  color: widget.isActive ? Colors.white : Colors.black,
                ),
              ],
            ),
          ),

          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: expanded? Column(children: widget.children,): const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}