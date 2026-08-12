import 'package:core/bases/event/base/base_event.dart';

import '../model/summary_answer_item.dart';

/// Fetches request/fields when the user is eligible.
class UserInfoLoadFieldsEvent extends BaseEvent {}

/// Re-emits [UpdateUserInfoUI] after the [UserInfoModel] was mutated in place (form controls).
class UserInfoFormChangedEvent extends BaseEvent {}

/// Form passed validation; submit request/create then navigate to summary.
class UserInfoSubmitEvent extends BaseEvent {
  final List<SummaryAnswerItem> answers;

  UserInfoSubmitEvent(this.answers);
}
