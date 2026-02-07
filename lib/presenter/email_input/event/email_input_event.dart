import 'package:core/bases/event/base/base_event.dart';

class EnableSaveButtonEvent extends BaseEvent {
  final bool isEnabled;

  EnableSaveButtonEvent(this.isEnabled);
}

class SaveEmailEvent extends BaseEvent {
  final String email;

  SaveEmailEvent(this.email);
}
