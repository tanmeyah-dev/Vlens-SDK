import 'package:core/bases/event/base/base_event.dart';

class EnableSaveButtonEvent extends BaseEvent {
  final bool isEnabled;

  EnableSaveButtonEvent(this.isEnabled);
}

class SaveUsernameSecurityCodeEvent extends BaseEvent {
  final String username;
  final String securityCode;

  SaveUsernameSecurityCodeEvent(this.username, this.securityCode);
}
