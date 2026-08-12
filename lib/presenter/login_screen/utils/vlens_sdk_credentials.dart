import 'package:uuid/uuid.dart';

import '../model/login_response.dart';

/// Resolved credentials required before [VLensManager.init].
///
/// Ensures [transactionId], [accessToken], [apiKey], and [tenancyName] are all
/// present and non-empty before the SDK is started.
class VlensSdkCredentials {
  final String accessToken;
  final String refreshToken;
  final String transactionId;
  final String apiKey;
  final String tenancyName;
  final String apiBaseUrl;

  const VlensSdkCredentials({
    required this.accessToken,
    required this.refreshToken,
    required this.transactionId,
    required this.apiKey,
    required this.tenancyName,
    required this.apiBaseUrl,
  });

  static const String defaultApiKey =
      'j1m9DwIywPS1dPCkFUT2hM2IRr10921gq5PBzQID6xI';
  static const String defaultTenancyName = 'tanmeyah-stg';
  static const String defaultApiBaseUrl = 'https://api.vlenseg.com';

  /// Builds credentials from login data, or `null` if any required field is missing.
  ///
  /// Required before VLens init:
  /// - [accessToken] (or non-empty encryptedAccessToken)
  /// - [transactionId] (fresh local UUID)
  /// - [apiKey]
  /// - [tenancyName]
  ///
  /// [refreshToken] is also required by the SDK env config.
  static VlensSdkCredentials? tryResolve(LoginResponseData data) {
    final accessToken = _resolveAccessToken(data);
    final refreshToken = data.refreshToken?.trim() ?? '';
    final transactionId = const Uuid().v4().trim();
    const apiKey = defaultApiKey;
    const tenancyName = defaultTenancyName;
    const apiBaseUrl = defaultApiBaseUrl;

    if (accessToken.isEmpty ||
        refreshToken.isEmpty ||
        !_isValidTransactionId(transactionId) ||
        apiKey.trim().isEmpty ||
        tenancyName.trim().isEmpty ||
        apiBaseUrl.trim().isEmpty) {
      return null;
    }

    return VlensSdkCredentials(
      accessToken: accessToken,
      refreshToken: refreshToken,
      transactionId: transactionId,
      apiKey: apiKey,
      tenancyName: tenancyName,
      apiBaseUrl: apiBaseUrl,
    );
  }

  /// Human-readable reason when [tryResolve] returns null (for logs / UI).
  static String missingFieldsMessage(LoginResponseData data) {
    final missing = <String>[];
    if (_resolveAccessToken(data).isEmpty) missing.add('accessToken');
    if ((data.refreshToken?.trim() ?? '').isEmpty) missing.add('refreshToken');
    if (defaultApiKey.trim().isEmpty) missing.add('apiKey');
    if (defaultTenancyName.trim().isEmpty) missing.add('tenancyName');
    // transactionId is generated locally; only report if generation failed.
    final tx = const Uuid().v4().trim();
    if (!_isValidTransactionId(tx)) missing.add('transactionId');
    if (missing.isEmpty) {
      return 'لا يمكن بدء التحقق: بيانات ناقصة (transactionId, accessToken, apiKey, tenancyName)';
    }
    return 'لا يمكن بدء التحقق: بيانات ناقصة (${missing.join(', ')})';
  }

  /// Final gate used right before [VLensManager.init].
  bool get isReadyForVlensInit =>
      accessToken.trim().isNotEmpty &&
      refreshToken.trim().isNotEmpty &&
      _isValidTransactionId(transactionId) &&
      apiKey.trim().isNotEmpty &&
      tenancyName.trim().isNotEmpty &&
      apiBaseUrl.trim().isNotEmpty;

  static bool _isValidTransactionId(String? transactionId) {
    final value = transactionId?.trim() ?? '';
    if (value.isEmpty) return false;
    if (value == '00000000-0000-0000-0000-000000000000') return false;
    return true;
  }

  static String _resolveAccessToken(LoginResponseData data) {
    final plain = data.accessToken?.trim() ?? '';
    if (plain.isNotEmpty) return plain;
    return data.encryptedAccessToken?.trim() ?? '';
  }
}
