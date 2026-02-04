import 'package:core/bases/states/base/base_state.dart';

/// State that contains data to render in the UI.
class RenderDataState<D> extends BaseStates {
  D data;

  RenderDataState(this.data);
}


