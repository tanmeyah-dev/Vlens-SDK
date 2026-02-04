import 'package:flutter/services.dart';

class ArabicOnlyFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Extract only Arabic characters from the new value (remove spaces and non-Arabic characters)
    final arabicOnly = newValue.text.replaceAll(RegExp(r'[^\u0600-\u06FF]'), '');
    
    // If the text changed (filtered out some characters), update the selection
    if (arabicOnly != newValue.text) {
      // Calculate the new cursor position
      // Count how many characters were removed before the cursor
      int removedBeforeCursor = 0;
      for (int i = 0; i < newValue.selection.baseOffset && i < newValue.text.length; i++) {
        if (!RegExp(r'[\u0600-\u06FF]').hasMatch(newValue.text[i])) {
          removedBeforeCursor++;
        }
      }
      final newOffset = (newValue.selection.baseOffset - removedBeforeCursor).clamp(0, arabicOnly.length);
      
      return TextEditingValue(
        text: arabicOnly,
        selection: TextSelection.collapsed(offset: newOffset),
      );
    }
    
    return newValue;
  }
}
