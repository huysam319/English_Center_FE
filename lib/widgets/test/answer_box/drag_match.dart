import 'package:flutter/material.dart';

class DragMatch extends StatefulWidget {
  const DragMatch({super.key});

  @override
  State<DragMatch> createState() => _DragMatchState();
}

class _DragMatchState extends State<DragMatch> {
  final left = ['A', 'B', 'C'];
  final right = ['1', '2', '3'];

  Map<String, String> matched = {};

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          children: left.map((item) {
            return Draggable<String>(
              data: item,
              feedback: Material(
                child: Chip(label: Text(item)),
              ),
              childWhenDragging: Opacity(
                opacity: 0.3,
                child: Chip(label: Text(item)),
              ),
              child: Chip(label: Text(item)),
            );
          }).toList(),
        ),

        SizedBox(width: 40),

        Column(
          children: right.map((target) {
            return DragTarget<String>(
              builder: (context, candidateData, rejectedData) {
                return Container(
                  width: 80,
                  height: 40,
                  margin: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(),
                  ),
                  child: Center(
                    child: Text(matched[target] ?? target),
                  ),
                );
              },
              onAccept: (data) {
                setState(() {
                  matched[target] = data;
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}