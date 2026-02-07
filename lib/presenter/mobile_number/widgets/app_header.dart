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
    // Responsive padding and sizes
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth > 600 ? 24.0 : 16.0;
    final verticalPadding = screenWidth > 600 ? 20.0 : 16.0;
    final logoHeight = screenWidth > 600 ? 70.0 : 60.0;
    final iconSize = screenWidth > 600 ? 28.0 : 24.0;
    
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Centered logo
          Center(
            child: AppImage(
              AppAssets.tanmeyah,
              height: logoHeight,
            ),
          ),
          // Arrow on the right side
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: onBackPressed ?? () => Navigator.of(context).pop(),
              child: Icon(
                Icons.arrow_back_ios_new,
                size: iconSize,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
