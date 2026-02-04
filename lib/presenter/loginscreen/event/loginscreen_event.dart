import 'package:core/bases/event/base/base_event.dart';
import '../model/loginscreen_model.dart';

class EnableLoginButtonEvent extends BaseEvent {
  final bool isEnabled;
  EnableLoginButtonEvent(this.isEnabled);
}

class PasswordVisibilityEvent extends BaseEvent {
  final bool visible;
  PasswordVisibilityEvent(this.visible);
}

class LoginEvent extends BaseEvent {
  final String mobileNumber;
  final String password;
  LoginEvent(this.mobileNumber, this.password);
}

class UpdateLoginScreenUIEvent extends BaseEvent {
  final LoginScreenModel model;
  UpdateLoginScreenUIEvent(this.model);
}
