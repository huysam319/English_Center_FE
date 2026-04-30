import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../models/dropped_file.dart';
import '../../models/part_model.dart';
import 'dropzone.dart';

class WritingPartCreation extends StatefulWidget {
  final PartModel part;
  final List<PartModel> parts;
  final VoidCallback clearPart;

  const WritingPartCreation({super.key, required this.part, required this.parts, required this.clearPart});

  @override
  State<WritingPartCreation> createState() => _WritingPartCreationState();
}

class _WritingPartCreationState extends State<WritingPartCreation> {
  DroppedFile? file;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        color: Colors.grey.shade300,
        alignment: Alignment.center,
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      "Task ${widget.parts.indexOf(widget.part) + 1}",
                      style: TextStyle(
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 16),
                  onPressed: widget.clearPart,
                  style: ButtonStyle(
                    padding: WidgetStateProperty.all(EdgeInsets.zero),
                    minimumSize: WidgetStateProperty.all(Size(16, 16)),
                    maximumSize: WidgetStateProperty.all(Size(16, 16)),
                  ),
                ),
              ],
            ),

            Padding(
              padding: EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: Colors.black,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    QuillSimpleToolbar(
                      controller: widget.part.textController,
                    ),
                    Divider(
                      color: Colors.grey,
                      thickness: 1,
                      height: 20,
                    ),
                    QuillEditor(
                      controller: widget.part.textController,
                      scrollController:
                          ScrollController(),
                      focusNode: FocusNode(),
                      config: QuillEditorConfig(
                        padding: EdgeInsets.all(10),
                        autoFocus: false,
                        expands: false,
                        placeholder: 'Add your question prompt here...',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 600,
                maxHeight: 400,
              ),
              child: Dropzone(
                onDroppedFile: (file) => setState(() => widget.part.file = file),
                file: widget.part.file,
              ),
            ),
          ],
        )
      ),
    );
  }
}