import 'package:core/components/text/app_text.dart';
import 'package:core/extensions/widget_extension.dart';
import 'package:core/utils/ui.dart';
import 'package:core/style/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/validate_user_constants.dart';
import '../utils/phone_validator.dart';
import 'country_code_display.dart';

class ValidateUserPhoneField extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onChanged;
  final FormFieldValidator<String>? validator;
  final bool readOnly;

  const ValidateUserPhoneField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.validator,
    this.readOnly = false,
  });

  @override
  State<ValidateUserPhoneField> createState() => _ValidateUserPhoneFieldState();
}

class _ValidateUserPhoneFieldState extends State<ValidateUserPhoneField> {
  String _previousMobileNumber = '';

  @override
  void initState() {
    super.initState();
    final initial = widget.controller.text.trim();
    if (initial.isNotEmpty) {
      _previousMobileNumber = initial;
    }
  }

  void _setControllerTextSafely(String text, int desiredOffset) {
    final safeOffset = desiredOffset.clamp(0, text.length);
    widget.controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: safeOffset),
    );
  }

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
              child: SizedBox(
                height: 86,
                child: TextFormField(
                  controller: widget.controller,
                  readOnly: widget.readOnly,
                  showCursor: !widget.readOnly,
                  enableInteractiveSelection: !widget.readOnly,
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
                    hintText: ValidateUserConstants.mobileNumberHint,
                    hintStyle: TextStyle(
                      color: AppColors.hintGray,
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor:
                        widget.readOnly ? AppColors.border1.withOpacity(0.3) : AppColors.white,
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
                    errorStyle: TextStyle(
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
            ),
            8.width,
            // Static country code display widget
            const CountryCodeDisplay(),
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
      final desiredCursorPosition = controller.selection.baseOffset > 0
          ? controller.selection.baseOffset - 1
          : 0;
      _setControllerTextSafely(_previousMobileNumber, desiredCursorPosition);
      widget.onChanged(_previousMobileNumber);
      return;
    }

    // If text doesn't start with "0" and is not empty, add "0" at the beginning
    if (!currentText.startsWith('0') && currentText.isNotEmpty) {
      final newText = '0$currentText';
      final desiredCursorPosition = controller.selection.baseOffset + 1;
      _setControllerTextSafely(newText, desiredCursorPosition);
      _previousMobileNumber = newText;
      widget.onChanged(newText);
    } else {
      _previousMobileNumber = currentText;
      widget.onChanged(currentText);
    }
  }
}
