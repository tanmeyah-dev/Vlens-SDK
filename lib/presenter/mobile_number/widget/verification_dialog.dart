import 'package:core/components/button/app_button.dart';
import 'package:core/components/text/app_text.dart';
import 'package:core/extensions/widget_extension.dart';
import 'package:core/utils/ui.dart';
import 'package:core/style/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:pinput/pinput.dart';
import 'dart:async';
import '../../../../routes/route_path.dart';
import '../utils/verification_success_dialog_helper.dart';

class VerificationDialog extends StatefulWidget {
  final String lastTwoDigits;
  final Function(String) onConfirm;
  final BuildContext? parentContext;

  const VerificationDialog({
    super.key,
    required this.lastTwoDigits,
    required this.onConfirm,
    this.parentContext,
  });

  @override
  State<VerificationDialog> createState() => _VerificationDialogState();
}

class _VerificationDialogState extends State<VerificationDialog> {
  int countdown = 30;
  bool canResend = false;
  Timer? countdownTimer;
  final TextEditingController pinController = TextEditingController();
  final FocusNode pinFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Start countdown timer
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        if (countdown > 0) {
          setState(() {
            countdown--;
          });
        } else {
          timer.cancel();
          setState(() {
            canResend = true;
          });
        }
      }
    });

    // Listen to PIN changes
    pinController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    pinController.dispose();
    pinFocusNode.dispose();
    super.dispose();
  }

  void _resendCode() {
    setState(() {
      countdown = 10;
      canResend = false;
    });
    countdownTimer?.cancel();
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        if (countdown > 0) {
          setState(() {
            countdown--;
          });
        } else {
          timer.cancel();
          setState(() {
            canResend = true;
          });
        }
      }
    });
    // TODO: Implement resend code logic
  }

  @override
  Widget build(BuildContext context) {
    final isPinComplete = pinController.text.length == 5;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 471,
            height: 398,
            margin: const EdgeInsets.only(
              bottom: 20,
              left: 14,
              right: 14,
            ),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Title
                  AppText(
                    "تأكيد رقم الموبايل",
                    color: AppColors.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  16.height,
                  // Instructions
                  AppText(
                    "برجاء إدخال الكود المكون من ٥ ارقام الذي تم ارساله إلي هاتفك المحمول **${widget.lastTwoDigits}",
                    color: AppColors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    textAlign: TextAlign.center,
                  ),
                  24.height,
                  // PIN Input
                  Pinput(
                    length: 5,
                    controller: pinController,
                    focusNode: pinFocusNode,
                    keyboardType: TextInputType.number,
                    defaultPinTheme: PinTheme(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        border: Border.all(
                          color: AppColors.border1,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: TextStyle(
                        color: AppColors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    focusedPinTheme: PinTheme(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        border: Border.all(
                          color: AppColors.primary,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: TextStyle(
                        color: AppColors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onCompleted: (pin) {
                      // Close verification dialog first
                      Navigator.of(context).pop();
                      // Use parent context or current context for showing success dialog
                      final successContext = widget.parentContext ?? context;
                      // Use a post-frame callback to ensure context is valid
                      SchedulerBinding.instance.addPostFrameCallback((_) {
                        if (successContext.mounted) {
                          VerificationSuccessDialogHelper.showVerificationSuccessDialog(
                            successContext,
                            onDismiss: () {
                              // Navigate to username security code screen
                              if (successContext.mounted) {
                                Navigator.of(successContext).pushNamed(RoutePath.usernameSecurityCode);
                              }
                              widget.onConfirm(pin); // Call the original callback
                            },
                          );
                        }
                      });
                    },
                  ),
                  24.height,
                  // Resend option
                  GestureDetector(
                    onTap: canResend ? _resendCode : null,
                    child: AppText(
                      canResend
                          ? "إرسال مرة أخرى"
                          : "إرسال مرة أخرى بعد $countdown ثواني",
                      color: canResend ? AppColors.primary : AppColors.gray,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  70.height,
                  // Confirm button
                  AppButton(
                    title: "تأكيد",
                    textColor: isPinComplete ? AppColors.white : AppColors.gray,
                    onPressed: isPinComplete
                        ? () {
                            // Close verification dialog first
                            Navigator.of(context).pop();
                            // Use parent context or current context for showing success dialog
                            final successContext = widget.parentContext ?? context;
                            // Use a post-frame callback to ensure context is valid
                            SchedulerBinding.instance.addPostFrameCallback((_) {
                              if (successContext.mounted) {
                                VerificationSuccessDialogHelper.showVerificationSuccessDialog(
                                  successContext,
                                  onDismiss: () {
                                    // Navigate to username security code screen
                                    if (successContext.mounted) {
                                      Navigator.of(successContext).pushNamed(RoutePath.usernameSecurityCode);
                                    }
                                    widget.onConfirm(pinController.text); // Call the original callback
                                  },
                                );
                              }
                            });
                          }
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
