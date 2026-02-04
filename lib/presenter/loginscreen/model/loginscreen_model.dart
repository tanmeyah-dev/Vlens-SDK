import 'package:flutter/material.dart';

class LoginScreenModel {
  final TextEditingController mobileNumberController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  var formKey = GlobalKey<FormState>();
  var isLoginButtonDisabled = true;
  bool passwordVisible = true;
  bool isBiometricAvailable = false;
  String? phoneNumberError;
  String? passwordError;

  bool isInputEmpty() {
    return mobileNumberController.text.isEmpty ||
        passwordController.text.isEmpty;
  }

  bool isPhoneNumberValid() {
    final phone = mobileNumberController.text.trim();
    if (phone.isEmpty) return false;
    // Use the same validation pattern as PhoneValidator
    var phoneRegExp = RegExp(r'^(0?1)[0125][0-9]{8}$');
    var textIsArabic = RegExp(r'^[\0621-\064A0-9 ]+$');
    if (!textIsArabic.hasMatch(phone)) return false;
    if (!phoneRegExp.hasMatch(phone)) return false;
    return true;
  }

  bool isPasswordValid() {
    final password = passwordController.text.trim();
    if (password.isEmpty) return false;
    if (!RegExp(r'^\d+$').hasMatch(password)) return false;
    if (password.length != 6) return false;
    return true;
  }

  bool areFieldsValid() {
    return isPhoneNumberValid() && isPasswordValid();
  }
}
