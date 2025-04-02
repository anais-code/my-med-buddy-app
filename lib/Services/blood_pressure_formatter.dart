import 'package:flutter/services.dart';

// Create a custom TextInputFormatter to allow only digits and "/"
class BloodPressureInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // Only allow digits and "/"
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9/]'), '');

    // Ensure only one "/" is allowed
    if (newText.contains("/") && newText.indexOf("/") != newText.lastIndexOf("/")) {
      newText = newText.substring(0, newText.lastIndexOf("/"));
    }

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

