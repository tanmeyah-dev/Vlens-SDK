import 'package:core/bases/states/base/non_render_state.dart';
import 'package:core/bases/states/base/render_data_state.dart';
import '../model/mobile_number_model.dart';

class UpdateMobileNumberUI extends RenderDataState<MobileNumberModel> {
  UpdateMobileNumberUI(super.data);
}

class OnMobileNumberSavedState extends NonRenderState {
  OnMobileNumberSavedState();
}
