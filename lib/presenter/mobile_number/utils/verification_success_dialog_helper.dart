import 'package:flutter/material.dart';
import '../widget/verification_success_dialog.dart';

class VerificationSuccessDialogHelper {
  static void showVerificationSuccessDialog(
    BuildContext context, {
    VoidCallback? onDismiss,
  }) {
    // Store the original context for navigation
    final navigationContext = context;
    
    showGeneralDialog(
      context: context,
      useRootNavigator: false,
      barrierDismissible: true,
      barrierLabel: "إغلاق",
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return VerificationSuccessDialog(
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
