import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:http/src/response.dart';

import '../../services/api_service.dart';

class PaginatedDropdownForm extends StatefulWidget {
  const PaginatedDropdownForm({super.key});

  @override
  _PaginatedDropdownFormState createState() => _PaginatedDropdownFormState();
}

class _PaginatedDropdownFormState extends State<PaginatedDropdownForm> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedUser;

  // Giả lập hàm gọi API với phân trang
  Future<List<String>> getData(String filter, int page) async {
    try {
      // Thay thế URL bằng API thực tế của bạn
      // Tham số: page (trang hiện tại), filter (từ khóa tìm kiếm)
      var response = await ApiService.get(
        "https://63d123456.mockapi.io",
        // body: {"search": filter, "page": page, "limit": 10},
      );

      final data = response.data;
      if (data != null) {
        return List<String>.from(data.map((item) => item['name']));
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Dropdown API Phân Trang")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Sử dụng DropdownSearch thay cho DropdownButtonFormField2
              DropdownSearch<String>(
                // 1. Cấu hình lấy dữ liệu từ API
                items: (filter, loadProps) => getData(filter, loadProps!.skip ~/ 10 + 1),

                // 2. Cấu hình tìm kiếm
                popupProps: PopupProps.menu(
                  showSearchBox: true,
                  searchFieldProps: TextFieldProps(
                    decoration: InputDecoration(hintText: "Tìm kiếm tên..."),
                  ),
                  infiniteScrollProps: InfiniteScrollProps(
                    loadProps: LoadProps(skip: 0, take: 10),
                  ),
                ),

                // 3. Form decoration
                decoratorProps: DropDownDecoratorProps(
                  decoration: InputDecoration(
                    labelText: "Chọn thành viên",
                    border: OutlineInputBorder(),
                  ),
                ),
                onChanged: (value) => setState(() => _selectedUser = value),
                selectedItem: _selectedUser,
                
                // Validator cho Form
                validator: (value) => value == null ? "Vui lòng chọn một mục" : null,
              ),

              SizedBox(height: 20),
              
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    print("Dữ liệu đã chọn: $_selectedUser");
                  }
                },
                child: Text("Gửi Form"),
              )
            ],
          ),
        ),
      ),
    );
  }
}

extension on Response {
   get data => null;
}