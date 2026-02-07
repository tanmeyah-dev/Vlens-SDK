import 'package:core/bases/event/base/base_event.dart';

class EnableSaveButtonEvent extends BaseEvent {
  final bool isEnabled;

  EnableSaveButtonEvent(this.isEnabled);
}

class SaveMobileNumberEvent extends BaseEvent {
  final String mobileNumber;

  SaveMobileNumberEvent(this.mobileNumber);
}

class UpdateLoadingStateEvent extends BaseEvent {
  final bool isLoading;

  UpdateLoadingStateEvent(this.isLoading);
}
