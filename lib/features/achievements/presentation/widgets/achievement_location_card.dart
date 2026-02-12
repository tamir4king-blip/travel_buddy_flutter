import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:travel_buddy/core/theme/app_theme.dart';
import 'package:travel_buddy/l10n/registry_l10n.dart';
import 'package:travel_buddy/shared/models/achievement.dart';

class AchievementLocationCard extends StatelessWidget {
  final Achievement achievement;
  final double? distanceMeters;
  final VoidCallback onTap;

  const AchievementLocationCard({
    super.key,
    required this.achievement,
    this.distanceMeters,
    required this.onTap,
  });

  Color get _tierColor => switch (achievement.tier) {
        AchievementTier.bronze => AppColors.bronze,
        AchievementTier.silver => AppColors.silver,
        AchievementTier.gold => AppColors.gold,
        AchievementTier.platinum => AppColors.platinum,
      };

  // Rich gradients per tier — atmospheric, not flat
  List<Color> get _tierGradient => switch (achievement.tier) {
        AchievementTier.bronze => [
            const Color(0xFF5C3A1E),
            const Color(0xFFB87333),
            const Color(0xFF8B5E3C),
          ],
        AchievementTier.silver => [
            const Color(0xFF3A4A5C),
            const Color(0xFF7A8EA0),
            const Color(0xFF5A6E80),
          ],
        AchievementTier.gold => [
            const Color(0xFF6B4F00),
            const Color(0xFFE6B422),
            const Color(0xFF8B6914),
          ],
        AchievementTier.platinum => [
            const Color(0xFF0F766E),
            const Color(0xFFD4CFC9),
            const Color(0xFF2DD4BF),
          ],
      };

  // Collection-specific emoji for visual flavor
  String get _collectionEmoji => switch (achievement.collectionId) {
        'beaches' => '\u{1F30A}',   // wave
        'landmarks' => '\u{1F3DB}', // classical building
        'parks' => '\u{1F333}',     // deciduous tree
        'culture' => '\u{1F3AD}',   // performing arts
        _ => '\u{1F4CD}',           // pin
      };

  IconData get _collectionIcon => switch (achievement.collectionId) {
        'beaches' => LucideIcons.waves,
        'landmarks' => LucideIcons.landmark,
        'parks' => LucideIcons.trees,
        'culture' => LucideIcons.palette,
        _ => LucideIcons.mapPin,
      };

  String _tierLabel() => switch (achievement.tier) {
        AchievementTier.bronze => 'BRONZE',
        AchievementTier.silver => 'SILVER',
        AchievementTier.gold => 'GOLD',
        AchievementTier.platinum => 'PLATINUM',
      };

  String _formatDistance(BuildContext context, double meters) {
    final l10n = AppLocalizations.of(context)!;
    if (meters >= 1000) {
      final km = (meters / 1000).toStringAsFixed(1);
      return l10n.kmAway(km);
    }
    return l10n.mAway(meters.round().toString());
  }

  String _formatDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context);
    return DateFormat.yMMMd(locale.languageCode).format(date);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final isUnlocked = achievement.isUnlocked;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isUnlocked
                ? _tierColor.withValues(alpha: 0.5)
                : AppColors.bgCardLight.withValues(alpha: 0.4),
            width: isUnlocked ? 1.5 : 1,
          ),
          boxShadow: isUnlocked
              ? [
                  BoxShadow(
                    color: _tierColor.withValues(alpha: 0.12),
                    blurRadius: 20,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Top section: tier gradient header ──
            Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
              decoration: BoxDecoration(
                gradient: isUnlocked
                    ? LinearGradient(
                        colors: _tierGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        stops: const [0.0, 0.5, 1.0],
                      )
                    : LinearGradient(
                        colors: [
                          AppColors.bgCardLight.withValues(alpha: 0.7),
                          AppColors.bgCard,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
              ),
              child: Row(
                children: [
                  // Location emoji stamp
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: isUnlocked
                          ? Colors.white.withValues(alpha: 0.18)
                          : AppColors.bgDark.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: isUnlocked
                            ? Colors.white.withValues(alpha: 0.2)
                            : AppColors.textMuted.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Center(
                      child: isUnlocked
                          ? Text(
                              _collectionEmoji,
                              style: const TextStyle(fontSize: 22),
                            )
                          : Icon(
                              _collectionIcon,
                              color: AppColors.textMuted.withValues(alpha: 0.6),
                              size: 20,
                            ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Tier badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: isUnlocked
                          ? Colors.black.withValues(alpha: 0.2)
                          : _tierColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isUnlocked
                            ? Colors.white.withValues(alpha: 0.15)
                            : _tierColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      _tierLabel(),
                      style: TextStyle(
                        color: isUnlocked
                            ? Colors.white.withValues(alpha: 0.9)
                            : _tierColor.withValues(alpha: 0.8),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // XP reward — glowing pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isUnlocked
                            ? [
                                AppColors.xpGreen.withValues(alpha: 0.3),
                                AppColors.xpGlow.withValues(alpha: 0.15),
                              ]
                            : [
                                AppColors.xpGreen.withValues(alpha: 0.1),
                                AppColors.xpGreen.withValues(alpha: 0.05),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.xpGreen.withValues(alpha: isUnlocked ? 0.4 : 0.15),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.zap,
                          size: 12,
                          color: isUnlocked
                              ? AppColors.xpGlow
                              : AppColors.xpGreen.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '+${achievement.xpReward}',
                          style: TextStyle(
                            color: isUnlocked
                                ? AppColors.xpGlow
                                : AppColors.xpGreen.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // ── Bottom section: details ──
            Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                // subtle inner shadow for depth
                border: Border(
                  top: BorderSide(
                    color: isUnlocked
                        ? _tierColor.withValues(alpha: 0.15)
                        : AppColors.bgCardLight.withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + unlock indicator
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          RegistryL10n.achievementTitle(
                            locale, achievement.id, achievement.title,
                          ),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            letterSpacing: -0.2,
                            color: isUnlocked
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (isUnlocked)
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.success.withValues(alpha: 0.2),
                                AppColors.success.withValues(alpha: 0.08),
                              ],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.success.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Icon(
                            LucideIcons.check,
                            color: AppColors.success,
                            size: 16,
                          ),
                        )
                      else
                        Transform.rotate(
                          angle: -0.15,
                          child: Icon(
                            LucideIcons.lock,
                            color: AppColors.textMuted.withValues(alpha: 0.4),
                            size: 16,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Description
                  Text(
                    RegistryL10n.achievementDescription(
                      locale, achievement.id, achievement.description,
                    ),
                    style: TextStyle(
                      color: AppColors.textMuted.withValues(alpha: 0.9),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // ── Footer: distance + status ──
                  Row(
                    children: [
                      // Distance pill
                      if (distanceMeters != null && !isUnlocked) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.navigation,
                                size: 12,
                                color: AppColors.primaryLight,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _formatDistance(context, distanceMeters!),
                                style: TextStyle(
                                  color: AppColors.primaryLight,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                      ] else ...[
                        const Spacer(),
                      ],
                      // Status label
                      if (isUnlocked && achievement.unlockedAt != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.calendarCheck,
                              size: 12,
                              color: AppColors.success.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              l10n.unlockedOn(_formatDate(context, achievement.unlockedAt!)),
                              style: TextStyle(
                                color: AppColors.success.withValues(alpha: 0.8),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.accent.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.footprints,
                                size: 12,
                                color: AppColors.accent.withValues(alpha: 0.8),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                l10n.visitToUnlock,
                                style: TextStyle(
                                  color: AppColors.accent.withValues(alpha: 0.9),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
