import 'package:flutter/material.dart';
import '../widget/verify_user_otp_dialog.dart';

class VerifyUserOTPDialogHelper {
  static void showVerifyUserOTPDialog(
    BuildContext context, {
    String? phoneNumber,
    String? password,
    String? maskedPhoneNumber,
    String? phoneNumberOtpRequestId,
    String? transactionId,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      useRootNavigator: false,
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return MediaQuery.removePadding(
          context: dialogContext,
          removeTop: false,
          removeBottom: false,
          child: VerifyUserOTPDialog(
            phoneNumber: phoneNumber,
            password: password,
            maskedPhoneNumber: maskedPhoneNumber,
            phoneNumberOtpRequestId: phoneNumberOtpRequestId,
            transactionId: transactionId,
            parentContext: context,
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          )),
          child: child,
        );
      },
    );
  }
}
