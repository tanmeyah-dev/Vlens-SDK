import 'package:core/components/button/app_button.dart';
import 'package:core/style/app_colors.dart';
import 'package:core/utils/ui.dart';
import 'package:flutter/material.dart';

import '../utils/e_contract_otp_helper.dart';

/// Package name from [pubspec.yaml]; required for asset resolution from host apps.
const String _tanSdkPackageName = 'tan_sdk';

class RequestSubmittedScene extends StatefulWidget {
  final dynamic requestId;

  /// When true, e-contract OTP was already completed (e.g. after documents); [حسناً] only closes the flow.
  final bool eContractFlowCompleted;

  const RequestSubmittedScene({
    super.key,
    required this.requestId,
    this.eContractFlowCompleted = false,
  });

  @override
  State<RequestSubmittedScene> createState() => _RequestSubmittedSceneState();
}

class _RequestSubmittedSceneState extends State<RequestSubmittedScene> {
  Future<void> _onDonePressed(BuildContext context) async {
    if (widget.eContractFlowCompleted) {
      if (!context.mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    await EContractOtpHelper.run(
      context,
      widget.requestId,
      onVerifiedWithoutPayment: (ctx) {
        if (!ctx.mounted) return;
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(
            content: Text('تم تأكيد التعاقد الإلكتروني بنجاح'),
            backgroundColor: AppColors.primary,
          ),
        );
        Navigator.of(ctx).popUntil((route) => route.isFirst);
      },
    );
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
              onPressed: () => _onDonePressed(context),
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  const Text(
                    'طلب تمويل',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 36 / 2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 36),
                  Container(
                    color: AppColors.white,
                    child: Image.asset(
                      AppAssets.requestSubmitted,
                      package: _tanSdkPackageName,
                      width: 330,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 48),
                  const Text(
                    'تهانينا..!',
                    style: TextStyle(
                      color: Color(0xFF2E2B77),
                      fontSize: 34 / 2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'لقد تم انشاء عقدك بنجاح .. برجاء مراجعة البريد الالكتروني الخاص بك. ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 30 / 2,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
