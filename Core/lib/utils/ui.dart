/// UI utilities and constants
library ui;

/// Asset paths for images and other resources
class AppAssets {
  /// Tanmeyah logo asset path
  static const String tanmeyah = 'packages/tan_sdk/assets/images/logo.png';
  /// Fingerprint white icon asset path (placeholder - file may need to be added)
  static const String fingerPrintWhite = 'packages/tan_sdk/assets/images/fingerprint_white.png';
  /// Request submitted success illustration.
  /// Referenced with `package: tan_sdk` in Image.asset / AssetImage.
  static const String requestSubmitted = 'assets/images/request_submitted_white.png';

  /// Location permission gate illustration (host apps resolve via `package: tan_sdk`).
  static const String locationPermission = 'assets/images/location_permission.png';
}
