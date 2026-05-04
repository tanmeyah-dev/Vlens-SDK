import 'package:flutter/material.dart';

class LoginScreenModel {
  final TextEditingController mobileNumberController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FocusNode passwordFocusNode = FocusNode();
  var formKey = GlobalKey<FormState>();
  var isLoginButtonDisabled = true;
  bool isBiometricAvailable = false;
  String? phoneNumberError;
  String? passwordError;
  bool isLoading = false;

  /// While true, [LoginEvent] is ignored — avoids a second `/login` when OTP flow
  /// is active or a duplicate event was queued after the first login returned.
  bool awaitingOtpVerification = false;

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
    return true;
  }

  bool areFieldsValid() {
    return isPhoneNumberValid() && isPasswordValid();
  }
}
