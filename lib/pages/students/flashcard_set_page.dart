import 'dart:convert';

import 'package:flip_card/flip_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../exceptions/unauthorized_exception.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/layout/layout.dart';

class FlashcardSetPage extends StatefulWidget {
  final String flashcardSetId;

  const FlashcardSetPage({super.key, required this.flashcardSetId});

  @override
  State<FlashcardSetPage> createState() => _FlashcardSetPageState();
}

class _FlashcardSetPageState extends State<FlashcardSetPage> {
  final TextEditingController _wordController = TextEditingController();
  final TextEditingController _meaningController = TextEditingController();
  final TextEditingController _wordFormController = TextEditingController();
  final TextEditingController _exampleController = TextEditingController();
  final GlobalKey<FormState> _flashcardFormKey = GlobalKey<FormState>();
  late final Future<Map<String, dynamic>> _flashcardsFuture;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _flashcardsFuture = _loadAllFlashcards(widget.flashcardSetId);
  }

  Future<Map<String, dynamic>> _loadAllFlashcards(String flashcardSetId) async {
    var response = await ApiService.get(
      '/identity/flashcards/getdetailflashcards/$flashcardSetId',
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
          '/identity/flashcards/getdetailflashcards/$flashcardSetId',
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
  Widget build(BuildContext context) {
    return Title(
      color: Colors.black,
      title: "Chi tiết flashcard",
      child: SiteLayout(
        menuNo: 8,
        content: SelectionArea( 
          child: Container(
            color: Colors.white,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Container()),
                      ElevatedButton(
                        onPressed: () {
                          _wordController.clear();
                          _meaningController.clear();
                          _wordFormController.clear();
                          _exampleController.clear();
                          _flashcardFormKey.currentState?.reset();

                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (BuildContext context) {
                              return Padding(
                                padding: EdgeInsets.all(30),
                                child: AlertDialog(
                                  title: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text("Tạo từ vựng mới"),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.close),
                                        iconSize: 16,
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                      )
                                    ],
                                  ),
                                  content: SizedBox(
                                    width: 400,
                                    child: Form(
                                      key: _flashcardFormKey,
                                      autovalidateMode: AutovalidateMode.onUserInteraction,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TextFormField(
                                            controller: _wordController,
                                            decoration: InputDecoration(
                                              label: Text.rich(
                                                TextSpan(
                                                  text: 'Từ vựng',
                                                  children: [
                                                    TextSpan(
                                                      text: ' *',
                                                      style: TextStyle(color: Colors.red),
                                                    ),
                                                  ],
                                                ),
                                              ),
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
                                            validator: (value) {
                                              final trimmedValue = value?.trim() ?? '';
                                              if (trimmedValue.isEmpty) {
                                                return 'Vui lòng nhập từ vựng';
                                              }
                                              if (trimmedValue.length > 255) {
                                                return 'Từ vựng không được vượt quá 255 ký tự';
                                              }
                                              return null;
                                            },
                                            textInputAction: TextInputAction.next,
                                          ),
                                          SizedBox(height: 12),
                                          TextFormField(
                                            controller: _meaningController,
                                            decoration: InputDecoration(
                                              label: Text.rich(
                                                TextSpan(
                                                  text: 'Nghĩa của từ',
                                                  children: [
                                                    TextSpan(
                                                      text: ' *',
                                                      style: TextStyle(color: Colors.red),
                                                    ),
                                                  ],
                                                ),
                                              ),
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
                                            validator: (value) {
                                              final trimmedValue = value?.trim() ?? '';
                                              if (trimmedValue.isEmpty) {
                                                return 'Vui lòng nhập nghĩa của từ';
                                              }
                                              if (trimmedValue.length > 255) {
                                                return 'Nghĩa của từ không được vượt quá 255 ký tự';
                                              }
                                              return null;
                                            },
                                            textInputAction: TextInputAction.next,
                                          ),
                                          SizedBox(height: 12),
                                          TextFormField(
                                            controller: _wordFormController,
                                            decoration: InputDecoration(
                                              label: Text.rich(
                                                TextSpan(
                                                  text: 'Từ loại',
                                                ),
                                              ),
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
                                            validator: (value) {
                                              final trimmedValue = value?.trim() ?? '';
                                              if (trimmedValue.length > 255) {
                                                return 'Từ loại không được vượt quá 255 ký tự';
                                              }
                                              return null;
                                            },
                                            textInputAction: TextInputAction.next,
                                          ),
                                          SizedBox(height: 12),
                                          TextFormField(
                                            controller: _exampleController,
                                            decoration: InputDecoration(
                                              label: Text.rich(
                                                TextSpan(
                                                  text: 'Ví dụ',
                                                ),
                                              ),
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
                                            textInputAction: TextInputAction.next,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  actions: [
                                    ElevatedButton(
                                      onPressed: () async {
                                        if (!(_flashcardFormKey.currentState?.validate() ?? false)) {
                                          return;
                                        }

                                        var response = await ApiService.post(
                                          '/identity/flashcards/adddetailflashcards/${widget.flashcardSetId}',
                                          token: authService.accessToken,
                                          body: {
                                            'word': _wordController.text,
                                            'meaning': _meaningController.text,
                                            'wordForm': _wordFormController.text,
                                            'example': _exampleController.text,
                                          },
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
                                              '/identity/flashcards/adddetailflashcards/${widget.flashcardSetId}',
                                              token: authService.accessToken,
                                              body: {
                                                'word': _wordController.text,
                                                'meaning': _meaningController.text,
                                                'wordForm': _wordFormController.text,
                                                'example': _exampleController.text,
                                              },
                                            );
                                          } else {
                                            await authService.clearAuth();
                                            throw UnauthorizedException();
                                          }
                                        }

                                        final data = jsonDecode(response.body);
                                        if (data != null && data['code'] == 1000) {
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Tạo từ vựng thành công')),
                                          );
                                          context.go('/flashcard/${widget.flashcardSetId}');
                                        } else {
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Tạo từ vựng thất bại')),
                                          );
                                        }

                                        Navigator.pop(context);
                                      },
                                      style: ButtonStyle(
                                        backgroundColor: WidgetStateProperty.all(
                                          Color(0xFF1E40AF),
                                        ),
                                        foregroundColor: WidgetStateProperty.all(Colors.white),
                                        overlayColor: WidgetStateProperty.all(
                                          Colors.transparent,
                                        ),
                                        minimumSize: WidgetStateProperty.all(Size(100, 50)),
                                        elevation: WidgetStateProperty.all(0),
                                        shape: WidgetStateProperty.all(
                                          RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        ),
                                      ),
                                      child: Text("Tạo"),
                                    )
                                  ],
                                ),
                              );
                            },
                          );
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
                            Text('Thêm từ vựng mới'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  FutureBuilder<Map<String, dynamic>>(
                    future: _flashcardsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Text('Lỗi khi tải flashcards: ${snapshot.error}');
                      } else if (!snapshot.hasData || snapshot.data!['code'] != 1000) {
                        return Text('Không có flashcards nào');
                      } else {
                        final flashcards = snapshot.data!['result'] as List<dynamic>;
                        final flashcard = flashcards[_currentIndex];

                        return Column(
                          children: [
                            SizedBox(height: 20),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Nút trái
                                IconButton(
                                  icon: Icon(Icons.arrow_back_ios),
                                  onPressed: _currentIndex > 0
                                      ? () {
                                          setState(() {
                                            _currentIndex--;
                                          });
                                        }
                                      : null,
                                ),

                                FlipCard(
                                  front: Card(
                                    color: Color.lerp(Color(0xFF1E40AF), Colors.white, 0.1),
                                    elevation: 4,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: SizedBox(
                                      width: 350,
                                      height: 250,
                                      child: Center(
                                        child: Text(
                                          flashcard['word'] ?? '',
                                          style: TextStyle(
                                            fontSize: 24, 
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  back: Card(
                                    color: Color.lerp(Color(0xFF1E40AF), Colors.white, 0.7),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: SizedBox(
                                      width: 350,
                                      height: 250,
                                      child: Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              flashcard['meaning'] ?? '',
                                              style: TextStyle(color: Colors.black, fontSize: 18),
                                              textAlign: TextAlign.center,
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              flashcard['wordForm'] ?? '',
                                              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              flashcard['example'] ?? '',
                                              style: TextStyle(color: Colors.black87),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // Nút phải
                                IconButton(
                                  icon: Icon(Icons.arrow_forward_ios),
                                  onPressed: _currentIndex < flashcards.length - 1
                                      ? () {
                                          setState(() {
                                            _currentIndex++;
                                          });
                                        }
                                      : null,
                                ),
                              ],
                            ),

                            SizedBox(height: 16),

                            // Hiển thị vị trí
                            Text(
                              '${_currentIndex + 1} / ${flashcards.length}',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        );
                      }
                    },
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