import 'package:flutter/material.dart';
import '../widget/verification_dialog.dart';

class VerificationDialogHelper {
  static void showVerificationDialog(
    BuildContext context,
    String lastTwoDigits,
  ) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return VerificationDialog(
          lastTwoDigits: lastTwoDigits,
          parentContext: context, // Pass original context for navigation
          onConfirm: (pin) {
            // This callback will be called after success dialog dismisses
            // The navigation is handled in the success dialog's onDismiss
          },
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
