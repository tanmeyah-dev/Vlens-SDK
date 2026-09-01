import 'package:flutter/material.dart';
import 'package:core/components/image/app_image.dart';
import 'package:core/utils/ui.dart';
import 'package:core/style/app_colors.dart';
import '../../../routes/route_path.dart';
import '../../login_screen/model/login_screen_nav_args.dart';
import '../../login_screen/utils/request_documents_navigator.dart';

class SplashScene extends StatefulWidget {
  /// Optional phone from the host app to prefill on validate-user.
  final String? phoneNumber;

  /// Optional host-app VLens status. When `200`, splash opens login.
  final String? vlenseStatus;

  const SplashScene({super.key, this.phoneNumber, this.vlenseStatus});

  @override
  State<SplashScene> createState() => _SplashSceneState();
}

class _SplashSceneState extends State<SplashScene> {
  @override
  void initState() {
    super.initState();
    // Navigate to validate user after 2 seconds (login when vlenseStatus == 200).
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        final phone = widget.phoneNumber?.trim();
        if (RequestDocumentsNavigator.isStatus200(widget.vlenseStatus)) {
          Navigator.of(context).pushReplacementNamed(
            RoutePath.loginScreen,
            arguments: LoginScreenNavArgs(
              phoneNumber: (phone != null && phone.isNotEmpty) ? phone : null,
              vlenseStatus: widget.vlenseStatus,
            ),
          );
          return;
        }
        Navigator.of(context).pushReplacementNamed(
          RoutePath.validateUser,
          arguments: (phone != null && phone.isNotEmpty) ? phone : null,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: AppImage(
          AppAssets.tanmeyah,
          width: 200,
          height: 200,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
