import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:go_router/go_router.dart';
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';

import '../../models/part_model.dart';
import '../../widgets/layout/layout.dart';
import '../../widgets/test/dropzone.dart';

class CreateTestPage extends StatefulWidget {
  const CreateTestPage({super.key});

  @override
  State<CreateTestPage> createState() => _CreateTestPageState();
}

class _CreateTestPageState extends State<CreateTestPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _classNameController = TextEditingController();
  // bool _classNameError = false;

  final List<String> certificates = ["IELTS"];
  final List<String> skills = ["Listening", "Reading", "Speaking", "Writing"];
  final List<PartModel> _parts = [];

  String? _selectedCertificate;
  String? _selectedSkill;

  @override
  void initState() {
    super.initState();
    // _classNameController.addListener(_onClassNameChanged);
  }

  // void _onClassNameChanged(PartModel part) {
  //   if (part.classError && part.classController.text.trim().isNotEmpty) {
  //     setState(() {
  //       part.classError = false;
  //     });
  //   }
  // }

  @override
  void dispose() {
    _classNameController.dispose();

    // _classNameController.removeListener(_onClassNameChanged);
    for (var part in _parts) {
      part.textController.dispose();
      part.classController.dispose();
      part.classController.removeListener(part.onClassChanged);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Title(
      color: Colors.black,
      title: "Tạo đề thi",
      child: SiteLayout(
        menuNo: 11,
        content: Container(
          color: Colors.white,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_circle_left_outlined, size: 32),
                        onPressed: () {
                          context.go('/tests');
                        },
                      ),
                      Text(
                        "Thêm đề thi",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 20),

                  Padding(
                    padding: EdgeInsets.only(left: 50, right: 50),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Chọn chứng chỉ
                        Expanded(
                          child: DropdownSearch<String>(
                            items: (filter, loadProps) => certificates,
                            popupProps: PopupProps.menu(
                              disableFilter: true,
                              showSearchBox: false,
                              infiniteScrollProps: InfiniteScrollProps(
                                loadProps: LoadProps(skip: 0, take: 10),
                              ),
                              constraints: BoxConstraints(maxHeight: 150),
                              scrollbarProps: ScrollbarProps(
                                thumbVisibility: true,
                              ),
                              containerBuilder: (context, popupWidget) => Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.white,
                                ),
                                child: popupWidget,
                              ),
                              itemBuilder: (context, item, isDisabled, isSelected) => Container(
                                height: 40,
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  item,
                                  style: TextStyle(
                                    color: isSelected ? Color(0xFF1E40AF) : Colors.black,
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                            autoValidateMode: AutovalidateMode.onUserInteraction,
                            decoratorProps: DropDownDecoratorProps(
                              decoration: InputDecoration(
                                labelText: 'Chứng chỉ',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.red),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.red,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                            selectedItem: _selectedCertificate,
                            onChanged: (value) {
                              _selectedCertificate = value;
                            },
                            validator: (value) => value == null ? 'Vui lòng chọn chứng chỉ' : null,
                          ),
                        ),
                        SizedBox(width: 12),

                        // Chọn kỹ năng
                        Expanded(
                          child: DropdownSearch<String>(
                            items: (filter, loadProps) => skills,
                            popupProps: PopupProps.menu(
                              disableFilter: true,
                              showSearchBox: false,
                              infiniteScrollProps: InfiniteScrollProps(
                                loadProps: LoadProps(skip: 0, take: 10),
                              ),
                              constraints: BoxConstraints(maxHeight: 150),
                              scrollbarProps: ScrollbarProps(
                                thumbVisibility: true,
                              ),
                              containerBuilder: (context, popupWidget) => Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.white,
                                ),
                                child: popupWidget,
                              ),
                              itemBuilder: (context, item, isDisabled, isSelected) => Container(
                                height: 40,
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  item,
                                  style: TextStyle(
                                    color: isSelected ? Color(0xFF1E40AF) : Colors.black,
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                            autoValidateMode: AutovalidateMode.onUserInteraction,
                            decoratorProps: DropDownDecoratorProps(
                              decoration: InputDecoration(
                                labelText: 'Kỹ năng',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.red),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.red,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                            selectedItem: _selectedSkill,
                            onChanged: (value) {
                              _selectedSkill = value;
                            },
                            validator: (value) => value == null ? 'Vui lòng chọn kỹ năng' : null,
                          ),
                        ),
                        SizedBox(width: 12),

                        // Nút thêm part
                        Flexible(
                          child: Align(
                            alignment: Alignment.center,
                            child: ElevatedButton(
                              onPressed: () {
                                if (!_formKey.currentState!.validate()) {
                                  return;
                                }
                                setState(() {
                                  final part = PartModel(
                                    id: _parts.length, 
                                    classController: TextEditingController(),
                                    refresh: () => setState(() {}),
                                  );
                                  part.classController.addListener(part.onClassChanged);
                                  _parts.add(part);
                                });
                              },
                              style: ButtonStyle(
                                backgroundColor: WidgetStateProperty.all(
                                  Color(0xFF1E40AF),
                                ),
                                foregroundColor: WidgetStateProperty.all(Colors.white),
                                overlayColor: WidgetStateProperty.all(
                                  Colors.transparent,
                                ),
                                minimumSize: WidgetStateProperty.all(Size(150, 50)),
                                maximumSize: WidgetStateProperty.all(Size(150, 50)),
                                elevation: WidgetStateProperty.all(0),
                                shape: WidgetStateProperty.all(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.add_outlined, size: 20),
                                  SizedBox(width: 4),
                                  Text('Thêm part'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 12),

                  // Thêm part
                  Column(
                    children: _parts.map((part) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        width: double.infinity,
                        color: Colors.grey.shade400,
                        alignment: Alignment.center,
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Center(
                                    child: Text(
                                      "Part ${part.id + 1}",
                                      style: TextStyle(color: Colors.black),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.close, size: 16,),
                                  onPressed: () {
                                    setState(() {
                                      part.textController.dispose();
                                      part.classController.dispose();
                                      part.classController.removeListener(part.onClassChanged);
                                      _parts.remove(part);
                                    });
                                  },
                                  style: ButtonStyle(
                                    padding: WidgetStateProperty.all(EdgeInsets.zero),
                                    minimumSize: WidgetStateProperty.all(Size(16, 16)),
                                    maximumSize: WidgetStateProperty.all(Size(16, 16)),
                                  ),
                                ),
                              ],
                            ),
                            if (_selectedSkill == "Listening") 
                              Padding(
                                padding: EdgeInsets.all(16),
                                child: Dropzone(
                                  onDroppedFile: (file) => setState(() => part.audioFile = file),
                                  file: part.audioFile,     
                                ),
                              )
                            else if (_selectedSkill == "Reading") 
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
                                      QuillSimpleToolbar(controller: part.textController),
                                      Divider(
                                        color: Colors.grey,
                                        thickness: 1,
                                        height: 20,
                                      ),
                                      QuillEditor(
                                        controller: part.textController,
                                        scrollController: ScrollController(),
                                        focusNode: FocusNode(),
                                        config: QuillEditorConfig(
                                          padding: EdgeInsets.all(10),
                                          autoFocus: false,
                                          expands: false,
                                          placeholder: 'Add your passage here...',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else Container(),
                            // TextField(
                            //   controller: part.classController,
                            //   decoration: InputDecoration(
                            //     labelText: 'Tên lớp',
                            //     errorText: part.classError
                            //         ? 'Vui lòng nhập tên'
                            //         : null,
                            //     border: OutlineInputBorder(
                            //       borderRadius: BorderRadius.circular(12),
                            //     ),
                            //     errorBorder: OutlineInputBorder(
                            //       borderRadius: BorderRadius.circular(12),
                            //       borderSide: BorderSide(color: Colors.red),
                            //     ),
                            //     focusedErrorBorder: OutlineInputBorder(
                            //       borderRadius: BorderRadius.circular(12),
                            //       borderSide: BorderSide(
                            //         color: Colors.red,
                            //         width: 2,
                            //       ),
                            //     ),
                            //   ),
                            //   textInputAction: TextInputAction.next,
                            // ),

                            Row(
                              children: [
                                Expanded(child: Container()),
                                ElevatedButton(
                                  onPressed: () async {
                                    // setState(() {
                                    //   for (var part in _parts) {
                                    //     if (part.classController.text.trim().isEmpty) {
                                    //       part.classError = true;
                                    //     } else {
                                    //       part.classError = false;
                                    //     }
                                    //   }
                                    // });

                                    // if (!_formKey.currentState!.validate() || _parts.any((part) => part.classError)) {
                                    //   return;
                                    // }

                                    // for (var part in _parts) {
                                    //   print("Part ${part.id + 1}:");
                                    //   if (_selectedSkill == "Listening") {
                                    //     print("Audio file: ${part.audioFile!.name}");
                                    //   }
                                    //   if (_selectedSkill == "Reading" && part.textController.document.toPlainText().trim().isNotEmpty) {
                                    //     final delta = part.textController.document.toDelta();
                                    //     final converter = QuillDeltaToHtmlConverter(
                                    //       delta.toJson(),
                                    //       ConverterOptions.forEmail(), // hoặc ConverterOptions()
                                    //     );

                                    //     final html = converter.convert();

                                    //     print(html);
                                    //   }
                                    // }
                                  },
                                  style: ButtonStyle(
                                    backgroundColor: WidgetStateProperty.all(
                                      Color(0xFF1E40AF),
                                    ),
                                    foregroundColor: WidgetStateProperty.all(Colors.white),
                                    overlayColor: WidgetStateProperty.all(
                                      Colors.transparent,
                                    ),
                                    minimumSize: WidgetStateProperty.all(Size(150, 50)),
                                    elevation: WidgetStateProperty.all(0),
                                    shape: WidgetStateProperty.all(
                                      RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.add_outlined, size: 20),
                                      SizedBox(width: 4),
                                      Text('Thêm dạng câu hỏi'),
                                    ],
                                  ),
                                ),
                                Expanded(child: Container()),
                              ],
                            ),

                            Column(
                              children: [
                                
                              ],
                            ),
                          ],
                        ),
                      ),
                    )).toList(),
                  ),

                  SizedBox(height: 20),

                  // Nút tạo đề thi
                  Row(
                    children: [
                      Expanded(child: Container()),
                      ElevatedButton(
                        onPressed: () async {
                          // setState(() {
                          //   for (var part in _parts) {
                          //     if (part.classController.text.trim().isEmpty) {
                          //       part.classError = true;
                          //     } else {
                          //       part.classError = false;
                          //     }
                          //   }
                          // });

                          if (!_formKey.currentState!.validate() || _parts.any((part) => part.classError)) {
                            return;
                          }

                          for (var part in _parts) {
                            print("Part ${part.id + 1}:");
                            if (_selectedSkill == "Listening") {
                              print("Audio file: ${part.audioFile!.name}");
                            }
                            if (_selectedSkill == "Reading" && part.textController.document.toPlainText().trim().isNotEmpty) {
                              final delta = part.textController.document.toDelta();
                              final converter = QuillDeltaToHtmlConverter(
                                delta.toJson(),
                                ConverterOptions.forEmail(), // hoặc ConverterOptions()
                              );

                              final html = converter.convert();

                              print(html);
                            }
                          }
                        },
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all(
                            Color(0xFF1E40AF),
                          ),
                          foregroundColor: WidgetStateProperty.all(Colors.white),
                          overlayColor: WidgetStateProperty.all(
                            Colors.transparent,
                          ),
                          minimumSize: WidgetStateProperty.all(Size(150, 50)),
                          elevation: WidgetStateProperty.all(0),
                          shape: WidgetStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        child: Text('Thêm vào lớp học'),
                      ),
                      Expanded(child: Container()),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}