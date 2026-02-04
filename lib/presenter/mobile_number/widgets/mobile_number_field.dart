import 'package:core/components/text/app_text.dart';
import 'package:core/extensions/widget_extension.dart';
import 'package:core/utils/ui.dart';
import 'package:core/style/app_colors.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/mobile_number_constants.dart';
import '../utils/phone_validator.dart';
import 'country_code_display.dart';

class MobileNumberField extends StatefulWidget {
  final TextEditingController controller;
  final CountryCode selectedCountryCode;
  final Function(String) onChanged;
  final FormFieldValidator<String>? validator;

  const MobileNumberField({
    super.key,
    required this.controller,
    required this.selectedCountryCode,
    required this.onChanged,
    this.validator,
  });

  @override
  State<MobileNumberField> createState() => _MobileNumberFieldState();
}

class _MobileNumberFieldState extends State<MobileNumberField> {
  String _previousMobileNumber = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label above the input fields
        AppText(
          "رقم الموبايل",
          color: AppColors.secondary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        8.height,
        Row(
          textDirection: TextDirection.rtl,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mobile number field (appears on left in RTL)
            Expanded(
              child: TextFormField(
                controller: widget.controller,
                keyboardType: TextInputType.phone,
                maxLength: 11,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                style: TextStyle(
                  color: AppColors.black,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: MobileNumberConstants.mobileNumberHint,
                  hintStyle: TextStyle(
                    color: AppColors.hintGray,
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: AppColors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: AppColors.border1,
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: AppColors.border1,
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: AppColors.primary,
                      width: 1,
                    ),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: AppColors.border1,
                      width: 1,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: AppColors.error,
                      width: 1,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: AppColors.error,
                      width: 1,
                    ),
                  ),
                  errorStyle: const TextStyle(
                    color: AppColors.error,
                    fontSize: 12,
                    height: 1.2,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 15,
                  ),
                  counterText: "",
                ),
                validator: widget.validator ??
                    (value) => PhoneValidator.validate(widget.controller.text),
                onChanged: (value) {
                  _handlePhoneNumberChange(value);
                },
              ),
            ),
            8.width,
            // Country code display widget
            CountryCodeDisplay(
              selectedCountryCode: widget.selectedCountryCode,
            ),
          ],
        ),
      ],
    );
  }

  void _handlePhoneNumberChange(String value) {
    final controller = widget.controller;
    final currentText = controller.text;

    // If text is empty, don't do anything
    if (currentText.isEmpty) {
      _previousMobileNumber = '';
      widget.onChanged(value);
      return;
    }

    // Check if user tried to add "0" at the beginning when there's already "0"
    if (_previousMobileNumber.startsWith('0') && value.startsWith('00')) {
      // Ignore the duplicate "0" - revert to previous text
      final cursorPosition = controller.selection.baseOffset > 0
          ? controller.selection.baseOffset - 1
          : 0;
      controller.value = TextEditingValue(
        text: _previousMobileNumber,
        selection: TextSelection.collapsed(offset: cursorPosition),
      );
      widget.onChanged(_previousMobileNumber);
      return;
    }

    // If text doesn't start with "0" and is not empty, add "0" at the beginning
    if (!currentText.startsWith('0') && currentText.isNotEmpty) {
      final newText = '0$currentText';
      final cursorPosition = controller.selection.baseOffset + 1;
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: cursorPosition),
      );
      _previousMobileNumber = newText;
      widget.onChanged(newText);
    } else {
      _previousMobileNumber = currentText;
      widget.onChanged(currentText);
    }
  }
}
