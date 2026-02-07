import 'package:core/bases/states/base/non_render_state.dart';
import 'package:core/bases/states/base/render_data_state.dart';
import '../model/mobile_number_model.dart';

class UpdateMobileNumberUI extends RenderDataState<MobileNumberModel> {
  UpdateMobileNumberUI(super.data);
}

class OnMobileNumberSavedState extends NonRenderState {
  final String? phoneNumberOtpRequestId;
  final String? transactionId;

  OnMobileNumberSavedState({
    this.phoneNumberOtpRequestId,
    this.transactionId,
  });
}

class OnMobileNumberLoadingState extends NonRenderState {
  OnMobileNumberLoadingState();
}

class OnMobileNumberErrorState extends NonRenderState {
  final String errorMessage;

  OnMobileNumberErrorState(this.errorMessage);
}

class OnPhoneNumberExistsState extends NonRenderState {
  OnPhoneNumberExistsState();
}
