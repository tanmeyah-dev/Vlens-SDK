import 'package:core/components/text/app_text.dart';
import 'package:core/extensions/widget_extension.dart';
import 'package:core/utils/ui.dart';
import 'package:core/style/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';

class PinInputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final int length;
  final bool obscureText;
  final VoidCallback? onChanged;
  final VoidCallback? onCompleted;

  const PinInputField({
    super.key,
    required this.label,
    required this.controller,
    this.focusNode,
    this.length = 6,
    this.obscureText = true,
    this.onChanged,
    this.onCompleted,
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
          child: Pinput(
            obscureText: obscureText,
            length: length,
            controller: controller,
            focusNode: focusNode,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            defaultPinTheme: PinTheme(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border.all(
                  color: AppColors.border1,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: TextStyle(
                color: AppColors.black,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            focusedPinTheme: PinTheme(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border.all(
                  color: AppColors.primary,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: TextStyle(
                color: AppColors.black,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            onChanged: (_) => onChanged?.call(),
            onCompleted: (_) => onCompleted?.call(),
          ),
        ),
      ],
    );
  }
}
