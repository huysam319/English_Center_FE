import 'package:flutter/material.dart';

class CompletionAnswerBox extends StatefulWidget {
  final int questionNo;
  final TextEditingController answerController;

  const CompletionAnswerBox({super.key, required this.questionNo, required this.answerController});

  @override
  State<CompletionAnswerBox> createState() => _CompletionAnswerBoxState();
}

class _CompletionAnswerBoxState extends State<CompletionAnswerBox> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 130,
          height: 25,
          child: TextField(
            controller: widget.answerController,
            textAlign: TextAlign.left,
            style: TextStyle(fontSize: 14),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Color(0xFF1E40AF),
                  width: 2,
                ),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
        ),

        if (widget.answerController.text.isEmpty)
          IgnorePointer(
            child: Text(
              widget.questionNo.toString(),
              style: TextStyle(
                color: Color(0xFF1E40AF),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
      ],
    );
  }
}