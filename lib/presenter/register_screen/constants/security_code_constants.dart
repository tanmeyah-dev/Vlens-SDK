class SecurityCodeConstants {
  static const int pinLength = 6;
  static const int usernameMinLength = 3;
  
  // Validation messages
  static const String onlyDigitsMessage = "يجب أن تحتوي على أرقام فقط";
  static const String minLengthMessage = "يجب ألا يقل عن 6 أرقام";
  static const String sequentialMessage = "تجنب إدخال أرقام متسلسلة في رمز الحماية";
  static const String matchMessage = "تطابق رمز الحماية";
  
  // Username validation messages
  static const String usernameRequired = "اسم المستخدم";
  static const String onlyArabicMessage = "يجب أن يحتوي على أحرف عربية فقط";
  static const String usernameMinLengthMessage = "يجب أن يكون أكثر من 3 أحرف";
  static const String noSpacesMessage = "لا يمكن استخدام المسافات";
}
