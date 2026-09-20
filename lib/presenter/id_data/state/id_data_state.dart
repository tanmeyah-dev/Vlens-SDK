import 'package:core/bases/states/base/non_render_state.dart';
import 'package:core/bases/states/base/render_data_state.dart';

import '../model/id_data_model.dart';

class UpdateIdDataUI extends RenderDataState<IdDataModel> {
  UpdateIdDataUI(super.data);
}

/// Emitted when eligibility check succeeds; the scene should push the user-info flow.
class IdDataNavigateToUserInfoState extends NonRenderState {
  final Map<String, dynamic> eligibilityResponse;

  IdDataNavigateToUserInfoState(this.eligibilityResponse);
}

/// Emitted when CMA check-user fails; the scene should show the mismatch dialog.
class IdDataCheckUserFailedState extends NonRenderState {
  final String message;

  IdDataCheckUserFailedState(this.message);
}
