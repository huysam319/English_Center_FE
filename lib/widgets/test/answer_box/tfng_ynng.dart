import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';

class TFNGYNNGAnswerBox extends StatefulWidget {
  final int questionNo;
  final bool isTFNG;
  final TextEditingController answerController;

  const TFNGYNNGAnswerBox({super.key, required this.questionNo, required this.isTFNG, required this.answerController});

  @override
  State<TFNGYNNGAnswerBox> createState() => _TFNGYNNGAnswerBoxState();
}

class _TFNGYNNGAnswerBoxState extends State<TFNGYNNGAnswerBox> {
  final List<String> tfngOptions = ['TRUE', 'FALSE', 'NOT GIVEN'];
  final List<String> ynngOptions = ['YES', 'NO', 'NOT GIVEN'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 130,
      height: 25,
      child: DropdownButtonFormField2<String>(
        value: widget.answerController.text.isEmpty ? null : widget.answerController.text,
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
          contentPadding: EdgeInsets.all(0),
        ),
        alignment: Alignment.center,
        hint: Text(
          widget.questionNo.toString(),
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF1E40AF),
            fontWeight: FontWeight.bold,
          ),
        ),
        iconStyleData: IconStyleData(
          icon: SizedBox.shrink(),
        ),
        menuItemStyleData: MenuItemStyleData(
          height: 30,
          padding: EdgeInsets.zero,
        ),
        isExpanded: true,
        items: (widget.isTFNG ? tfngOptions : ynngOptions).map<DropdownMenuItem<String>>((option) {
          return DropdownMenuItem<String>(
            value: option,
            child: Center(
              child: Text(option, style: TextStyle(fontSize: 12)),
            ),
          );
        }).toList(),
        onChanged: (value) {
          widget.answerController.text = value ?? '';
        },
      ),
    );
  }
}