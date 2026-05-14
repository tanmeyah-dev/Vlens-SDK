import 'package:flutter/material.dart';

class PhoneValidator {
  /// Validates Egyptian phone number format
  /// Pattern: (0?1)[0125][0-9]{8}
  /// Valid formats: 01012345678, 1012345678, 01123456789, 1512345678
  static String? validatePhone(BuildContext context, String? phone) {
    var phoneRegExp = RegExp(r'^(0?1)[0125][0-9]{8}$');
    var textIsArabic = RegExp(r'^[\0621-\064A0-9 ]+$');
    
    if (phone == null || phone.trim().isEmpty) {
      return 'رقم الموبايل مطلوب'; // phone_field_is_required.tr
    } else if (!textIsArabic.hasMatch(phone)) {
      return "الرقم غير صحيح"; // number_wrong.tr
    } else if (!phoneRegExp.hasMatch(phone)) {
      return "رقم الموبايل غير صحيح"; // phone_error.tr
    }
    return null;
  }
  
  /// Legacy method for backward compatibility
  static String? validate(BuildContext context, String? phone) {
    return validatePhone(context, phone);
  }
}
