import 'package:core/bases/event/base/base_event.dart';

class EnableSaveButtonEvent extends BaseEvent {
  final bool isEnabled;

  EnableSaveButtonEvent(this.isEnabled);
}

class RegisterScreenSaveEvent extends BaseEvent {
  /// Verified email from the email step / cache (read-only on screen).
  final String email;
  final String securityCode;
  final String mobileNumber;

  /// Google OAuth id, or empty/`null` when user verified email via OTP.
  final String? oauthTokenVerificationRequestId;

  /// Email OTP request id from verify-email (email flow).
  final String? emailOtpRequestId;

  RegisterScreenSaveEvent(
    this.email,
    this.securityCode, {
    required this.mobileNumber,
    this.oauthTokenVerificationRequestId,
    this.emailOtpRequestId,
  });
}
