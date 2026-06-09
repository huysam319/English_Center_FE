import 'package:flutter/material.dart';

class PasswordField extends StatefulWidget {
  final bool showError;
  final TextEditingController controller;
  final String labelText;
  final String errorText;
  final String? hintText;
  final TextInputAction? textInputAction;

  const PasswordField({
    super.key,
    this.showError = false,
    required this.controller,
    required this.labelText,
    required this.errorText,
    this.hintText,
    this.textInputAction,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300),
    );

    return TextField(
      controller: widget.controller,
      textInputAction: widget.textInputAction,
      obscureText: _obscure,
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        errorText: widget.showError ? widget.errorText : null,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        labelStyle: const TextStyle(color: Color(0xFF475569)),
        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: Color(0xFF1E40AF), width: 1.5),
        ),
        errorBorder: border.copyWith(
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: border.copyWith(
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        suffixIcon: IconButton(
          splashRadius: 20,
          icon: Icon(
            _obscure ? Icons.visibility_off : Icons.visibility,
            color: const Color(0xFF64748B),
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