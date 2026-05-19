import 'package:flutter/material.dart';

class MultipleChoiceQuizWidget extends StatefulWidget {
  final dynamic question;
  final Map<int, int> selectedAnswers;
  final bool submitted;

  const MultipleChoiceQuizWidget({
    super.key,
    required this.question,
    required this.selectedAnswers,
    required this.submitted
  });

  @override
  State<MultipleChoiceQuizWidget> createState() => _MultipleChoiceQuizWidgetState();
}

class _MultipleChoiceQuizWidgetState extends State<MultipleChoiceQuizWidget> {
  Color _getChoiceColor(
    Map<String, dynamic> choice,
    int questionOrder,
  ) {
    if (!widget.submitted) {
      return Colors.white;
    }

    final selectedChoice =
        widget.selectedAnswers[questionOrder];

    final bool isSelected =
        selectedChoice == choice['order'];

    final bool isCorrect = choice['isCorrect'];

    if (isCorrect) {
      return Colors.green.shade100;
    }

    if (isSelected && !isCorrect) {
      return Colors.red.shade100;
    }

    return Colors.white;
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int questionOrder = widget.question['order'];

    final List choices = widget.question['choices'];

    return Container(
      margin:
          EdgeInsets.only(bottom: 24),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            'Question ${widget.question['order']}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),

          SizedBox(height: 10),

          Text(
            widget.question['content'],
            style: TextStyle(
              fontSize: 16,
            ),
          ),

          SizedBox(height: 16),

          ...choices.map((choice) {
            return Container(
              margin:
                  EdgeInsets.only(
                      bottom: 10),
              decoration: BoxDecoration(
                color: _getChoiceColor(
                  choice,
                  questionOrder,
                ),
                borderRadius:
                    BorderRadius
                        .circular(10),
                border: Border.all(
                  color: Colors
                      .grey.shade300,
                ),
              ),
              child: RadioListTile<int>(
                value: choice['order'],
                groupValue: widget.selectedAnswers[questionOrder],
                onChanged: widget.submitted
                    ? null
                    : (value) {
                        setState(() {
                          widget.selectedAnswers[questionOrder] = value!;
                        });
                      },
                title: Text(choice['content']),
              ),
            );
          }).toList(),

          if (widget.submitted)
            Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                SizedBox(height: 10),

                Text(
                  'Correct answer:',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    color:
                        Colors.green,
                  ),
                ),

                SizedBox(height: 5),

                Text(
                  widget.question['answer'],
                ),
              ],
            ),
        ],
      ),
    );
  }
}