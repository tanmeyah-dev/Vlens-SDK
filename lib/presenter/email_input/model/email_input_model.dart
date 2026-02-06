import 'package:flutter/material.dart';

class EmailInputModel {
  final TextEditingController emailController = TextEditingController();
  var formKey = GlobalKey<FormState>();
  var isSaveButtonDisabled = true;
  var isLoading = false;

  bool isInputEmpty() {
    return emailController.text.isEmpty;
  }
}
