import 'package:core/bases/states/base/non_render_state.dart';
import 'package:core/bases/states/base/render_data_state.dart';
import '../model/login_response.dart';
import '../model/login_screen_model.dart';

class InitLoginScreen extends RenderDataState<LoginScreenModel> {
  InitLoginScreen({required LoginScreenModel data}) : super(data);
}

class UpdateLoginScreenUI extends RenderDataState<LoginScreenModel> {
  UpdateLoginScreenUI(super.data);
}

class OnLoginSuccessState extends NonRenderState {
  final LoginResponse loginResponse;
  
  OnLoginSuccessState(this.loginResponse);
}

class OnLoginErrorState extends NonRenderState {
  final String errorMessage;
  
  OnLoginErrorState(this.errorMessage);
}

class OnLoginLoadingState extends NonRenderState {}
