import 'package:core/bases/states/base/non_render_state.dart';
import 'package:core/bases/states/base/render_data_state.dart';
import '../model/username_security_code_model.dart';

class UpdateUsernameSecurityCodeUI extends RenderDataState<UsernameSecurityCodeModel> {
  UpdateUsernameSecurityCodeUI(super.data);
}

class OnUsernameSecurityCodeSavedState extends NonRenderState {
  OnUsernameSecurityCodeSavedState();
}
