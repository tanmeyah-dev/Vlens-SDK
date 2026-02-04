import 'package:core/bases/base_bloc.dart';
import '../event/loginscreen_event.dart';
import '../model/loginscreen_model.dart';
import '../state/loginscreen_state.dart';

class LoginScreenBloc extends BaseBloc {
  final LoginScreenModel _model;

  LoginScreenBloc(this._model)
      : super(initialState: InitLoginScreen(data: _model)) {
    on<EnableLoginButtonEvent>(_onEnableLoginButtonEvent);
    on<PasswordVisibilityEvent>(_onPasswordVisibilityEvent);
    on<LoginEvent>(_onLoginEvent);
    on<UpdateLoginScreenUIEvent>(_onUpdateLoginScreenUIEvent);
  }

  _onEnableLoginButtonEvent(EnableLoginButtonEvent event, emit) {
    _model.isLoginButtonDisabled = !event.isEnabled;
    emit(UpdateLoginScreenUI(_model));
  }

  _onPasswordVisibilityEvent(PasswordVisibilityEvent event, emit) {
    _model.passwordVisible = event.visible;
    emit(UpdateLoginScreenUI(_model));
  }

  _onUpdateLoginScreenUIEvent(UpdateLoginScreenUIEvent event, emit) {
    emit(UpdateLoginScreenUI(event.model));
  }

  _onLoginEvent(LoginEvent event, emit) async {
    // TODO: Implement actual login API call here
    // For demonstration, simulate login failure for wrong phone number
    // Replace this with actual API call
    
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 1));
    
    // Example: Check if phone number is wrong (for demo purposes)
    // In real implementation, this would be an API call
    if (event.mobileNumber == "01111111111" || event.mobileNumber == "01234567890") {
      emit(OnLoginErrorState("رقم الموبايل غير صحيح. يرجى التحقق من الرقم والمحاولة مرة أخرى"));
      return;
    }
    
    // Simulate other validation errors
    if (event.mobileNumber.length != 11) {
      emit(OnLoginErrorState("رقم الموبايل يجب أن يكون 11 رقم"));
      return;
    }
    
    // If login is successful
    emit(OnLoginSuccessState());
  }
}
