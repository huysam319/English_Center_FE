import 'package:english_center_fe/controllers/text_input_controller.dart';
import 'package:flutter/material.dart';

class PasswordField extends StatefulWidget {
  final bool showError;
  final String? errorText;

  const PasswordField({super.key, this.showError = false, this.errorText});

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: passwordController,
      obscureText: _obscure,
      decoration: InputDecoration(
        labelText: "Password",
        errorText: widget.showError ? (widget.errorText ?? 'Vui lòng nhập mật khẩu') : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscure ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: () {
            setState(() {
              _obscure = !_obscure;
            });
          },
        ),
      ),
    );
  }
}