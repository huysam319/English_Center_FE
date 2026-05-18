import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';

import '../../models/dropped_file.dart';

class Dropzone extends StatefulWidget {
  final ValueChanged<DroppedFile> onDroppedFile;
  final DroppedFile? file;

  const Dropzone({super.key, required this.onDroppedFile, this.file});

  @override
  State<Dropzone> createState() => _DropzoneState();
}

class _DropzoneState extends State<Dropzone> {
  late DropzoneViewController controller;
  bool isHighlighted = false;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        color: isHighlighted ? Colors.white : Color(0xFF1E40AF),
        height: 260,
        padding: EdgeInsets.all(10),
        child: DottedBorder( 
          options: RoundedRectDottedBorderOptions(
            color: isHighlighted ? Color(0xFF1E40AF) : Colors.white,
            padding: EdgeInsets.all(0),
            strokeWidth: 3,
            dashPattern: [8, 4],
            radius: Radius.circular(12),
          ),
          child: Stack(
            children: [
              DropzoneView(
                onCreated: (controller) => this.controller = controller,
                onHover: () => setState(() => isHighlighted = true),
                onLeave: () => setState(() => isHighlighted = false),
                onDrop: (_) => setState(() => isHighlighted = false),
                onDropFile: acceptFile,
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.upload_file_outlined, 
                      size: 80, 
                      color: isHighlighted ? Colors.black : Colors.white,
                    ),
                    Text(
                      'Kéo thả file vào đây',
                      style: TextStyle(
                        fontSize: 18, 
                        color: isHighlighted ? Colors.black : Colors.white,
                      ),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        backgroundColor: isHighlighted ? Colors.blue.shade300 : Colors.blue.shade300,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: Icon(Icons.search_outlined, size: 32),
                      label: Text(
                        'Chọn file',
                        style: TextStyle(fontSize: 18, color: Colors.white,),
                      ),
                      onPressed: () async {
                        final events = await controller.pickFiles();
                        if (events.isEmpty) return;

                        acceptFile(events.first);
                      }, 
                    ),
                    SizedBox(height: 16),

                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8,),
                      child: Text(
                        widget.file != null
                          ? 'File được chọn: ${widget.file!.name}, size: ${widget.file!.size}, type: ${widget.file!.mime}'
                          : 'Chưa có file nào được chọn',
                        style: TextStyle(
                          fontSize: 16, 
                          color: isHighlighted ? Colors.black : Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future acceptFile(dynamic event) async {
    final name = event.name;
    final mime = await controller.getFileMIME(event);
    final bytes = await controller.getFileSize(event);
    final url = await controller.createFileUrl(event);
    final content = controller.getFileStream(event);

    final droppedFile = DroppedFile(
      name: name,
      mime: mime,
      bytes: bytes,
      url: url,
      content: content,
    );

    widget.onDroppedFile(droppedFile);
  }
}