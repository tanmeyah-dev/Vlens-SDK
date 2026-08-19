import 'dart:async';

import 'package:core/utils/cache/verification_cache.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../routes/route_path.dart';
import 'sdk_navigator.dart';

/// Forces the SDK flow back to login whenever an API returns HTTP 417.
class SessionExpiredRedirect {
  static bool _isHandling = false;

  static void handle(http.Response response) {
    if (response.statusCode != 417) return;
    if (_isHandling) return;
    _isHandling = true;
    unawaited(_redirectToLogin());
  }

  static Future<void> _redirectToLogin() async {
    try {
      final cache = VerificationCache();
      final mobile = await cache.getMobileNumber();
      await cache.clearLoginSession();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          final nav = SdkNavigator.key.currentState;
          if (nav == null || !nav.mounted) {
            _isHandling = false;
            return;
          }

          Route<dynamic>? topRoute;
          nav.popUntil((route) {
            topRoute = route;
            return true;
          });
          if (topRoute?.settings.name == RoutePath.loginScreen) {
            _isHandling = false;
            return;
          }

          nav.pushNamedAndRemoveUntil(
            RoutePath.loginScreen,
            (route) => false,
            arguments: (mobile != null && mobile.trim().isNotEmpty)
                ? mobile.trim()
                : null,
          );
        } finally {
          _isHandling = false;
        }
      });
    } catch (_) {
      _isHandling = false;
    }
  }
}
