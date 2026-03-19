import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:travel_buddy_mobile/core/theme/app_theme.dart';
import 'package:travel_buddy_mobile/l10n/app_localizations.dart';
import 'package:travel_buddy_mobile/shared/models/achievement.dart';

/// Full-screen achievement unlock celebration popup.
///
/// Shows a big trophy animation that scales in with glow + confetti,
/// then transitions to reveal the achievement details below it.
class AchievementUnlockPopup extends StatefulWidget {
  final Achievement achievement;

  const AchievementUnlockPopup({super.key, required this.achievement});

  /// Show the popup as a full-screen dialog. Returns when dismissed.
  static Future<void> show(BuildContext context, Achievement achievement) {
    HapticFeedback.heavyImpact();
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) =>
          AchievementUnlockPopup(achievement: achievement),
    );
  }

  @override
  State<AchievementUnlockPopup> createState() =>
      _AchievementUnlockPopupState();
}

class _AchievementUnlockPopupState extends State<AchievementUnlockPopup>
    with TickerProviderStateMixin {
  late final ConfettiController _confettiController;
  late final AnimationController _trophyController;
  late final AnimationController _detailsController;
  late final Animation<double> _trophyScale;
  late final Animation<double> _trophyGlow;

  bool _showDetails = false;

  @override
  void initState() {
    super.initState();

    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));

    // Trophy entrance: scale from 0 → 1.15 → 1.0 (overshoot bounce)
    _trophyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _trophyScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.15)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.15, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 40,
      ),
    ]).animate(_trophyController);

    _trophyGlow = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _trophyController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    // Details slide-up
    _detailsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _startSequence();
  }

  Future<void> _startSequence() async {
    // Start trophy animation
    _trophyController.forward();

    // Fire confetti slightly after trophy starts appearing
    await Future.delayed(const Duration(milliseconds: 300));
    _confettiController.play();

    // Show details after trophy lands
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() => _showDetails = true);
      _detailsController.forward();
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _trophyController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Color get _tierColor => switch (widget.achievement.tier) {
        AchievementTier.bronze => AppColors.bronze,
        AchievementTier.silver => AppColors.silver,
        AchievementTier.gold => AppColors.gold,
        AchievementTier.platinum => AppColors.platinum,
      };

  String get _tierEmoji => switch (widget.achievement.tier) {
        AchievementTier.bronze => '🥉',
        AchievementTier.silver => '🥈',
        AchievementTier.gold => '🥇',
        AchievementTier.platinum => '💎',
      };

  String _tierLabel(AppLocalizations l10n) =>
      switch (widget.achievement.tier) {
        AchievementTier.bronze => 'Bronze',
        AchievementTier.silver => 'Silver',
        AchievementTier.gold => 'Gold',
        AchievementTier.platinum => 'Platinum',
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final achievement = widget.achievement;
    final tierColor = _tierColor;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Main content
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── "Achievement Unlocked!" text ──
                    Text(
                      l10n.achievementUnlocked,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: tierColor,
                        letterSpacing: 2.0,
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 100.ms)
                        .slideY(begin: -0.3, duration: 400.ms),

                    const SizedBox(height: 24),

                    // ── Big Trophy ──
                    AnimatedBuilder(
                      animation: _trophyController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _trophyScale.value,
                          child: Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: tierColor.withValues(
                                      alpha: 0.4 * _trophyGlow.value),
                                  blurRadius: 40 * _trophyGlow.value,
                                  spreadRadius: 10 * _trophyGlow.value,
                                ),
                                BoxShadow(
                                  color: tierColor.withValues(
                                      alpha: 0.2 * _trophyGlow.value),
                                  blurRadius: 80 * _trophyGlow.value,
                                  spreadRadius: 20 * _trophyGlow.value,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                '🏆',
                                style: TextStyle(
                                  fontSize: 100,
                                  shadows: [
                                    Shadow(
                                      color: tierColor.withValues(
                                          alpha: 0.6 * _trophyGlow.value),
                                      blurRadius: 30 * _trophyGlow.value,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    // ── Achievement Details (revealed after trophy animation) ──
                    if (_showDetails)
                      FadeTransition(
                        opacity: _detailsController,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.3),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: _detailsController,
                            curve: Curves.easeOutCubic,
                          )),
                          child: Column(
                            children: [
                              // Achievement title
                              Text(
                                achievement.title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Description
                              Text(
                                achievement.description,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Tier badge + XP row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Tier chip
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: tierColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: tierColor.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(_tierEmoji,
                                            style:
                                                const TextStyle(fontSize: 14)),
                                        const SizedBox(width: 6),
                                        Text(
                                          _tierLabel(l10n),
                                          style: TextStyle(
                                            color: tierColor,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // XP reward
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.xpGreen
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(LucideIcons.sparkles,
                                            color: AppColors.xpGreen,
                                            size: 14),
                                        const SizedBox(width: 6),
                                        Text(
                                          '+${achievement.xpReward} XP',
                                          style: const TextStyle(
                                            color: AppColors.xpGreen,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 32),

                              // Dismiss button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: tierColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    l10n.awesome,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // ── Confetti — top center ──
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              blastDirection: pi / 2,
              particleDrag: 0.05,
              emissionFrequency: 0.06,
              numberOfParticles: 30,
              gravity: 0.08,
              shouldLoop: false,
              colors: [
                tierColor,
                AppColors.xpGreen,
                AppColors.gold,
                AppColors.primary,
                Colors.white,
              ],
            ),
          ),

          // ── Pulsing ring behind trophy ──
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: AnimatedBuilder(
                  animation: _trophyController,
                  builder: (context, _) {
                    if (_trophyGlow.value < 0.1) {
                      return const SizedBox.shrink();
                    }
                    return Container(
                      width: 200 + (60 * _trophyGlow.value),
                      height: 200 + (60 * _trophyGlow.value),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: tierColor
                              .withValues(alpha: 0.2 * _trophyGlow.value),
                          width: 2,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
