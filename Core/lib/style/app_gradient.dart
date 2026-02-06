import 'package:flutter/material.dart';
import 'app_colors.dart';

/// App gradient utilities
class AppGradient {
  final bool isHorizontal;

  AppGradient({this.isHorizontal = true});

  /// Primary gradient
  LinearGradient get primary {
    return LinearGradient(
      begin: isHorizontal ? Alignment.centerLeft : Alignment.topCenter,
      end: isHorizontal ? Alignment.centerRight : Alignment.bottomCenter,
      colors: const [
        AppColors.primary,
        AppColors.primaryLight,
      ],
    );
  }

  /// Returns the primary gradient
  LinearGradient call() => primary;
}
