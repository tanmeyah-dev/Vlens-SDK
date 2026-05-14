class UsernameValidator {
  static const int minLength = 3;

  /// Validates if username contains only Arabic characters (no spaces)
  static bool hasOnlyArabic(String username) {
    return RegExp(r'^[\u0600-\u06FF]+$').hasMatch(username);
  }

  /// Validates if username has minimum length
  static bool hasMinimumLength(String username) {
    return username.length > minLength;
  }

  /// Validates if username has no spaces
  static bool hasNoSpaces(String username) {
    return !username.contains(' ');
  }

  /// Validates if username is valid
  static bool isValid(String username) {
    return hasOnlyArabic(username) && 
           hasMinimumLength(username) && 
           hasNoSpaces(username);
  }

  /// Gets validation error message for username
  static String? getValidationError(String? username) {
    if (username == null || username.isEmpty) {
      return "اسم المستخدم";
    }
    
    if (!hasOnlyArabic(username)) {
      return "يجب أن يحتوي على أحرف عربية فقط";
    }
    
    if (!hasMinimumLength(username)) {
      return "يجب أن يكون أكثر من 3 أحرف";
    }
    
    if (!hasNoSpaces(username)) {
      return "لا يمكن استخدام المسافات";
    }
    
    return null;
  }
}
