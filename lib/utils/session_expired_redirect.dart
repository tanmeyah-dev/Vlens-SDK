import 'dart:async';

import 'package:core/style/app_colors.dart';
import 'package:core/utils/cache/verification_cache.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../presenter/login_screen/model/login_screen_nav_args.dart';
import '../routes/route_path.dart';
import 'sdk_api_response.dart';
import 'sdk_navigator.dart';

/// Redirects to [LoginScreenScene] when an API response is HTTP 401, HTTP 429,
/// body code 401/429, or Unauthorized. Shows the API message first, then navigates.
class SessionExpiredRedirect {
  static bool _isHandling = false;

  static const Duration _messageDisplayDuration = Duration(seconds: 3);

  static void handle(http.Response response, {Uri? requestUri}) {
    final api = SdkApiResponse.from(response);
    if (!api.isUnauthorized) return;
    if (_isHandling) return;
    _isHandling = true;
    unawaited(_redirectToLogin(response));
  }

  static String _resolveMessage(http.Response response) {
    final api = SdkApiResponse.from(response);
    if (response.statusCode == 429 || api.responseCode == 429) {
      return api.message(
        fallback: 'تم تجاوز الحد الأقصى للطلبات. يرجى المحاولة مرة أخرى لاحقاً',
      );
    }
    return api.message(
      fallback: 'انتهت الجلسة، يرجى تسجيل الدخول مرة أخرى',
    );
  }

  static Future<void> _redirectToLogin(http.Response response) async {
    try {
      final message = _resolveMessage(response);
      final cache = VerificationCache();
      final mobile = await cache.getMobileNumber();
      await cache.clearLoginSession();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_showMessageThenNavigate(
          message: message,
          mobile: mobile,
        ));
      });
    } catch (_) {
      _isHandling = false;
    }
  }

  static Future<void> _showMessageThenNavigate({
    required String message,
    required String? mobile,
  }) async {
    try {
      final nav = SdkNavigator.key.currentState;
      if (nav == null || !nav.mounted) {
        _isHandling = false;
        return;
      }

      final messageShown = await _showMessage(nav.context, message);

      if (!nav.mounted) {
        _isHandling = false;
        return;
      }

      Route<dynamic>? topRoute;
      nav.popUntil((route) {
        topRoute = route;
        return true;
      });

      final phoneArg = (mobile != null && mobile.trim().isNotEmpty)
          ? mobile.trim()
          : null;

      if (topRoute?.settings.name == RoutePath.loginScreen) {
        _isHandling = false;
        return;
      }

      final trimmedMessage = message.trim();
      nav.pushNamedAndRemoveUntil(
        RoutePath.loginScreen,
        (route) => false,
        arguments: LoginScreenNavArgs(
          phoneNumber: phoneArg,
          sessionMessage: !messageShown && trimmedMessage.isNotEmpty
              ? trimmedMessage
              : null,
        ),
      );
    } finally {
      _isHandling = false;
    }
  }

  static Future<bool> _showMessage(BuildContext context, String message) async {
    if (message.trim().isEmpty) return false;

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      await Future<void>.delayed(_messageDisplayDuration);
      return false;
    }

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message.trim()),
        backgroundColor: AppColors.error,
        duration: _messageDisplayDuration,
      ),
    );
    await Future<void>.delayed(_messageDisplayDuration);
    return true;
  }
}
