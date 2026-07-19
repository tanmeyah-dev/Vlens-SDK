import 'package:uuid/uuid.dart';

import '../model/login_response.dart';

/// Resolved credentials required before [VLensManager.init].
///
/// [transactionId] is always created locally after login/OTP success
/// (not taken from the login API response).
class VlensSdkCredentials {
  final String accessToken;
  final String refreshToken;
  final String transactionId;

  const VlensSdkCredentials({
    required this.accessToken,
    required this.refreshToken,
    required this.transactionId,
  });

  /// Builds credentials from login data, or `null` if tokens are missing.
  ///
  /// - [accessToken]: plain token, else non-empty [LoginResponseData.encryptedAccessToken]
  /// - [refreshToken]: must be non-empty
  /// - [transactionId]: always a newly generated UUID
  static VlensSdkCredentials? tryResolve(LoginResponseData data) {
    final accessToken = _resolveAccessToken(data);
    final refreshToken = data.refreshToken?.trim() ?? '';

    if (accessToken.isEmpty || refreshToken.isEmpty) {
      return null;
    }

    return VlensSdkCredentials(
      accessToken: accessToken,
      refreshToken: refreshToken,
      transactionId: const Uuid().v4(),
    );
  }

  /// Human-readable reason when [tryResolve] returns null (for logs / UI).
  static String missingFieldsMessage(LoginResponseData data) {
    final missing = <String>[];
    if (_resolveAccessToken(data).isEmpty) missing.add('accessToken');
    if ((data.refreshToken?.trim() ?? '').isEmpty) missing.add('refreshToken');
    return 'لا يمكن بدء التحقق: بيانات ناقصة (${missing.join(', ')})';
  }

  static String _resolveAccessToken(LoginResponseData data) {
    final plain = data.accessToken?.trim() ?? '';
    if (plain.isNotEmpty) return plain;
    return data.encryptedAccessToken?.trim() ?? '';
  }
}
