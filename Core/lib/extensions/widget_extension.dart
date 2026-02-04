import 'package:flutter/cupertino.dart';

/// Extension for creating SizedBox widgets from integers.
extension WidgetExtensions on int {
  Widget get height => SizedBox(height: toDouble());
  Widget get width => SizedBox(width: toDouble());
}


