import 'dart:async';

import 'package:core/utils/cache/verification_cache.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../routes/route_path.dart';
import 'api_response_envelope.dart';
import 'sdk_navigator.dart';

/// Forces the SDK flow back to login when an API returns HTTP 417 for session expiry.
///
/// Wrong OTP / validation errors also use HTTP 417 with `"success": false` — those
/// must stay on the current screen and are **not** treated as session expiry.
class SessionExpiredRedirect {
  static bool _isHandling = false;

  static void handle(http.Response response, {Uri? requestUri}) {
    if (response.statusCode != 417) return;

    // OTP verify endpoints always handle 417 locally (wrong code, etc.).
    if (requestUri != null && ApiResponseEnvelope.isOtpVerifyEndpoint(requestUri)) {
      return;
    }

    // Business failure envelope — show error on current screen, do not redirect.
    if (ApiResponseEnvelope.isExplicitFailure(response)) return;

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
