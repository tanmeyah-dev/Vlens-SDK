import 'package:flutter/material.dart';

class MobileNumberModel {
  final TextEditingController mobileNumberController = TextEditingController();
  var formKey = GlobalKey<FormState>();
  var isSaveButtonDisabled = true;
  var isLoading = false;

  bool isInputEmpty() {
    return mobileNumberController.text.isEmpty;
  }
}
