import 'package:flutter/material.dart';

class XpProgressBar extends StatelessWidget {
  final int current;
  final int max;

  const XpProgressBar({
    super.key,
    required this.current,
    required this.max,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: LinearProgressIndicator(
        value: current / max,
        backgroundColor: Colors.white.withValues(alpha: 0.2),
        valueColor: const AlwaysStoppedAnimation(Colors.white),
        minHeight: 8,
      ),
    );
  }
}
