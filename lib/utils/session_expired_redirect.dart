import 'dart:async';

import 'package:core/utils/cache/verification_cache.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../routes/route_path.dart';
import 'sdk_api_response.dart';
import 'sdk_navigator.dart';

/// Forces the SDK flow back to login when an API returns HTTP 417 for session
/// expiry. Responses with `success: false` are business validation errors and
/// must stay on the current screen so the caller can show the API message.
class SessionExpiredRedirect {
  static bool _isHandling = false;

  static const _otpPathSegments = <String>[
    'verify-otp',
    'send-otp',
    'send-email-otp',
  ];

  static void handle(http.Response response, {Uri? requestUri}) {
    if (response.statusCode != 417) return;
    if (_shouldStayOnCurrentScreen(response, requestUri)) return;
    if (_isHandling) return;
    _isHandling = true;
    unawaited(_redirectToLogin());
  }

  static bool _shouldStayOnCurrentScreen(
    http.Response response,
    Uri? requestUri,
  ) {
    if (SdkApiResponse.hasBusinessFailure(response)) return true;

    final path = (requestUri?.path ?? '').toLowerCase();
    for (final segment in _otpPathSegments) {
      if (path.contains(segment)) return true;
    }
    return false;
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
