class SecurityCodeValidator {
  /// Validates if the code contains only digits
  static bool hasOnlyDigits(String code) {
    return RegExp(r'^\d+$').hasMatch(code);
  }

  /// Validates if the code length is at least the minimum length
  static bool hasMinimumLength(String code, int minLength) {
    return code.length >= minLength;
  }

  /// Validates if the code contains sequential numbers (ascending or descending)
  static bool isSequential(String code) {
    if (code.length < 3) return false;
    
    // Check ascending sequence (e.g., 123456, 234567)
    bool isAscending = true;
    for (int i = 1; i < code.length; i++) {
      if (int.parse(code[i]) != int.parse(code[i - 1]) + 1) {
        isAscending = false;
        break;
      }
    }
    
    // Check descending sequence (e.g., 654321, 543210)
    bool isDescending = true;
    for (int i = 1; i < code.length; i++) {
      if (int.parse(code[i]) != int.parse(code[i - 1]) - 1) {
        isDescending = false;
        break;
      }
    }
    
    return isAscending || isDescending;
  }

  /// Validates if two codes match
  static bool codesMatch(String code1, String code2) {
    return code1 == code2 && code1.isNotEmpty && code2.isNotEmpty;
  }

  /// Validates if the code is valid (contains only digits and has minimum length)
  static bool isValid(String code, int minLength) {
    return hasOnlyDigits(code) && hasMinimumLength(code, minLength);
  }
}
