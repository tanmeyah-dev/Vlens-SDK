import 'package:core/components/text/app_text.dart';
import 'package:core/components/textField/app_textfield.dart';
import 'package:core/extensions/widget_extension.dart';
import 'package:core/utils/ui.dart';
import 'package:core/style/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PinInputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool obscureText;
  final FormFieldValidator<String>? validator;
  final VoidCallback? onChanged;
  final VoidCallback? onCompleted;
  final int? maxLength;
  final List<TextInputFormatter>? formatter;
  final TextInputType? keyboardType;
  final TextAlign textAlign;

  const PinInputField({
    super.key,
    required this.label,
    required this.controller,
    this.focusNode,
    this.obscureText = true,
    this.validator,
    this.onChanged,
    this.onCompleted,
    this.maxLength,
    this.formatter,
    this.keyboardType,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          label,
          color: AppColors.secondary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        8.height,
        SizedBox(
          width: double.infinity,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: AppTextField(
              hintText: label,
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType ?? TextInputType.visiblePassword,
              validator: validator,
              maxLength: maxLength,
              inputFormatters: formatter,
              textAlign: textAlign,
              onChanged: (_) => onChanged?.call(),
            ),
          ),
        ),
      ],
    );
  }
}
