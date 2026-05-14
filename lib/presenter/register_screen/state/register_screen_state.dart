import 'package:core/bases/states/base/non_render_state.dart';
import 'package:core/bases/states/base/render_data_state.dart';
import '../model/create_user_response.dart';
import '../model/register_screen_model.dart';

class UpdateRegisterScreenUI extends RenderDataState<RegisterScreenModel> {
  UpdateRegisterScreenUI(super.data);
}

class OnRegisterScreenSavedState extends NonRenderState {
  final CreateUserResponse response;

  OnRegisterScreenSavedState(this.response);
}

class OnRegisterScreenLoadingState extends NonRenderState {
  OnRegisterScreenLoadingState();
}

class OnRegisterScreenErrorState extends NonRenderState {
  final String errorMessage;
  
  OnRegisterScreenErrorState(this.errorMessage);
}
