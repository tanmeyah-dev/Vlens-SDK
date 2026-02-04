import 'package:flutter/material.dart';
import 'package:country_code_picker/country_code_picker.dart';

class MobileNumberModel {
  final TextEditingController mobileNumberController = TextEditingController();
  var formKey = GlobalKey<FormState>();
  var isSaveButtonDisabled = true;
  CountryCode selectedCountryCode = CountryCode.fromDialCode("+20");

  bool isInputEmpty() {
    return mobileNumberController.text.isEmpty;
  }
}
