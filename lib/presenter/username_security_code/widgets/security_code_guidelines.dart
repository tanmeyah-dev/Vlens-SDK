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
    final isLessThanMinLength = createCode.isNotEmpty && 
                                !SecurityCodeValidator.hasMinimumLength(createCode, minLength);
    final hasNoUppercase = createCode.isNotEmpty && 
                          !SecurityCodeValidator.hasUppercaseLetter(createCode);
    final hasNoLowercase = createCode.isNotEmpty && 
                          !SecurityCodeValidator.hasLowercaseLetter(createCode);
    final hasNoNumber = createCode.isNotEmpty && 
                       !SecurityCodeValidator.hasNumber(createCode);
    final hasNoSpecialChar = createCode.isNotEmpty && 
                            !SecurityCodeValidator.hasSpecialCharacter(createCode);
    final doNotMatch = createCode.isNotEmpty && 
                      confirmCode.isNotEmpty && 
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
            text: "يجب ألا يقل عن $minLength أحرف",
            showError: isLessThanMinLength,
          ),
          8.height,
          _GuidelineItem(
            text: "يجب أن يحتوي على حرف كبير واحد على الأقل (A-Z)",
            showError: hasNoUppercase,
          ),
          8.height,
          _GuidelineItem(
            text: "يجب أن يحتوي على حرف صغير واحد على الأقل (a-z)",
            showError: hasNoLowercase,
          ),
          8.height,
          _GuidelineItem(
            text: "يجب أن يحتوي على رقم واحد على الأقل (0-9)",
            showError: hasNoNumber,
          ),
          8.height,
          _GuidelineItem(
            text: "يجب أن يحتوي على رمز خاص واحد على الأقل (!@#\$%...)",
            showError: hasNoSpecialChar,
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
