import 'package:flutter/material.dart';

class EmailScreenModel {
  final TextEditingController emailController = TextEditingController();
  var formKey = GlobalKey<FormState>();
  var isSaveButtonDisabled = true;
  var isLoading = false;

  bool isInputEmpty() {
    return emailController.text.isEmpty;
  }
}
