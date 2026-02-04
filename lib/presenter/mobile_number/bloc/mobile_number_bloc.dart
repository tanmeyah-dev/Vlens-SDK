import 'package:core/bases/base_bloc.dart';
import 'package:core/bases/states/general_state/general_render_state.dart';
import 'package:core/bases/states/base/init_screen.dart';
import '../event/mobile_number_event.dart';
import '../model/mobile_number_model.dart';
import '../state/mobile_number_state.dart';

class MobileNumberBloc extends BaseBloc {
  final MobileNumberModel _mobileNumberModel;

  MobileNumberBloc(this._mobileNumberModel)
      : super(initialState: InitScreen<MobileNumberModel>(_mobileNumberModel)) {
    on<EnableSaveButtonEvent>(_onEnableSaveButtonEvent);
    on<CountryCodeChangedEvent>(_onCountryCodeChangedEvent);
    on<SaveMobileNumberEvent>(_onSaveMobileNumberEvent);
  }

  _onEnableSaveButtonEvent(EnableSaveButtonEvent event, emit) {
    _mobileNumberModel.isSaveButtonDisabled = !event.isEnabled;
    emit(UpdateMobileNumberUI(_mobileNumberModel));
  }

  _onCountryCodeChangedEvent(CountryCodeChangedEvent event, emit) {
    _mobileNumberModel.selectedCountryCode = event.countryCode;
    emit(UpdateMobileNumberUI(_mobileNumberModel));
  }

  _onSaveMobileNumberEvent(SaveMobileNumberEvent event, emit) async {
    // TODO: Implement save logic here
    // For now, just emit success state
    emit(OnMobileNumberSavedState());
  }
}
