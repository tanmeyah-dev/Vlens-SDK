import 'package:core/components/image/app_image.dart';
import 'package:core/utils/ui.dart';
import 'package:core/style/app_colors.dart';
import 'package:flutter/material.dart';

class AppHeader extends StatelessWidget {
  final VoidCallback? onBackPressed;

  const AppHeader({
    super.key,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Centered logo
          Center(
            child: AppImage(
              AppAssets.tanmeyah,
              height: 60,
            ),
          ),
          // Arrow on the right side
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: onBackPressed ?? () => Navigator.of(context).pop(),
              child:Icon(Icons.arrow_back_ios_new, size: 24, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
