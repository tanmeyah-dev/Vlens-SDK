import 'package:flutter/services.dart';

class PhoneNumberFormatter extends TextInputFormatter {
  final String? previousValue;

  PhoneNumberFormatter({this.previousValue});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final currentText = newValue.text;

    // If text is empty, return as is
    if (currentText.isEmpty) {
      return newValue;
    }

    // Check if user tried to add "0" at the beginning when there's already "0"
    if (previousValue != null &&
        previousValue!.startsWith('0') &&
        currentText.startsWith('00')) {
      // Ignore the duplicate "0" - revert to previous text
      final cursorPosition = newValue.selection.baseOffset > 0
          ? newValue.selection.baseOffset - 1
          : 0;
      return TextEditingValue(
        text: previousValue!,
        selection: TextSelection.collapsed(offset: cursorPosition),
      );
    }

    // If text doesn't start with "0" and is not empty, add "0" at the beginning
    if (!currentText.startsWith('0') && currentText.isNotEmpty) {
      final newText = '0$currentText';
      final cursorPosition = newValue.selection.baseOffset + 1;
      return TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: cursorPosition),
      );
    }

    return newValue;
  }
}
