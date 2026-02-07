import 'package:core/components/text/app_text.dart';
import 'package:core/extensions/widget_extension.dart';
import 'package:core/utils/ui.dart';
import 'package:core/style/app_colors.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import '../../email_input/scene/email_input_scene.dart';

class VerificationSuccessDialog extends StatefulWidget {
  final VoidCallback? onDismiss;
  final BuildContext? navigationContext;

  const VerificationSuccessDialog({
    super.key,
    this.onDismiss,
    this.navigationContext,
  });

  @override
  State<VerificationSuccessDialog> createState() => _VerificationSuccessDialogState();
}

class _VerificationSuccessDialogState extends State<VerificationSuccessDialog> {
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    // Auto-dismiss after 2 seconds
    _autoDismissTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pop(); // Close success dialog
        // Use a small delay to ensure dialog is fully closed before navigation
        Future.delayed(const Duration(milliseconds: 300), () {
          // Navigate to email input screen
          final navContext = widget.navigationContext ?? context;
          if (navContext.mounted) {
            print('🧭 Navigating to email input screen...');
            Navigator.of(navContext).push(
              MaterialPageRoute(builder: (_) => const EmailInputScene()),
            );
            print('✅ Navigation completed');
          } else {
            print('⚠️ Navigation context not mounted');
          }
          widget.onDismiss?.call(); // Call the callback if provided
        });
      }
    });
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    super.dispose();
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
            width: 398,
            height: 341,
            margin: const EdgeInsets.only(
              bottom: 20,
              left: 14,
              right: 14,
            ),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary,
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Success icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.green.shade400,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check,
                        color: AppColors.white,
                        size: 36,
                      ),
                    ),
                  ),
                ),
                24.height,
                // Primary message
                AppText(
                  "حسناً..!",
                  color: Colors.green.shade600,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                8.height,
                // Secondary message
                AppText(
                  "لقد تمت عملية التحقق بنجاح",
                  color: AppColors.gray,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
