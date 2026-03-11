import 'package:flutter/material.dart';

class SectionNavbar extends StatefulWidget {
  final bool isActive;
  final String label;
  final int number;
  final VoidCallback onChanged;
  
  const SectionNavbar({super.key, required this.isActive, required this.label, required this.number, required this.onChanged});

  @override
  State<SectionNavbar> createState() => _SectionNavbarState();
}

class _SectionNavbarState extends State<SectionNavbar> {
  @override
  Widget build(BuildContext context) {
    if (widget.isActive) {
      return Container(
        height: 40,
        color: Colors.blue,
        child: Center(
          child: Text("${widget.label} ${widget.number}"),
        ),
      );
    } else {
      return Container(
        height: 40,
        color: Colors.grey,
        child: Center(
          child: Expanded(
            child: TextButton(
              onPressed: widget.onChanged, 
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Colors.grey),
                foregroundColor: WidgetStateProperty.all(Colors.black),
                overlayColor: WidgetStateProperty.all(
                  Colors.transparent,
                ),
                minimumSize: WidgetStateProperty.all(Size(double.infinity, 40)),
                elevation: WidgetStateProperty.all(0),
              ),
              child: Text("${widget.label} ${widget.number}"),
            ),
          ),
        ),
      );
    }
  }
}