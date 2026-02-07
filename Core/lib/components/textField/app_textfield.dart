import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../text/app_text.dart';
import '../../style/app_colors.dart';

/// A reusable text field widget with consistent styling
class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final int? maxLength;
  final bool enabled;
  final TextDirection? textDirection;
  final TextAlign? textAlign;

  final Widget? endSuffix;
  final VoidCallback? onSuffixTap;

  const AppTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.obscureText = false,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.maxLength,
    this.enabled = true,
    this.textDirection,
    this.textAlign,
    this.endSuffix,
    this.onSuffixTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelText != null) ...[
          AppText(
            labelText!,
            color: AppColors.secondary,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onChanged: onChanged,
          maxLength: maxLength,
          enabled: enabled,
          textDirection: textDirection,
          textAlign: textAlign ?? TextAlign.start,
          style: const TextStyle(
            color: AppColors.black,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: AppColors.hintGray,
              fontSize: 14,
            ),
            filled: true,
            fillColor: AppColors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.border1,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.border1,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.border1,
                width: 1,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.error,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
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
            counterText: maxLength != null ? "" : null,
            suffixIcon: endSuffix != null
                ? GestureDetector(
                    onTap: onSuffixTap,
                    child: endSuffix,
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
