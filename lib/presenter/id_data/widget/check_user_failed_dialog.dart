import 'package:core/components/text/app_text.dart';
import 'package:core/extensions/widget_extension.dart';
import 'package:core/style/app_colors.dart';
import 'package:flutter/material.dart';

import '../../../utils/sdk_navigator.dart';

class CheckUserFailedDialog extends StatelessWidget {
  final String message;
  final BuildContext navigationContext;

  const CheckUserFailedDialog({
    super.key,
    required this.message,
    required this.navigationContext,
  });

  static const _pinkCircle = Color(0xFFF8BBD0);
  static const _redClose = Color(0xFFE53935);

  void _goToCmaMainScreen(BuildContext dialogContext) {
    Navigator.of(dialogContext).pop();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!navigationContext.mounted) return;
      Navigator.of(navigationContext, rootNavigator: true)
          .pushNamedAndRemoveUntil(
        SdkNavigator.hostMainRouteName,
        (route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(
              bottom: 20,
              left: 14,
              right: 14,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: _pinkCircle,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(
                        color: _redClose,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: AppColors.white,
                        size: 36,
                      ),
                    ),
                  ),
                ),
                24.height,
                AppText(
                  'عذراً ..!',
                  color: _redClose,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                8.height,
                AppText(
                  'لم تتم عملية التحقق بنجاح',
                  color: AppColors.gray,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  textAlign: TextAlign.center,
                ),
                16.height,
                AppText(
                  message,
                  color: AppColors.navy,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  textAlign: TextAlign.center,
                ),
                24.height,
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _goToCmaMainScreen(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.textPrimary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const AppText(
                      'إعادة المحاولة',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
