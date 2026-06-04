import 'dart:convert';

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html/flutter_html.dart' as html;
import 'package:flutter_quill/flutter_quill.dart';

import '../../constants/error_list.dart';
import '../../exceptions/unauthorized_exception.dart';
import '../../models/writing_task_grade_model.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

class WritingTaskGrading extends StatefulWidget {
  final String assessmentId;
  final WritingExerciseGrade gradeModel;
  final Map<String, dynamic> answerData;

  const WritingTaskGrading({super.key, required this.assessmentId, required this.gradeModel, required this.answerData});

  @override
  State<WritingTaskGrading> createState() => _WritingTaskGradingState();
}

class _WritingTaskGradingState extends State<WritingTaskGrading> {
  late final Future<Map<String, dynamic>> _partInfoFuture;

  final List<double> scores =
      List.generate(19, (index) => index * 0.5);

  double? calculateOverall() {
    if ([widget.gradeModel.task, widget.gradeModel.coherence, widget.gradeModel.lexical, widget.gradeModel.grammar]
        .any((e) => e == null)) return null;

    double avg =
        (widget.gradeModel.task! + widget.gradeModel.coherence! + widget.gradeModel.lexical! + widget.gradeModel.grammar!) / 4;

    return (avg * 2).round() / 2;
  }

  void updateOverall() {
    setState(() {
      widget.gradeModel.overall = calculateOverall();
    });
  }

  void addError() {
    setState(() {
      widget.gradeModel.errors.add(WritingError());
    });
  }

  void removeError(int index) {
    setState(() {
      widget.gradeModel.errors.removeAt(index);
    });
  }

  Widget buildDropdown(String label, double? value, Function(double?) onChanged) {
    return DropdownSearch<double>(
      selectedItem: value,
      decoratorProps: DropDownDecoratorProps(
        decoration: InputDecoration(
          labelText: label,
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
      items: (_, _) => scores,
      onChanged: (val) {
        onChanged(val);
        updateOverall();
      },
    );
  }

  Future<Map<String, dynamic>> _loadPartInfo(String exerciseId, int partNumber) async {
    var response = await ApiService.get(
      '/identity/writing-assessments/$exerciseId?partNumber=$partNumber',
      token: authService.accessToken,
    );

    if (response.statusCode == 401) {
      var refreshResponse = await ApiService.post(
        '/identity/auth/refresh',
        body: {'token': authService.accessToken},
      );

      var refreshData = jsonDecode(refreshResponse.body);
      if (refreshData['code'] == 1000) {
        final newToken = refreshData['result']['token'];
        await authService.setAuth(newToken);

        response = await ApiService.get(
          '/identity/writing-assessments/$exerciseId?partNumber=$partNumber',
          token: authService.accessToken,
        );
      } else {
        await authService.clearAuth();
        throw UnauthorizedException();
      }
    }

    return jsonDecode(response.body);
  }

  @override
  void initState() {
    super.initState();
    _partInfoFuture = _loadPartInfo(widget.assessmentId, widget.answerData['questionNumber']);
    if (widget.answerData['evaluationId'] != null) {}
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _partInfoFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Lỗi tải dữ liệu'));
        } else if (snapshot.hasData) {
          final result = snapshot.data!['result'];
          return Column(
            children: [
              Text(
                'Task ${result['partNumber']}',
                style: TextStyle(
                  fontSize: 20, 
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E40AF),
                ),
              ),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Đề bài',
                  style: TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              Html(
                data: result['text'] ?? 'No title available',
                style: {
                  "body": html.Style(fontSize: FontSize(16.0)),
                },
              ),

              if (result['imageUrl'] != null) Image.network(result['imageUrl']),
              const SizedBox(height: 12),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Bài làm học viên',
                  style: TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 4),

              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey.shade400, 
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[50],
                ),
                padding: const EdgeInsets.all(4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.answerData['textAnswer'] ?? 'No answer provided',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Chấm điểm",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      var response = await ApiService.post(
                        '/identity/writing-grading/auto',
                        token: authService.accessToken,
                        body: {
                          'question': result['text'],
                          'answer': widget.answerData['textAnswer'],
                          'imageUrl': result['imageUrl'],
                        }
                      );

                      if (response.statusCode == 401) {
                        var refreshResponse = await ApiService.post(
                          '/identity/auth/refresh',
                          body: {'token': authService.accessToken},
                        );

                        var refreshData = jsonDecode(refreshResponse.body);
                        if (refreshData['code'] == 1000) {
                          final newToken = refreshData['result']['token'];
                          await authService.setAuth(newToken);

                          response = await ApiService.post(
                            '/identity/writing-grading/auto',
                            token: authService.accessToken,
                            body: {
                              'question': result['text'],
                              'answer': widget.answerData['textAnswer'],
                              'imageUrl': result['imageUrl'],
                            }
                          );
                        } else {
                          await authService.clearAuth();
                          throw UnauthorizedException();
                        }
                      }

                      final data = jsonDecode(response.body);
                      if (data != null && data['code'] == 1000) {
                        setState(() {
                          widget.gradeModel.task = data['result']['trScore'];
                          widget.gradeModel.coherence = data['result']['ccScore'];
                          widget.gradeModel.lexical = data['result']['lrScore'];
                          widget.gradeModel.grammar = data['result']['graScore'];
                          widget.gradeModel.overall = calculateOverall();
                          widget.gradeModel.errors = (data['result']['errors'] as List<dynamic>).map((e) => WritingError(
                            type: e['studentErrorType'],
                            description: e['errorDescription'],
                          )).toList();
                          widget.gradeModel.commentController.document = Document()..insert(0, data['result']['feedback'] ?? '');
                        });
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Chấm bài Writing Task ${result['partNumber']} thành công')),
                        );
                      } else {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Chấm bài Writing Task ${result['partNumber']} thất bại')),
                        );
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
                      minimumSize: WidgetStateProperty.all(Size(100, 40)),
                      elevation: WidgetStateProperty.all(0),
                      shape: WidgetStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    child: const Text("Chấm tự động"),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: buildDropdown(
                      "Task Achievement / Response", 
                      widget.gradeModel.task,
                      (val) => widget.gradeModel.task = val,
                    ),
                  ),
                  SizedBox(width: 5),
                  Expanded(
                    child: buildDropdown(
                      "Coherence and Cohesion", 
                      widget.gradeModel.coherence,
                      (val) => widget.gradeModel.coherence = val,
                    ),
                  ),
                  SizedBox(width: 5),
                  Expanded(
                    child: buildDropdown(
                      "Lexical Resource", 
                      widget.gradeModel.lexical,
                      (val) => widget.gradeModel.lexical = val,
                    ),
                  ),
                  SizedBox(width: 5),
                  Expanded(
                    child: buildDropdown(
                      "Grammatical Range and Accuracy",
                      widget.gradeModel.grammar,
                      (val) => widget.gradeModel.grammar = val,
                    ),
                  ),
                ],
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Overall score",
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    widget.gradeModel.overall != null
                        ? widget.gradeModel.overall!.toStringAsFixed(1)
                        : "--",
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  )
                ],
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Danh sách lỗi sai",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: addError,
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(
                        Color(0xFF1E40AF),
                      ),
                      foregroundColor: WidgetStateProperty.all(Colors.white),
                      overlayColor: WidgetStateProperty.all(
                        Colors.transparent,
                      ),
                      minimumSize: WidgetStateProperty.all(Size(100, 40)),
                      elevation: WidgetStateProperty.all(0),
                      shape: WidgetStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    child: const Text("Thêm lỗi sai"),
                  )
                ],
              ),

              const SizedBox(height: 12),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.gradeModel.errors.length,
                itemBuilder: (_, index) {
                  final error = widget.gradeModel.errors[index];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 5),
                    color: Colors.grey[100],
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: DropdownSearch<String>(
                              items: (filter, loadProps) => errorTypes.map((e) => e['id'] ?? '').toList(),
                              itemAsString: (item) => getErrorTypeName(item),
                              autoValidateMode: AutovalidateMode.onUserInteraction,
                              decoratorProps: DropDownDecoratorProps(
                                decoration: InputDecoration(
                                  labelText: 'Loại lỗi sai',
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
                              selectedItem: error.type,
                              onChanged: (val) {
                                setState(() {
                                  error.type = val;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: error.descriptionController,
                              decoration: const InputDecoration(
                                labelText: "Mô tả lỗi sai",
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => removeError(index),
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Nhận xét tổng thể",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Container(
                height: 200,
                decoration: BoxDecoration(
                  border:
                      Border.all(color: Colors.grey),
                ),
                child: QuillEditor.basic(
                  controller: widget.gradeModel.commentController,
                ),
              ),

              Divider(
                height: 32,
                thickness: 2,
                color: Colors.grey[600],
              ),
            ],
          );
        }
        else {
          return Container();
        }
      },
    );
  }
}