import 'package:flutter/material.dart';

/// App-wide color constants for consistent theming.
/// 
/// This class provides reusable color definitions used throughout the SDK.
class AppColors {
  AppColors._(); // Private constructor to prevent instantiation

  // Primary Colors
  static const Color primary = Color(0xFFB71C1C); // Red 900
  static const Color primaryLight = Color(0xFFE53935); // Red 600
  static const Color primaryDark = Color(0xFF8E0000); // Red 900 darker

  // Red shades (most commonly used)
  static const Color red = Color(0xFFD32F2F); // Red 700
  static const Color redLight = Color(0xFFEF5350); // Red 400
  static const Color redDark = Color(0xFFB71C1C); // Red 900

  // Condition Item Icon Colors
  static const Color green = Color(0xFF4CAF50); // Green 500
  static const Color blue = Color(0xFF2196F3); // Blue 500
  static const Color orange = Color(0xFFFF9800); // Orange 500
  static const Color purple = Color(0xFF9C27B0); // Purple 500

  // Background Colors
  static const Color background = Color(0xFFFFFFFF); // White
  static const Color backgroundLight = Color(0xFFF5F5F5); // Grey 100
  static const Color backgroundDark = Color(0xFFEEEEEE); // Grey 200

  // Text Colors
  static const Color textPrimary = Color(0xFF212121); // Grey 900
  static const Color textSecondary = Color(0xFF757575); // Grey 600
  static const Color textDisabled = Color(0xFFBDBDBD); // Grey 400
  static const Color textWhite = Color(0xFFFFFFFF); // White
  
  // Common aliases for convenience
  static const Color white = Color(0xFFFFFFFF);
  static const Color gray = Color(0xFF9E9E9E); // Grey 500
  static const Color secondary = textSecondary;
  static const Color hintGray = Color(0xFFBDBDBD); // Grey 400
  static const Color border1 = border;
  static const Color black = textPrimary;
  static const Color navy = Color(0xFF1976D2); // Blue 700
  static const Color lightBackBlue = Color(0xFFE3F2FD); // Light Blue 50
  static const Color hide = Color(0x00000000); // Transparent

  // Border and Divider Colors
  static const Color border = Color(0xFFE0E0E0); // Grey 300
  static const Color divider = Color(0xFFBDBDBD); // Grey 400

  // Status Colors
  static const Color success = Color(0xFF4CAF50); // Green 500
  static const Color warning = Color(0xFFFF9800); // Orange 500
  static const Color error = Color(0xFFD32F2F); // Red 700
  static const Color info = Color(0xFF2196F3); // Blue 500

  // Button Colors
  static const Color buttonPrimary = Color(0xFFD32F2F); // Red 700
  static const Color buttonPrimaryDisabled = Color(0xFFE0E0E0); // Grey 300
  static const Color buttonTextPrimary = Color(0xFFFFFFFF); // White
  static const Color buttonTextDisabled = Color(0xFF9E9E9E); // Grey 500

  // Card and Surface Colors
  static const Color cardBackground = Color(0xFFFFFFFF); // White
  static const Color cardShadow = Color(0x1A000000); // Black with 10% opacity

  // Checkbox Colors
  static const Color checkboxActive = Color(0xFFD32F2F); // Red 700
  static const Color checkboxCheck = Color(0xFFFFFFFF); // White
  static const Color checkboxInactive = Color(0xFFE0E0E0); // Grey 300

  // Icon Background Colors (with opacity)
  static Color get greenIconBackground => green.withOpacity(0.1);
  static Color get blueIconBackground => blue.withOpacity(0.1);
  static Color get orangeIconBackground => orange.withOpacity(0.1);
  static Color get purpleIconBackground => purple.withOpacity(0.1);
  static Color get redIconBackground => red.withOpacity(0.1);

  // Shadow Colors
  static Color get shadowLight => Colors.grey.withOpacity(0.1);
  static Color get shadowMedium => Colors.grey.withOpacity(0.2);
  static Color get shadowDark => Colors.grey.withOpacity(0.3);
}



