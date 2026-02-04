import 'package:flutter/material.dart';
import 'package:core/bases/states/base/base_state.dart';

/// Initial loading state.
class InitLoadingState extends BaseStates {
  final Color? backgroundColor;
  final bool withBackOption;

  InitLoadingState([this.backgroundColor]) : withBackOption = false;
}
