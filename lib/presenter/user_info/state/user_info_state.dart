import 'package:core/bases/states/base/non_render_state.dart';
import 'package:core/bases/states/base/render_data_state.dart';

import '../model/summary_answer_item.dart';
import '../model/user_info_model.dart';

class UpdateUserInfoUI extends RenderDataState<UserInfoModel> {
  UpdateUserInfoUI(super.data);
}

class UserInfoNavigateToSummaryState extends NonRenderState {
  final List<SummaryAnswerItem> answeredFields;

  UserInfoNavigateToSummaryState(this.answeredFields);
}

/// One-click-apply failed; scene should show [message] and reset submit UI.
class UserInfoSubmitFailedState extends NonRenderState {
  final String message;

  UserInfoSubmitFailedState(this.message);
}
