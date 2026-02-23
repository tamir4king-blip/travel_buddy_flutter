import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:travel_buddy_mobile/core/theme/app_theme.dart';
import 'package:travel_buddy_mobile/shared/models/achievement.dart';

class AchievementMarker extends StatelessWidget {
  final Achievement achievement;
  final bool inRange;
  final VoidCallback? onTap;

  const AchievementMarker({
    super.key,
    required this.achievement,
    this.inRange = false,
    this.onTap,
  });

  static Color tierColor(AchievementTier tier) {
    return switch (tier) {
      AchievementTier.bronze => AppColors.bronze,
      AchievementTier.silver => AppColors.silver,
      AchievementTier.gold => AppColors.gold,
      AchievementTier.platinum => AppColors.platinum,
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = tierColor(achievement.tier);
    final isUnlocked = achievement.isUnlocked;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 48,
        height: 56,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Pulsing ring when in range
            if (inRange && !isUnlocked)
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.success, width: 2),
                ),
              )
                  .animate(onPlay: (c) => c.repeat())
                  .scaleXY(begin: 0.8, end: 1.2, duration: 1200.ms)
                  .fadeOut(begin: 0.8, duration: 1200.ms),

            // Pin body
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isUnlocked ? color.withValues(alpha: 0.4) : color,
                border: Border.all(
                  color: isUnlocked ? color.withValues(alpha: 0.6) : Colors.white,
                  width: 2,
                ),
                boxShadow: isUnlocked
                    ? null
                    : [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
              ),
              child: Icon(
                isUnlocked ? LucideIcons.check : LucideIcons.trophy,
                size: 18,
                color: isUnlocked ? Colors.white70 : Colors.white,
              ),
            ),

            // Pin tail
            Positioned(
              bottom: 0,
              child: CustomPaint(
                size: const Size(12, 10),
                painter: _PinTailPainter(
                  color: isUnlocked ? color.withValues(alpha: 0.4) : color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinTailPainter extends CustomPainter {
  final Color color;

  _PinTailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_PinTailPainter oldDelegate) => color != oldDelegate.color;
}
