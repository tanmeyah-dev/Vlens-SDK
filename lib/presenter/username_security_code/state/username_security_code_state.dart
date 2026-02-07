import 'package:core/bases/states/base/non_render_state.dart';
import 'package:core/bases/states/base/render_data_state.dart';
import '../model/username_security_code_model.dart';

class UpdateUsernameSecurityCodeUI extends RenderDataState<UsernameSecurityCodeModel> {
  UpdateUsernameSecurityCodeUI(super.data);
}

class OnUsernameSecurityCodeSavedState extends NonRenderState {
  OnUsernameSecurityCodeSavedState();
}

class OnUsernameSecurityCodeLoadingState extends NonRenderState {
  OnUsernameSecurityCodeLoadingState();
}

class OnUsernameSecurityCodeErrorState extends NonRenderState {
  final String errorMessage;
  
  OnUsernameSecurityCodeErrorState(this.errorMessage);
}
