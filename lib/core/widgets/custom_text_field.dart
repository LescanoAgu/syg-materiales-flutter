import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final IconData? icon;
  final TextInputType? keyboardType;
  final Function(String)? onChanged;
  final String? hint;
  final int maxLines;
  // ✅ Nuevo parámetro agregado
  final bool readOnly;

  const CustomTextField({
    super.key,
    required this.label,
    this.controller,
    this.icon,
    this.keyboardType,
    this.onChanged,
    this.hint,
    this.maxLines = 1,
    this.readOnly = false, // Default false
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      maxLines: maxLines,
      readOnly: readOnly, // ✅ Usado aquí
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        filled: true,
        fillColor: readOnly ? Colors.grey.shade100 : Colors.white,
      ),
    );
  }
}