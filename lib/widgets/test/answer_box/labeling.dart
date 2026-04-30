import 'package:flutter/material.dart';

class LabelingAnswerBox extends StatefulWidget {
  final int questionNo;
  final String? initialAnswer;
  final ValueChanged<String>? onAnswerChanged;

  const LabelingAnswerBox({
    super.key,
    required this.questionNo,
    this.initialAnswer,
    this.onAnswerChanged,
  });

  @override
  State<LabelingAnswerBox> createState() => _LabelingAnswerBoxState();
}

class _LabelingAnswerBoxState extends State<LabelingAnswerBox> {
  late String? _answer;

  @override
  void initState() {
    super.initState();
    _answer = widget.initialAnswer;
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      builder: (context, candidateData, rejectedData) {
        final isFocused = candidateData.isNotEmpty;
        final answer = _answer;

        return Container(
          width: 130,
          height: 25,
          child: InputDecorator(
            isFocused: isFocused,
            isEmpty: (_answer ?? '').isEmpty,
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
            child: Align(
              alignment: Alignment.center,
              child: answer != null
                  ? Text(answer)
                  : Text(
                      widget.questionNo.toString(),
                      style: TextStyle(
                        color: Color(0xFF1E40AF),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
        );
      },
      onAccept: (data) {
        setState(() {
          _answer = data;
        });
        widget.onAnswerChanged?.call(data);
      },
    );
  }
}