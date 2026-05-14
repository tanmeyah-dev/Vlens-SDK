class SecurityCodeValidator {
  /// Validates if the code contains only digits
  static bool hasOnlyDigits(String code) {
    return RegExp(r'^\d+$').hasMatch(code);
  }

  /// Validates if the code length is at least the minimum length
  static bool hasMinimumLength(String code, int minLength) {
    return code.length >= minLength;
  }

  /// Validates if the code contains at least one uppercase letter
  static bool hasUppercaseLetter(String code) {
    return RegExp(r'[A-Z]').hasMatch(code);
  }

  /// Validates if the code contains at least one lowercase letter
  static bool hasLowercaseLetter(String code) {
    return RegExp(r'[a-z]').hasMatch(code);
  }

  /// Validates if the code contains at least one number
  static bool hasNumber(String code) {
    return RegExp(r'[0-9]').hasMatch(code);
  }

  /// Validates if the code contains at least one special character
  static bool hasSpecialCharacter(String code) {
    return RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(code);
  }

  /// Validates if the code contains sequential numbers (ascending or descending)
  static bool isSequential(String code) {
    if (code.length < 3) return false;
    
    // Extract only digits from the code
    final digits = code.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 3) return false;
    
    // Check ascending sequence (e.g., 123456, 234567)
    bool isAscending = true;
    for (int i = 1; i < digits.length; i++) {
      if (int.parse(digits[i]) != int.parse(digits[i - 1]) + 1) {
        isAscending = false;
        break;
      }
    }
    
    // Check descending sequence (e.g., 654321, 543210)
    bool isDescending = true;
    for (int i = 1; i < digits.length; i++) {
      if (int.parse(digits[i]) != int.parse(digits[i - 1]) - 1) {
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

  /// Validates if the password is valid according to requirements:
  /// - Minimum length of 6 characters
  /// - Contains at least one uppercase letter
  /// - Contains at least one lowercase letter
  /// - Contains at least one number
  /// - Contains at least one special character
  static bool isValid(String code, int minLength) {
    return hasMinimumLength(code, minLength) &&
           hasUppercaseLetter(code) &&
           hasLowercaseLetter(code) &&
           hasNumber(code) &&
           hasSpecialCharacter(code);
  }

  /// Gets validation error message for the password
  static String? getValidationError(String code, int minLength) {
    if (code.isEmpty) {
      return 'رمز الحماية مطلوب';
    }
    if (!hasMinimumLength(code, minLength)) {
      return 'يجب أن يكون رمز الحماية على الأقل $minLength أحرف';
    }
    if (!hasUppercaseLetter(code)) {
      return 'يجب أن يحتوي رمز الحماية على حرف كبير واحد على الأقل';
    }
    if (!hasLowercaseLetter(code)) {
      return 'يجب أن يحتوي رمز الحماية على حرف صغير واحد على الأقل';
    }
    if (!hasNumber(code)) {
      return 'يجب أن يحتوي رمز الحماية على رقم واحد على الأقل';
    }
    if (!hasSpecialCharacter(code)) {
      return 'يجب أن يحتوي رمز الحماية على رمز خاص واحد على الأقل (!@#\$%^&*...)';
    }
    return null;
  }
}
