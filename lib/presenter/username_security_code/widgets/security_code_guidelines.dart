import 'package:core/components/text/app_text.dart';
import 'package:core/extensions/widget_extension.dart';
import 'package:core/utils/ui.dart';
import 'package:core/style/app_colors.dart';
import 'package:flutter/material.dart';
import '../utils/security_code_validator.dart';

class SecurityCodeGuidelines extends StatelessWidget {
  final String createCode;
  final String confirmCode;
  final int minLength;

  const SecurityCodeGuidelines({
    super.key,
    required this.createCode,
    required this.confirmCode,
    this.minLength = 6,
  });

  @override
  Widget build(BuildContext context) {
    // Check validation states
    final hasNonDigits = createCode.isNotEmpty && 
                        !SecurityCodeValidator.hasOnlyDigits(createCode);
    final isLessThanMinLength = createCode.isNotEmpty && 
                                !SecurityCodeValidator.hasMinimumLength(createCode, minLength);
    final isSequential = createCode.isNotEmpty && 
                        SecurityCodeValidator.isSequential(createCode);
    final doNotMatch = createCode.length == minLength && 
                      confirmCode.length == minLength && 
                      !SecurityCodeValidator.codesMatch(createCode, confirmCode);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightBackBlue,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.info_outline,
                  color: AppColors.white,
                  size: 16,
                ),
              ),
              8.width,
              Expanded(
                child: AppText(
                  "من الأفضل استخدام رمز حماية قوي",
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          16.height,
          _GuidelineItem(
            text: "يجب أن تحتوي على أرقام فقط",
            showError: hasNonDigits,
          ),
          8.height,
          _GuidelineItem(
            text: "يجب ألا يقل عن $minLength أرقام",
            showError: isLessThanMinLength,
          ),
          8.height,
          _GuidelineItem(
            text: "تجنب إدخال أرقام متسلسلة في رمز الحماية",
            showError: isSequential,
          ),
          8.height,
          _GuidelineItem(
            text: "تطابق رمز الحماية",
            showError: doNotMatch,
          ),
        ],
      ),
    );
  }
}

class _GuidelineItem extends StatelessWidget {
  final String text;
  final bool showError;

  const _GuidelineItem({
    required this.text,
    required this.showError,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 6),
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: showError ? AppColors.error : AppColors.gray,
            shape: BoxShape.circle,
          ),
        ),
        8.width,
        Expanded(
          child: AppText(
            text,
            color: showError ? AppColors.error : AppColors.gray,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
