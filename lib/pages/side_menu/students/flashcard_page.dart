import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../exceptions/unauthorized_exception.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/layout/layout.dart';

class FlashcardPage extends StatefulWidget {
  const FlashcardPage({super.key});

  @override
  State<FlashcardPage> createState() => _FlashcardPageState();
}

class _FlashcardPageState extends State<FlashcardPage> {
  final TextEditingController _flashcardSetNameController = TextEditingController();
  final TextEditingController _flashcardSetDescriptionController = TextEditingController();
  final GlobalKey<FormState> _flashcardSetFormKey = GlobalKey<FormState>();
  late final Future<Map<String, dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadAllFlashcardSets(0, 15);
  }

  Future<Map<String, dynamic>> _loadAllFlashcardSets(int page, int size) async {
    var response = await ApiService.get(
      '/identity/flashcards/sets?page=$page&size=$size',
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
          '/identity/flashcards/sets?page=$page&size=$size',
          token: authService.accessToken,
        );
      } else {
        await authService.clearAuth();
        throw UnauthorizedException();
      }
    }

    final decoded = jsonDecode(response.body);
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  }

  List<Map<String, dynamic>> _extractFlashcardSets(Map<String, dynamic>? data) {
    final result = data?['result'];
    final rawList = result is Map ? result['content'] : result;
    if (rawList is! List) {
      return [];
    }

    return rawList
        .whereType<Map>()
        .map((item) => item.map((key, value) => MapEntry('$key', value)))
        .toList();
  }

  @override
  void dispose() {
    _flashcardSetNameController.dispose();
    _flashcardSetDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Title(
      color: Colors.black,
      title: "Flashcards",
      child: SiteLayout(
        menuNo: 8,
        content: SelectionArea( 
          child: Container(
            color: Colors.white,
            child: Padding(
              padding: EdgeInsets.fromLTRB(50, 16, 50, 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: Container()),
                      ElevatedButton(
                        onPressed: () {
                          _flashcardSetNameController.clear();
                          _flashcardSetDescriptionController.clear();
                          _flashcardSetFormKey.currentState?.reset();

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
                                        child: Text("Tạo bộ flashcard mới"),
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
                                      key: _flashcardSetFormKey,
                                      autovalidateMode: AutovalidateMode.onUserInteraction,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TextFormField(
                                            controller: _flashcardSetNameController,
                                            decoration: InputDecoration(
                                              label: Text.rich(
                                                TextSpan(
                                                  text: 'Tên bộ flashcard',
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
                                                return 'Vui lòng nhập tên bộ flashcard';
                                              }
                                              if (trimmedValue.length < 3) {
                                                return 'Tên bộ flashcard phải có ít nhất 3 ký tự';
                                              }
                                              return null;
                                            },
                                            textInputAction: TextInputAction.next,
                                          ),
                                          SizedBox(height: 12),
                                          TextFormField(
                                            controller: _flashcardSetDescriptionController,
                                            decoration: InputDecoration(
                                              labelText: 'Mô tả',
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                            ),
                                            textInputAction: TextInputAction.done,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  actions: [
                                    ElevatedButton(
                                      onPressed: () async {
                                        if (!(_flashcardSetFormKey.currentState?.validate() ?? false)) {
                                          return;
                                        }

                                        var response = await ApiService.post(
                                          '/identity/flashcards',
                                          token: authService.accessToken,
                                          body: {
                                            'name': _flashcardSetNameController.text,
                                            'description': _flashcardSetDescriptionController.text,
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
                                              '/identity/flashcards',
                                              token: authService.accessToken,
                                              body: {
                                                'name': _flashcardSetNameController.text,
                                                'description': _flashcardSetDescriptionController.text,
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
                                            SnackBar(content: Text('Tạo bộ flashcard thành công')),
                                          );
                                          context.go('/flashcard');
                                        } else {
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Tạo bộ flashcard thất bại')),
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
                            Text('Thêm bộ flashcard mới'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Expanded(
                    child: FutureBuilder<Map<String, dynamic>>(
                      future: _dataFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          final err = snapshot.error;
                          if (err is UnauthorizedException) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) context.go('/login');
                            });
                            return SizedBox.shrink();
                          }
                          return Center(
                            child: Text('Lỗi tải thông tin bộ flashcard'),
                          );
                        } else if (snapshot.hasData) {
                          final flashcardSets = _extractFlashcardSets(snapshot.data);
                          final result = flashcardSets;
                          if (result is! List) {
                            return Center(
                              child: Text('Dữ liệu bộ flashcard không hợp lệ'),
                            );
                          }

                          final ignoredFlashcardSets = result
                              .whereType<Map>()
                              .map(
                                (e) => e.map((k, v) => MapEntry(k.toString(), v)),
                              )
                              .toList();

                          if (flashcardSets.isEmpty) {
                            return Center(
                              child: Text('Chưa có bộ flashcard nào'),
                            );
                          }

                          return GridView.builder(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 1.5,
                            ),
                            itemCount: flashcardSets.length,
                            itemBuilder: (context, index) {
                              final flashcardSet = flashcardSets[index];
                              return Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: () {
                                    context.go('/flashcard/${flashcardSet['id']}');
                                  },
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Container(
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.blue.shade300,
                                                Colors.blue.shade500,
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              flashcardSet['name'] ?? '',
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              flashcardSet['description'] ?? '',
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 12,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        } else {
                          return Center(child: Text('Không có dữ liệu'));
                        }
                      },
                    ),
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
