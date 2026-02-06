import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core/bases/base_bloc.dart';
import 'package:core/bases/states/base/base_state.dart' as states;
import 'package:core/bases/states/base/render_data_state.dart';
import 'package:core/bases/states/base/non_render_state.dart';
import 'package:core/bases/states/base/init_loading_state.dart';
import 'package:core/bases/states/base/init_screen.dart';
import 'package:core/bases/event/base/base_event.dart';

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
      return _loadingAnimation(state);
    } else if (state is InitScreen) {
      return GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: buildWidget(context, state as RenderDataState<D>),
      );
    } else if (state is RenderDataState) {
      return GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: PopScope(
          canPop: true,
          child: buildWidget(context, state as RenderDataState<D>),
        ),
      );
    }
    // For non-render states (like loading), show the last rendered state with loading overlay
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: PopScope(
        canPop: true,
        child: Stack(
          children: [
            // Show last rendered state if available
            if (state is! InitLoadingState)
              buildWidget(context, _getLastRenderState() ?? state as RenderDataState<D>),
            // Show loading overlay
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  RenderDataState<D>? _getLastRenderState() {
    // This is a placeholder - in a real implementation, you'd track the last render state
    return null;
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


