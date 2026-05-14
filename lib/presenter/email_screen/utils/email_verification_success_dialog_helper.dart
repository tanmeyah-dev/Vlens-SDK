import 'package:flutter/material.dart';
import '../widget/email_verification_success_dialog.dart';

class EmailVerificationSuccessDialogHelper {
  static void showEmailVerificationSuccessDialog(
    BuildContext context, {
    VoidCallback? onDismiss,
  }) {
    // Store the original context for navigation
    final navigationContext = context;
    
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "إغلاق",
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return EmailVerificationSuccessDialog(
          onDismiss: onDismiss,
          navigationContext: navigationContext, // Use original context for navigation
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
