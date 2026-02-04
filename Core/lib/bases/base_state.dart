import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core/bases/base_bloc.dart';
import 'package:core/bases/states/base/base_state.dart' as states;
import 'package:core/bases/states/base/render_data_state.dart';
import 'package:core/bases/states/base/non_render_state.dart';
import 'package:core/bases/states/base/init_loading_state.dart';
import 'package:core/bases/states/base/init_screen.dart';
import 'package:core/bases/event/base/base_event.dart';
import 'package:core/components/screen/fixed_size_screen.dart';

/// Base state class for all screens using BLoC pattern.
abstract class BaseState<S extends StatefulWidget, T extends BaseBloc, D>
    extends State<S> {
  late double screenWidth;
  late double screenHeight;
  late BuildContext baseContext;
  late BuildContext screenContext;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        screenContext = context;
        screenWidth = constraints.biggest.width;
        screenHeight = constraints.biggest.height;
        return BlocProvider<T>(
          create: (context) => createBloc(),
          child: BlocConsumer<T, states.BaseStates>(
            buildWhen: (previous, current) => current is RenderDataState,
            listenWhen: (previous, current) => current is NonRenderState,
            listener: (context, state) {
              baseContext = context;
              _handleCommonEventAction(state);
            },
            builder: (context, state) {
              baseContext = context;
              return _handleWidgetRendering(state, context);
            },
          ),
        );
      },
    );
  }

  void _handleCommonEventAction(states.BaseStates state) {
    if (state is NonRenderState) {
      listenToState(context, state);
    }
  }

  Widget _handleWidgetRendering(states.BaseStates state, BuildContext context) {
    if (state is InitLoadingState) {
      return FixedSizeScreen(
        child: _loadingAnimation(state),
      );
    } else if (state is InitScreen) {
      return FixedSizeScreen(
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).requestFocus(FocusNode());
          },
          child: buildWidget(context, state as RenderDataState<D>),
        ),
      );
    }
    return FixedSizeScreen(
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: PopScope(
          canPop: true,
          child: buildWidget(context, state as RenderDataState<D>),
        ),
      ),
    );
  }

  Widget _loadingAnimation(InitLoadingState state) {
    return Scaffold(
      backgroundColor: state.backgroundColor ?? Colors.white,
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  /// Build the widget for the given state.
  Widget buildWidget(BuildContext context, RenderDataState<D> state);

  /// Listen to state changes (for navigation, callbacks, etc.).
  void listenToState(BuildContext context, states.BaseStates state);

  /// Emit an event to the BLoC.
  void emit(BaseEvent event) {
    (BlocProvider.of<T>(baseContext)).add(event);
  }

  /// Get the BLoC instance.
  T bloc() {
    return BlocProvider.of<T>(baseContext);
  }

  /// Create the BLoC instance.
  T createBloc();

  void hideKeyboard() {
    FocusScope.of(baseContext).requestFocus(FocusNode());
  }
}


