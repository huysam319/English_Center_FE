import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

import 'answer_box/labeling.dart';

class LabelingText extends StatelessWidget {
  final String text;

  const LabelingText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Html(
      data: text,
      extensions: [
        LabelingBlankTagExtension(),
      ],
      style: {
        "ul": Style(
          margin: Margins.zero,
          padding: HtmlPaddings.only(left: 10, right: 0, top: 0, bottom: 0,),
        ),
        "li": Style(
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
        ),
        "p": Style(
          margin: Margins.zero,
        ),
      },
    );
  }
}

class LabelingBlankTagExtension extends HtmlExtension {
  @override
  Set<String> get supportedTags => {"blank"};

  @override
  InlineSpan build(ExtensionContext context) {
    final idAttr = context.element?.attributes['id'];
    final questionNo = int.tryParse(idAttr ?? '') ?? 0;

    return TextSpan(
      children: [
        TextSpan(text: " "),
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: LabelingAnswerBox(
            questionNo: questionNo,
          ),
        ),
        TextSpan(text: " "),
      ],
    );
  }
}