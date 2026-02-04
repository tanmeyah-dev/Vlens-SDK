import 'package:flutter/material.dart';

/// Fixed size screen wrapper for SDK screens.
///
/// Wraps content with fixed dimensions: width 430, height 932.
/// Centers the content on larger screens and clips on smaller screens.
class FixedSizeScreen extends StatelessWidget {
  /// The child widget to wrap.
  final Widget child;

  /// Fixed width for SDK screens.
  static const double fixedWidth = 430.0;

  /// Fixed height for SDK screens.
  static const double fixedHeight = 932.0;

  const FixedSizeScreen({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: fixedWidth,
        height: fixedHeight,
        child: ClipRect(
          child: child,
        ),
      ),
    );
  }
}
