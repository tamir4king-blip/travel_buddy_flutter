import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:travel_buddy_mobile/core/theme/app_theme.dart';

class XpProgressBar extends StatelessWidget {
  final int current;
  final int max;
  final double height;
  final List<Color>? gradientColors;

  const XpProgressBar({
    super.key,
    required this.current,
    required this.max,
    this.height = 8,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    final progress = max > 0 ? (current / max).clamp(0.0, 1.0) : 0.0;
    final colors = gradientColors ?? [AppColors.primaryLight, AppColors.cyan];

    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fillWidth = constraints.maxWidth * progress;
          return Stack(
            children: [
              // Background track
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(height / 2),
                ),
              ),
              // Gradient fill with glow
              AnimatedContainer(
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                width: fillWidth,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: colors,
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(height / 2),
                  boxShadow: fillWidth > 0
                      ? [
                          BoxShadow(
                            color: colors.first.withValues(alpha: 0.4),
                            blurRadius: 8,
                            spreadRadius: -1,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
              ),
              // Shimmer sweep overlay
              if (fillWidth > 0)
                ClipRRect(
                  borderRadius: BorderRadius.circular(height / 2),
                  child: SizedBox(
                    width: fillWidth,
                    child: Shimmer.fromColors(
                      baseColor: Colors.white.withValues(alpha: 0.0),
                      highlightColor: Colors.white.withValues(alpha: 0.2),
                      period: const Duration(milliseconds: 2500),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(height / 2),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
