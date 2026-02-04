import 'package:core/bases/base_bloc.dart';
import 'package:core/bases/states/general_state/general_render_state.dart';
import 'package:core/bases/states/base/init_screen.dart';
import '../event/username_security_code_event.dart';
import '../model/username_security_code_model.dart';
import '../state/username_security_code_state.dart';

class UsernameSecurityCodeBloc extends BaseBloc {
  final UsernameSecurityCodeModel _model;

  UsernameSecurityCodeBloc(this._model)
      : super(initialState: InitScreen<UsernameSecurityCodeModel>(_model)) {
    on<EnableSaveButtonEvent>(_onEnableSaveButtonEvent);
    on<SaveUsernameSecurityCodeEvent>(_onSaveUsernameSecurityCodeEvent);
  }

  _onEnableSaveButtonEvent(EnableSaveButtonEvent event, emit) {
    _model.isSaveButtonDisabled = !event.isEnabled;
    emit(UpdateUsernameSecurityCodeUI(_model));
  }

  _onSaveUsernameSecurityCodeEvent(SaveUsernameSecurityCodeEvent event, emit) async {
    // TODO: Implement save logic here
    // For now, just emit success state
    emit(OnUsernameSecurityCodeSavedState());
  }
}
