import 'package:flutter/material.dart';
import 'package:core/components/image/app_image.dart';
import 'package:core/utils/ui.dart';
import 'package:core/style/app_colors.dart';
import '../../../routes/route_path.dart';

class SplashScene extends StatefulWidget {
  /// Optional phone from the host app to prefill on validate-user.
  final String? phoneNumber;

  const SplashScene({super.key, this.phoneNumber});

  @override
  State<SplashScene> createState() => _SplashSceneState();
}

class _SplashSceneState extends State<SplashScene> {
  @override
  void initState() {
    super.initState();
    // Navigate to validate user after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        final phone = widget.phoneNumber?.trim();
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
