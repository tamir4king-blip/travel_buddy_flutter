import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DevEntryGesture extends StatelessWidget {
  final Widget child;

  const DevEntryGesture({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => context.push('/dev-panel'),
      child: child,
    );
  }
}
