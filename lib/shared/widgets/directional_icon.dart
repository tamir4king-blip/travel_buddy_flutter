import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// A chevron icon that automatically flips direction for RTL layouts.
/// Shows chevronRight in LTR and chevronLeft in RTL.
class DirectionalChevron extends StatelessWidget {
  final double size;
  final Color? color;

  const DirectionalChevron({
    super.key,
    this.size = 18,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Icon(
      isRtl ? LucideIcons.chevronLeft : LucideIcons.chevronRight,
      size: size,
      color: color,
    );
  }
}
