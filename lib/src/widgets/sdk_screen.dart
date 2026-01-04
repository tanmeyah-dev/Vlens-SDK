import 'package:flutter/material.dart';

/// TAN SDK screen widget.
///
/// Base screen widget for TAN SDK screens.
class SDKScreen extends StatelessWidget {
  final String title;
  final Widget? body;

  const SDKScreen({
    super.key,
    required this.title,
    this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: body ??
          const Center(
            child: Text('SDK Screen Content'),
          ),
    );
  }
}
