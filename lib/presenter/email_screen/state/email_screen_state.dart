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
  /// Email to pass to register screen (manual entry or from Google).
  final String? email;

  /// Google OAuth request id; `null` for email OTP / already-confirmed email.
  final String? oauthTokenVerificationRequestId;

  OnEmailConfirmedState({
    this.email,
    this.oauthTokenVerificationRequestId,
  });
}

/// Dismisses the loading dialog without showing an error (e.g. Google cancel).
class OnEmailLoadingDismissedState extends NonRenderState {
  OnEmailLoadingDismissedState();
}
