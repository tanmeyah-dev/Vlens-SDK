class PhoneValidator {
  static final RegExp _phoneRegExp = RegExp(r'^(0?1)[0125][0-9]{8}$');
  static final RegExp _textIsArabic = RegExp(r'^[\0621-\064A0-9 ]+$');

  /// Validates if phone number is empty
  static bool isEmpty(String? phone) {
    return phone == null || phone.trim().isEmpty;
  }

  /// Validates if phone contains only Arabic characters, numbers, and spaces
  static bool hasValidCharacters(String phone) {
    return _textIsArabic.hasMatch(phone);
  }

  /// Validates if phone matches Egyptian mobile number pattern
  static bool matchesPattern(String phone) {
    return _phoneRegExp.hasMatch(phone);
  }

  /// Validates phone number and returns error message if invalid
  static String? validate(String? phone) {
    if (isEmpty(phone)) {
      return "رقم الموبايل";
    } else if (!hasValidCharacters(phone!)) {
      return "رقم الهاتف غير صحيح";
    } else if (!matchesPattern(phone)) {
      return "رقم الهاتف غير صحيح";
    }
    return null;
  }
}
