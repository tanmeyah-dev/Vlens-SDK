import 'package:core/bases/states/base/non_render_state.dart';
import 'package:core/bases/states/base/render_data_state.dart';
import '../model/email_screen_model.dart';

class UpdateEmailScreenUI extends RenderDataState<EmailScreenModel> {
  UpdateEmailScreenUI(super.data);
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
  final String? emailOtpRequestId;
  final String? transactionId;
  
  OnEmailVerificationRequiredState({
    required this.email,
    this.emailOtpRequestId,
    this.transactionId,
  });
}

class OnEmailConfirmedState extends NonRenderState {
  OnEmailConfirmedState();
}
