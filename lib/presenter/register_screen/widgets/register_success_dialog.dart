import 'dart:async';

import 'package:core/components/text/app_text.dart';
import 'package:core/extensions/widget_extension.dart';
import 'package:core/style/app_colors.dart';
import 'package:flutter/material.dart';

import '../../../routes/route_path.dart';
import '../../login_screen/model/login_screen_nav_args.dart';

class RegisterSuccessDialog extends StatefulWidget {
  final String? phoneNumber;
  final BuildContext? navigationContext;
  final VoidCallback? onDismiss;

  const RegisterSuccessDialog({
    super.key,
    this.phoneNumber,
    this.navigationContext,
    this.onDismiss,
  });

  @override
  State<RegisterSuccessDialog> createState() => _RegisterSuccessDialogState();
}

class _RegisterSuccessDialogState extends State<RegisterSuccessDialog> {
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    _autoDismissTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.of(context).pop();
      Future.delayed(const Duration(milliseconds: 100), () {
        final navContext = widget.navigationContext ?? context;
        if (!navContext.mounted) return;
        final phone = widget.phoneNumber?.trim();
        Navigator.of(navContext).pushNamedAndRemoveUntil(
          RoutePath.loginScreen,
          (route) => false,
          arguments: LoginScreenNavArgs(
            phoneNumber: (phone != null && phone.isNotEmpty) ? phone : null,
          ),
        );
        widget.onDismiss?.call();
      });
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
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          width: double.infinity,
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
                    child: const Icon(
                      Icons.check,
                      color: AppColors.white,
                      size: 36,
                    ),
                  ),
                ),
              ),
              24.height,
              AppText(
                'حسناً..!',
                color: Colors.green.shade600,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              8.height,
              AppText(
                'لقد قمت بإنشاء\nاسم مستخدم ورمز حماية بنجاح',
                color: AppColors.gray,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
