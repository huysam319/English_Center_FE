import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../models/dropped_file.dart';
import '../../../widgets/layout/layout.dart';
// import '../../../widgets/test/audio_player_widget.dart';
// import '../../../widgets/test/dropzone.dart';

class TestHistoryPage extends StatefulWidget {
  const TestHistoryPage({super.key});

  @override
  State<TestHistoryPage> createState() => _TestHistoryPageState();
}

class _TestHistoryPageState extends State<TestHistoryPage> {
  final QuillController controller = QuillController.basic();

  DroppedFile? file;

  // Future<void> _loadAudio(Uint8List bytes, String name) async {
  //   setState(() {
  //     _audioBytes = bytes;
  //     _audioName = name;
  //   });

  //   await _player.setAudioSource(
  //     AudioSource.uri(
  //       Uri.dataFromBytes(bytes, mimeType: 'audio/mpeg'),
  //     ),
  //   );

  //   // _player.play();
  // }

  // Future<void> _pickAudio() async {
  //   FilePickerResult? result = await FilePicker.platform.pickFiles(
  //     type: FileType.audio,
  //     withData: true,
  //   );

  //   if (result != null) {
  //     final file = result.files.first;
  //     if (file.bytes != null) {
  //       _loadAudio(file.bytes!, file.name);
  //     }
  //   }
  // }
  
  @override
  Widget build(BuildContext context) {
    return Title(
      color: Colors.black,
      title: "Lịch sử làm bài",
      child: SiteLayout(
        menuNo: 7,
        content: Container(
          color: Colors.white,
          child: Column(
            children: [
              // AudioPlayerWidget(url: 'assets/audios/music1.mp3'),

              // SizedBox(height: 20),

              // Padding(
              //   padding: EdgeInsets.all(16),
              //   child: Container(
              //     decoration: BoxDecoration(
              //       border: Border.all(
              //         color: Colors.black,
              //         width: 1,
              //       ),
              //       borderRadius: BorderRadius.circular(8),
              //     ),
              //     child: Column(
              //       children: [
              //         QuillSimpleToolbar(controller: controller),
              //         Divider(
              //           color: Colors.grey,
              //           thickness: 1,
              //           height: 20,
              //         ),
              //         QuillEditor(
              //           controller: controller,
              //           scrollController: ScrollController(),
              //           focusNode: FocusNode(),
              //           config: QuillEditorConfig(
              //             padding: EdgeInsets.all(10),
              //             autoFocus: false,
              //             expands: false,
              //             placeholder: 'Add your text here...',
              //           ),
              //         ),
              //       ],
              //     ),
              //   ),
              // ),

              // SizedBox(height: 20),

              // // Padding(
              // //   padding: const EdgeInsets.all(16),
              // //   child: Stack(
              // //     children: [
              // //       DropzoneView(
              // //         onCreated: (controller) => _dropController = controller,
              // //         onHover: () => setState(() => _isHovering = true),
              // //         onLeave: () => setState(() => _isHovering = false),
              // //         onDrop: (event) async {
              // //           final mime = await _dropController.getFileMIME(event);

              // //           if (!mime.startsWith('audio/')) {
              // //             ScaffoldMessenger.of(context).showSnackBar(
              // //               const SnackBar(content: Text("Chỉ được thả file audio")),
              // //             );
              // //             return;
              // //           }

              // //           final bytes = await _dropController.getFileData(event);
              // //           final name = await _dropController.getFilename(event);

              // //           _loadAudio(bytes, name);
              // //           setState(() => _isHovering = false);
              // //         },
              // //       ),
              // //       Container(
              // //         height: 150,
              // //         decoration: BoxDecoration(
              // //           border: Border.all(
              // //             color: _isHovering ? Colors.blue : Colors.grey,
              // //             width: 2,
              // //           ),
              // //           borderRadius: BorderRadius.circular(8),
              // //         ),
              // //         child: Center(
              // //           child: Column(
              // //             mainAxisAlignment: MainAxisAlignment.center,
              // //             children: [
              // //               const Text(
              // //                 "Kéo & thả file audio vào đây",
              // //                 style: TextStyle(fontSize: 16),
              // //               ),
              // //               const SizedBox(height: 10),
              // //               ElevatedButton(
              // //                 onPressed: _pickAudio,
              // //                 child: const Text("Hoặc chọn file"),
              // //               ),
              // //               if (_audioName != null)
              // //                 Padding(
              // //                   padding: const EdgeInsets.only(top: 8),
              // //                   child: Text("Đã chọn: $_audioName"),
              // //                 )
              // //             ],
              // //           ),
              // //         ),
              // //       ),
              // //     ],
              // //   ),
              // // ),

              // Padding(
              //   padding: EdgeInsets.all(16),
              //   child: Dropzone(
              //     onDroppedFile: (file) => setState(() => this.file = file),
              //     file: file,
              //   ),
              // ),

              // SizedBox(height: 20),

              SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    height: 500,
                    width: double.infinity,
                    child: PdfViewer.asset(
                      'assets/pdfs/Cam16_Reading.pdf',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}