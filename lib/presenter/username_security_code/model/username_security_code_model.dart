import 'package:flutter/material.dart';
import '../constants/security_code_constants.dart';
import '../utils/security_code_validator.dart';

class UsernameSecurityCodeModel {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController createSecurityCodeController = TextEditingController();
  final TextEditingController confirmSecurityCodeController = TextEditingController();
  final FocusNode createSecurityCodeFocusNode = FocusNode();
  final FocusNode confirmSecurityCodeFocusNode = FocusNode();
  var formKey = GlobalKey<FormState>();
  var isSaveButtonDisabled = true;

  bool isInputEmpty() {
    return usernameController.text.isEmpty ||
        createSecurityCodeController.text.isEmpty ||
        confirmSecurityCodeController.text.isEmpty;
  }

  bool isSecurityCodeValid() {
    final code = createSecurityCodeController.text;
    return SecurityCodeValidator.isValid(code, SecurityCodeConstants.pinLength);
  }

  bool isConfirmSecurityCodeValid() {
    final code = confirmSecurityCodeController.text;
    // Confirm code just needs to match the create code, not validate all requirements
    return code.isNotEmpty && SecurityCodeValidator.codesMatch(createSecurityCodeController.text, code);
  }

  bool doSecurityCodesMatch() {
    final createCode = createSecurityCodeController.text;
    final confirmCode = confirmSecurityCodeController.text;
    return SecurityCodeValidator.codesMatch(createCode, confirmCode);
  }

  bool isUsernameValid() {
    final value = usernameController.text.trim();
    return value.isNotEmpty && !value.contains(' ');
  }

  bool isFormValid() {
    return isUsernameValid() &&
           isSecurityCodeValid() &&
           isConfirmSecurityCodeValid() &&
           doSecurityCodesMatch();
  }
}
