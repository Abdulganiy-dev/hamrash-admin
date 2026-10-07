import 'package:flutter/material.dart';

/// Utility class for text field operations
class TextFieldUtil {
  /// Sanitizes numeric input by removing leading zeros
  /// 
  /// Example:
  /// - "00123" -> "123"
  /// - "000" -> "0"
  /// - "123" -> "123"
  /// 
  /// Returns the sanitized value and updates the controller if needed
  static String sanitizeNumericInput(TextEditingController controller) {
    String sanitizedValue = controller.text;
    
    if (sanitizedValue.length > 1 && sanitizedValue.startsWith('0')) {
      sanitizedValue = sanitizedValue.replaceFirst(RegExp(r'^0+'), '');
      if (sanitizedValue.isEmpty) {
        sanitizedValue = '0';
      }

      controller.value = TextEditingValue(
        text: sanitizedValue,
        selection: TextSelection.collapsed(offset: sanitizedValue.length),
      );
    }
    
    return sanitizedValue;
  }
}

