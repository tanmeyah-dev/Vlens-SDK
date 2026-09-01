import 'package:core/components/button/app_button.dart';
import 'package:core/style/app_colors.dart';
import 'package:core/utils/ui.dart';
import 'package:flutter/material.dart';

/// Package name from [pubspec.yaml]; required for asset resolution from host apps.
const String _tanSdkPackageName = 'tan_sdk';

/// Full-screen success state after e-contract OTP validation.
class EContractSuccessDialog extends StatelessWidget {
  final VoidCallback? onDismiss;

  const EContractSuccessDialog({
    super.key,
    this.onDismiss,
  });

  void _onContinuePressed() {
    onDismiss?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.white,
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 18),
            child: AppButton(
              title: 'حسناً',
              backgroundColor: AppColors.blue,
              onPressed: _onContinuePressed,
            ),
          ),
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 22),
                            child: Container(
                              width: double.infinity,
                              alignment: Alignment.center,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    AppAssets.waittingImg,
                                    package: _tanSdkPackageName,
                                    width: 360,
                                    height: 320,
                                    fit: BoxFit.contain,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'حسناً..!',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFF2E2B77),
                                      fontSize: 24,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 60),
                          child: Text(
                            'لقد تم ارسال عقدك بنجاح.\n'
                            'كما انه تم ارسال نسخة من العقد على الايميل الخاص بك',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
