import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core/bases/event/base/base_event.dart';
import 'package:core/bases/states/base/base_state.dart';
import 'package:core/bases/states/base/init_loading_state.dart';

/// Base BLoC class for all BLoCs in the application.
abstract class BaseBloc extends Bloc<BaseEvent, BaseStates> {
  BaseBloc({BaseStates? initialState})
      : super(initialState ?? InitLoadingState());
}
