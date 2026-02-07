import 'package:core/bases/states/base/non_render_state.dart';
import 'package:core/bases/states/base/render_data_state.dart';
import '../model/email_input_model.dart';

class UpdateEmailInputUI extends RenderDataState<EmailInputModel> {
  UpdateEmailInputUI(super.data);
}

class OnEmailLoadingState extends NonRenderState {
  OnEmailLoadingState();
}

class OnEmailSavedState extends NonRenderState {
  OnEmailSavedState();
}

class OnEmailErrorState extends NonRenderState {
  final String errorMessage;
  
  OnEmailErrorState(this.errorMessage);
}

class OnEmailVerificationRequiredState extends NonRenderState {
  final String email;
  final String emailOtpRequestId;
  final String transactionId;
  
  OnEmailVerificationRequiredState({
    required this.email,
    required this.emailOtpRequestId,
    required this.transactionId,
  });
}
