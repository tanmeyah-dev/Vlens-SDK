import 'package:flutter/material.dart';

class EmailScreenModel {
  final TextEditingController emailController = TextEditingController();
  var formKey = GlobalKey<FormState>();
  var isSaveButtonDisabled = true;
  var isLoading = false;
  var isGoogleLoading = false;

  bool isInputEmpty() {
    return emailController.text.isEmpty;
  }
}
