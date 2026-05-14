import 'package:core/bases/event/base/base_event.dart';

class EnableSaveButtonEvent extends BaseEvent {
  final bool isEnabled;

  EnableSaveButtonEvent(this.isEnabled);
}

class ValidateUserSaveEvent extends BaseEvent {
  final String mobileNumber;

  ValidateUserSaveEvent(this.mobileNumber);
}

class UpdateLoadingStateEvent extends BaseEvent {
  final bool isLoading;

  UpdateLoadingStateEvent(this.isLoading);
}
