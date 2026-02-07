import 'package:flutter/material.dart';
import '../widget/email_verification_dialog.dart';

class EmailVerificationDialogHelper {
  static void showEmailVerificationDialog(
    BuildContext context,
    String email, {
    String? emailOtpRequestId,
    String? transactionId,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      // Use MediaQuery to ensure dialog respects keyboard insets
      useRootNavigator: false,
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return MediaQuery.removePadding(
          context: dialogContext,
          removeTop: false,
          removeBottom: false,
          child: EmailVerificationDialog(
            email: email,
            emailOtpRequestId: emailOtpRequestId,
            transactionId: transactionId,
            parentContext: context, // Pass original context for navigation
            onConfirm: (pin) {
              // This callback will be called after success
              // The navigation is handled in the dialog itself
            },
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
