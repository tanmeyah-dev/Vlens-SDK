import 'package:core/bases/base_bloc.dart';
import 'package:core/bases/states/base/init_screen.dart';
import '../event/home_event.dart';
import '../model/home_model.dart';
import '../state/home_state.dart';

class HomeBloc extends BaseBloc {
  final HomeModel _model;

  HomeBloc(this._model)
      : super(initialState: InitHomeScreen(_model)) {
    on<UpdateHomeUIEvent>(_onUpdateHomeUIEvent);
  }

  _onUpdateHomeUIEvent(UpdateHomeUIEvent event, emit) {
    emit(InitHomeScreen(_model));
  }
}
