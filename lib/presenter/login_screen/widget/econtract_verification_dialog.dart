import 'dart:async';

import 'package:core/components/button/app_button.dart';
import 'package:core/components/text/app_text.dart';
import 'package:core/extensions/widget_extension.dart';
import 'package:core/style/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';

class EContractVerificationDialog extends StatefulWidget {
  final String lastTwoDigits;
  final ValueChanged<String> onConfirm;

  const EContractVerificationDialog({
    super.key,
    required this.lastTwoDigits,
    required this.onConfirm,
  });

  @override
  State<EContractVerificationDialog> createState() =>
      _EContractVerificationDialogState();
}

class _EContractVerificationDialogState extends State<EContractVerificationDialog> {
  int countdown = 30;
  bool canResend = false;
  Timer? countdownTimer;
  final TextEditingController pinController = TextEditingController();
  final FocusNode pinFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
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
    });

    pinController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    pinController.dispose();
    pinFocusNode.dispose();
    super.dispose();
  }

  void _restartCountdown() {
    countdownTimer?.cancel();
    setState(() {
      countdown = 30;
      canResend = false;
      pinController.clear();
    });
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final isPinComplete = pinController.text.length == 6;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth > 600 ? 471.0 : screenWidth - 28;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: keyboardHeight + 20,
            left: 14,
            right: 14,
          ),
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: dialogWidth,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary, width: 1),
              ),
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Icon(
                            Icons.close,
                            color: AppColors.primary,
                            size: 22,
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: AppText(
                              'تأكيد التعاقد الإلكتروني',
                              color: AppColors.primary,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 22),
                      ],
                    ),
                    16.height,
                    AppText(
                      widget.lastTwoDigits.isNotEmpty
                          ? 'برجاء إدخال الكود المكون من ٦ ارقام الذي تم ارساله إلي هاتفك المحمول **${widget.lastTwoDigits}'
                          : 'برجاء إدخال الكود المكون من ٦ ارقام الذي تم ارساله إلي هاتفك المحمول',
                      color: AppColors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      textAlign: TextAlign.center,
                    ),
                    24.height,
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Pinput(
                        length: 6,
                        controller: pinController,
                        focusNode: pinFocusNode,
                        keyboardType: TextInputType.number,
                        defaultPinTheme: PinTheme(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            border: Border.all(color: AppColors.border1, width: 1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          textStyle: const TextStyle(
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
                            border: Border.all(color: AppColors.primary, width: 1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          textStyle: const TextStyle(
                            color: AppColors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onCompleted: (_) {
                          if (!isPinComplete) return;
                          widget.onConfirm(pinController.text);
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                    24.height,
                    GestureDetector(
                      onTap: canResend ? _restartCountdown : null,
                      child: AppText(
                        canResend
                            ? 'إرسال مرة أخرى'
                            : 'إرسال مرة أخرى بعد $countdown ثواني',
                        color: canResend ? AppColors.primary : AppColors.gray,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    70.height,
                    AppButton(
                      title: 'تأكيد',
                      textColor: isPinComplete ? AppColors.white : AppColors.gray,
                      onPressed: isPinComplete
                          ? () {
                              widget.onConfirm(pinController.text);
                              Navigator.of(context).pop();
                            }
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
