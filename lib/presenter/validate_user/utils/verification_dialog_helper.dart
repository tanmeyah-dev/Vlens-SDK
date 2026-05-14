import 'package:flutter/material.dart';
import '../widget/verification_dialog.dart';

class VerificationDialogHelper {
  static void showVerificationDialog(
    BuildContext context,
    String lastTwoDigits, {
    String? mobileNumber,
    String? phoneNumberOtpRequestId,
    String? transactionId,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      // Use MediaQuery to ensure dialog respects keyboard insets
      useRootNavigator: false,
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return MediaQuery.removePadding(
          context: dialogContext,
          removeTop: false,
          removeBottom: false,
          child: PhoneVerificationDialog(
            lastTwoDigits: lastTwoDigits,
            mobileNumber: mobileNumber,
            phoneNumberOtpRequestId: phoneNumberOtpRequestId,
            transactionId: transactionId,
            parentContext: context, // Pass original context for navigation
            onConfirm: (pin) {
              // This callback will be called after success dialog dismisses
              // The navigation is handled in the success dialog's onDismiss
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
