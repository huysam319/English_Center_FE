import 'dart:html' as html;
import 'dart:ui_web' as ui;
import 'package:flutter/material.dart';

class PassageText extends StatefulWidget {
  final String text;
  final String? highlightStorageKey;

  const PassageText({
    super.key,
    required this.text,
    this.highlightStorageKey,
  });

  @override
  State<PassageText> createState() => _PassageTextState();
}

class _PassageTextState extends State<PassageText> {
  late html.DivElement _div;
  late String _viewType;
  html.Range? _savedRange;

  @override
  void initState() {
    super.initState();
    _createView();
  }

  @override
  void didUpdateWidget(covariant PassageText oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.text != widget.text ||
        oldWidget.highlightStorageKey != widget.highlightStorageKey) {
      _createView();
      setState(() {});
    }
  }

  String _getInitialHtml() {
    final storageKey = widget.highlightStorageKey;
    if (storageKey == null || storageKey.isEmpty) {
      return widget.text;
    }

    return html.window.localStorage[storageKey] ?? widget.text;
  }

  void _persistHighlightHtml() {
    final storageKey = widget.highlightStorageKey;
    if (storageKey == null || storageKey.isEmpty) {
      return;
    }

    html.window.localStorage[storageKey] = _div.innerHtml ?? widget.text;
  }

  void _createView() {
    _viewType = 'html-text-view-${DateTime.now().microsecondsSinceEpoch}';

    _div = html.DivElement()
      ..style.padding = '5px'
      ..style.fontSize = '16px'
      ..style.cursor = 'text'
      ..style.userSelect = 'text'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.overflowY = 'auto'
      ..style.textAlign = 'justify'
      ..innerHtml = _getInitialHtml();

    _applyHighlightStyles();

    ui.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) => _div,
    );

    _div.onContextMenu.listen(_handleRightClick);
  }

  void _applyHighlightStyles() {
    final highlightedElements = _div.querySelectorAll('.custom-highlight');

    for (final element in highlightedElements) {
      element.style.backgroundColor = 'yellow';
    }
  }

  void _handleRightClick(html.MouseEvent event) async {
    event.preventDefault();

    final target = event.target as html.Node?;

    // CASE 1: Right click vào highlight -> Remove
    if (target is html.Element &&
        target.classes.contains('custom-highlight')) {

      final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

      final menu = await showMenu<int>(
        context: context,
        position: RelativeRect.fromLTRB(
          event.client.x.toDouble(),
          event.client.y.toDouble(),
          overlay.size.width - event.client.x.toDouble(),
          overlay.size.height - event.client.y.toDouble(),
        ),
        items: const [
          PopupMenuItem(height: 30, value: 2, child: Text("Remove")),
        ],
      );

      if (menu == 2) {
        _removeHighlight(target);
      }
    }
    else {
      // CASE 2: Right click khi có selection -> Highlight
      final selection = html.window.getSelection();
      if (selection == null || selection.toString().trim().isEmpty) return;

      _savedRange = selection.getRangeAt(0).cloneRange();

      final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

      final menu = await showMenu<int>(
        context: context,
        position: RelativeRect.fromLTRB(
          event.client.x.toDouble(),
          event.client.y.toDouble(),
          overlay.size.width - event.client.x.toDouble(),
          overlay.size.height - event.client.y.toDouble(),
        ),
        items: const [
          PopupMenuItem(height: 30, value: 1, child: Text("Highlight")),
        ],
      );

      if (menu == 1) {
        _highlightSelection();
      }
    }
  }

  void _highlightSelection() {
    if (_savedRange == null) return;

    final span = html.SpanElement()
      ..style.backgroundColor = 'yellow'
      ..classes.add('custom-highlight');

    try {
      _savedRange!.surroundContents(span);
    } catch (_) {
      final fragment = _savedRange!.extractContents();
      span.append(fragment);
      _savedRange!.insertNode(span);
    }

    _savedRange = null;
    _persistHighlightHtml();
  }

  void _removeHighlight(html.Element span) {
    final parent = span.parent;
    if (parent == null) return;

    // unwrap span
    while (span.firstChild != null) {
      parent.insertBefore(span.firstChild!, span);
    }

    span.remove();
    _persistHighlightHtml();
  }

  @override
  Widget build(BuildContext context) {
    // return SizedBox.expand(
    //   child: HtmlElementView(
    //     viewType: 'html-text-view',
    //   ),
    // );
    return SizedBox(
      height: double.infinity,
      width: double.infinity,
      child: HtmlElementView(
        key: ValueKey(_viewType),
        viewType: _viewType,
      ),
    );
  }
}