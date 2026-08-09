import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'google_oauth_config.dart';

/// Obtains a Google ID token for Vlens `StepVerifyOAuthToken`.
class GoogleOAuthHelper {
  GoogleOAuthHelper._();

  static bool _initialized = false;
  static String? _lastNonce;

  /// Re-inits Google Sign-In with a fresh nonce on every auth when [freshNonce]
  /// is true. A unique nonce forces Credential Manager to mint a new IdToken
  /// instead of returning a cached nearly-expired JWT.
  static Future<void> ensureInitialized({bool freshNonce = false}) async {
    if (_initialized && !freshNonce) return;

    final clientId = (!kIsWeb && Platform.isIOS)
        ? GoogleOAuthConfig.iosClientId
        : null;
    final nonce = _generateNonce();
    _lastNonce = nonce;

    print('');
    print('═══════════════════════════════════════════════════════');
    print('🔑 GoogleSignIn.initialize');
    print('platform: ${kIsWeb ? 'web' : Platform.operatingSystem}');
    print('clientId: $clientId');
    print('serverClientId: ${GoogleOAuthConfig.serverClientId}');
    print('androidClientId (console only): ${GoogleOAuthConfig.androidClientId}');
    print('nonce: $nonce');
    print('═══════════════════════════════════════════════════════');
    print('');

    // Safe to call repeatedly on Android (authenticationEvents is null).
    await GoogleSignIn.instance.initialize(
      clientId: clientId,
      serverClientId: GoogleOAuthConfig.serverClientId,
      nonce: nonce,
    );
    _initialized = true;
  }

  /// Interactive Google sign-in; returns a non-empty, non-near-expiry IdToken.
  ///
  /// Throws [GoogleSignInException] when the user cancels or sign-in fails.
  /// Throws [StateError] when Google does not return a usable IdToken.
  static Future<String> getIdToken() async {
    // Fresh nonce each attempt so Play Services cannot reuse an old IdToken.
    await ensureInitialized(freshNonce: true);
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}

    var idToken = await _authenticateForIdToken();
    if (!_isNearExpiry(idToken)) {
      _logNonceMatch(idToken);
      return idToken;
    }

    print(
      '⚠️ IdToken still near expiry after nonce+signOut '
      '(age=${_tokenAgeSeconds(idToken)}s, '
      'remaining=${_secondsUntilExp(idToken)}s). Retry once...',
    );

    await ensureInitialized(freshNonce: true);
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    idToken = await _authenticateForIdToken();
    if (!_isNearExpiry(idToken)) {
      print('✅ Fresh IdToken after nonce retry');
      _logNonceMatch(idToken);
      return idToken;
    }

    // Last resort: wait for Play Services cache TTL, then mint again.
    // Only auto-wait when under 5 minutes so the loading UI stays reasonable.
    final remaining = _secondsUntilExp(idToken) ?? 0;
    if (remaining > 0 && remaining <= 5 * 60) {
      final waitSeconds = remaining + 2;
      print(
        '⏳ Waiting ${waitSeconds}s for Google IdToken cache to expire...',
      );
      await Future.delayed(Duration(seconds: waitSeconds));
      await ensureInitialized(freshNonce: true);
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
      idToken = await _authenticateForIdToken();
      if (!_isNearExpiry(idToken)) {
        print('✅ Fresh IdToken after cache expiry wait');
        _logNonceMatch(idToken);
        return idToken;
      }
    }

    final waitMinutes = remaining <= 0 ? 1 : ((remaining + 59) ~/ 60);
    throw StateError(
      'جلسة Google ما زالت تستخدم رمزًا قديمًا. انتظر حوالي $waitMinutes دقيقة ثم حاول مرة أخرى.',
    );
  }

  static Future<String> _authenticateForIdToken() async {
    final account = await GoogleSignIn.instance.authenticate(
      scopeHint: const ['email', 'openid', 'profile'],
    );

    final idToken = account.authentication.idToken?.trim();
    if (idToken == null || idToken.isEmpty) {
      throw StateError(
        'Google IdToken is empty. Create a Web OAuth client in Google Cloud '
        'Console and set GoogleOAuthConfig.serverClientId to that Web client ID.',
      );
    }
    return idToken;
  }

  static bool _isNearExpiry(String idToken) {
    final remaining = _secondsUntilExp(idToken);
    // Prefer tokens with ≥10 minutes left so Vlens clock skew does not reject.
    return remaining == null || remaining < 10 * 60;
  }

  static int _tokenAgeSeconds(String idToken) {
    final iat = _epochSecondsToUtc(decodeIdTokenClaims(idToken)['iat']);
    if (iat == null) return 0;
    return DateTime.now().toUtc().difference(iat).inSeconds;
  }

  static int? _secondsUntilExp(String idToken) {
    final exp = _epochSecondsToUtc(decodeIdTokenClaims(idToken)['exp']);
    if (exp == null) return null;
    return exp.difference(DateTime.now().toUtc()).inSeconds;
  }

  static String _generateNonce([int byteLength = 32]) {
    final random = Random.secure();
    final bytes = List<int>.generate(byteLength, (_) => random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  static void _logNonceMatch(String idToken) {
    final claims = decodeIdTokenClaims(idToken);
    print('nonce sent: $_lastNonce');
    print('nonce in token: ${claims['nonce']}');
  }

  /// Decodes JWT payload claims without verifying the signature.
  /// Safe for debug logs — never includes the raw token.
  static Map<String, dynamic> decodeIdTokenClaims(String idToken) {
    try {
      final parts = idToken.split('.');
      if (parts.length < 2) return const {};

      final normalized = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final json = jsonDecode(decoded);
      if (json is! Map<String, dynamic>) return const {};
      return json;
    } catch (_) {
      return const {};
    }
  }

  static DateTime? _epochSecondsToUtc(Object? value) {
    final seconds = value is int
        ? value
        : value is num
            ? value.toInt()
            : int.tryParse(value?.toString() ?? '');
    if (seconds == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);
  }

  /// Prints aud / iss / email / azp / exp for backend comparison (no raw token).
  static void logIdTokenClaims(String idToken) {
    final claims = decodeIdTokenClaims(idToken);
    final now = DateTime.now().toUtc();
    final iat = _epochSecondsToUtc(claims['iat']);
    final exp = _epochSecondsToUtc(claims['exp']);
    final remaining = exp?.difference(now).inSeconds;

    print('');
    print('═══════════════════════════════════════════════════════');
    print('🔑 GOOGLE ID TOKEN CLAIMS (debug)');
    print('═══════════════════════════════════════════════════════');
    print('aud: ${claims['aud']}');
    print('azp: ${claims['azp']}');
    print('iss: ${claims['iss']}');
    print('email: ${claims['email']}');
    print('email_verified: ${claims['email_verified']}');
    print('nonce: ${claims['nonce']}');
    print('iat: ${claims['iat']} ($iat)');
    print('exp: ${claims['exp']} ($exp)');
    print('now (device UTC): $now');
    print(
      'token age seconds: ${iat == null ? null : now.difference(iat).inSeconds}',
    );
    print('seconds until exp: $remaining');
    print('serverClientId (expected aud): ${GoogleOAuthConfig.serverClientId}');
    print('═══════════════════════════════════════════════════════');
    print('');
  }

  static Future<void> signOut() async {
    await ensureInitialized();
    await GoogleSignIn.instance.signOut();
  }
}
