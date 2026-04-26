import 'package:core/bases/event/base/base_event.dart';

class EnableSaveButtonEvent extends BaseEvent {
  final bool isEnabled;

  EnableSaveButtonEvent(this.isEnabled);
}

class SaveUsernameSecurityCodeEvent extends BaseEvent {
  /// Verified email from the email step / cache (read-only on screen).
  final String email;
  final String securityCode;
  final String mobileNumber;

  SaveUsernameSecurityCodeEvent(
    this.email,
    this.securityCode, {
    required this.mobileNumber,
  });
}
