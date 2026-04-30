import 'package:flutter/material.dart';

class MatchingOption extends StatefulWidget {
  final String content;

  const MatchingOption({super.key, required this.content});

  @override
  State<MatchingOption> createState() => _MatchingOptionState();
}

class _MatchingOptionState extends State<MatchingOption> {
  Widget optionBox(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey),
      ),
      child: Text(text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Draggable<String>(
        data: widget.content,
        feedback: Material(
          child: optionBox(widget.content),
        ),
        childWhenDragging: Opacity(
          opacity: 0.3,
          child: optionBox(widget.content),
        ),
        child: optionBox(widget.content),
    );
  }
}