import 'package:core/bases/states/base/non_render_state.dart';
import 'package:core/bases/states/base/render_data_state.dart';
import '../model/validate_user_model.dart';

class UpdateValidateUserUI extends RenderDataState<ValidateUserModel> {
  UpdateValidateUserUI(super.data);
}

class OnValidateUserSavedState extends NonRenderState {
  final String? phoneNumberOtpRequestId;
  final String? transactionId;

  OnValidateUserSavedState({
    this.phoneNumberOtpRequestId,
    this.transactionId,
  });
}

class OnValidateUserLoadingState extends NonRenderState {
  OnValidateUserLoadingState();
}

class OnValidateUserErrorState extends NonRenderState {
  final String errorMessage;

  OnValidateUserErrorState(this.errorMessage);
}

class OnPhoneNumberExistsState extends NonRenderState {
  OnPhoneNumberExistsState();
}
