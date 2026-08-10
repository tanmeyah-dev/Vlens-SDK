/// Route arguments for [RegisterScreen] / create-user.
class RegisterScreenNavArgs {
  final String? verifiedEmail;

  /// From Google OAuth verify response; empty/`null` for email OTP flow.
  final String? oauthTokenVerificationRequestId;

  /// From email send/verify OTP; used by create-user for non-Google flow.
  final String? emailOtpRequestId;

  final String? phoneNumberOtpRequestId;
  final String? transactionId;
  final String? mobileNumber;

  RegisterScreenNavArgs({
    this.verifiedEmail,
    this.oauthTokenVerificationRequestId,
    this.emailOtpRequestId,
    this.phoneNumberOtpRequestId,
    this.transactionId,
    this.mobileNumber,
  });
}
