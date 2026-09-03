/// Route arguments for [LoginScreenScene] when opened from the host app.
class LoginScreenNavArgs {
  final String? phoneNumber;
  final String? vlenseStatus;
  final String? sessionMessage;

  const LoginScreenNavArgs({
    this.phoneNumber,
    this.vlenseStatus,
    this.sessionMessage,
  });
}
