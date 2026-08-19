import 'package:flutter/material.dart';

/// Navigator key for the SDK's internal [Navigator] in [TanSdkEntry].
class SdkNavigator {
  static final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();

  /// Host-app route to land on when the SDK flow finishes.
  static const String hostMainRouteName = '/mainScreen';

  /// Optional host callback. When set, [returnToHostApp] invokes it instead of
  /// pushing [hostMainRouteName] on the root navigator.
  static VoidCallback? onCompleted;

  /// Leaves the SDK and returns to the host app's main screen.
  static void returnToHostApp(BuildContext context) {
    final completed = onCompleted;
    if (completed != null) {
      completed();
      return;
    }
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
      hostMainRouteName,
      (route) => false,
    );
  }
}
