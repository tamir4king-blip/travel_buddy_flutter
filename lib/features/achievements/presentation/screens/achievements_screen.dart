import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:travel_buddy/core/theme/app_theme.dart';
import 'package:travel_buddy/l10n/registry_l10n.dart';
import 'package:travel_buddy/shared/models/achievement.dart';
import 'package:travel_buddy/shared/providers/achievements_provider.dart';
import 'package:travel_buddy/shared/providers/geolocation_provider.dart';
import 'package:travel_buddy/features/achievements/presentation/widgets/retroactive_claim_modal.dart';
import 'package:travel_buddy/features/achievements/presentation/widgets/master_achievements_section.dart';
import 'package:travel_buddy/features/achievements/presentation/widgets/achievement_location_card.dart';
import 'package:travel_buddy/shared/widgets/responsive_layout.dart';
import 'package:travel_buddy/shared/widgets/collection_complete_dialog.dart';
import 'package:travel_buddy/shared/widgets/visual_extras.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  static const _collectionOrder = ['beaches', 'landmarks', 'parks', 'culture'];

  static List<_CollectionFilter> _collections(AppLocalizations l10n) => [
    _CollectionFilter(id: null, label: l10n.tierAll, color: AppColors.primary, icon: LucideIcons.layoutGrid),
    _CollectionFilter(id: 'beaches', label: l10n.collectionBeaches, color: const Color(0xFF38BDF8), icon: LucideIcons.waves),
    _CollectionFilter(id: 'landmarks', label: l10n.collectionLandmarks, color: AppColors.accent, icon: LucideIcons.landmark),
    _CollectionFilter(id: 'parks', label: l10n.collectionParks, color: AppColors.xpGreen, icon: LucideIcons.trees),
    _CollectionFilter(id: 'culture', label: l10n.collectionCulture, color: AppColors.error, icon: LucideIcons.palette),
  ];

  static String _collectionTitle(AppLocalizations l10n, String collectionId) {
    return switch (collectionId) {
      'beaches' => l10n.collectionBeaches,
      'landmarks' => l10n.collectionLandmarks,
      'parks' => l10n.collectionParks,
      'culture' => l10n.collectionCulture,
      _ => collectionId,
    };
  }

  static Color _collectionColor(String collectionId) {
    return switch (collectionId) {
      'beaches' => const Color(0xFF38BDF8),
      'landmarks' => AppColors.accent,
      'parks' => AppColors.xpGreen,
      'culture' => AppColors.error,
      _ => AppColors.primary,
    };
  }

  static String _collectionEmoji(String collectionId) {
    return switch (collectionId) {
      'beaches' => '\u{1F3D6}',   // beach with umbrella
      'landmarks' => '\u{1F3DB}', // classical building
      'parks' => '\u{1F33F}',     // herb/leaf
      'culture' => '\u{1F3AD}',   // performing arts
      _ => '\u{1F4CD}',
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(achievementsProvider);
    final notifier = ref.read(achievementsProvider.notifier);
    final geo = ref.watch(geolocationProvider);
    final filtered = state.filteredAchievements;
    final completedCollections = state.completedCollections;

    final showGrouped = state.filterCollection == null && state.searchQuery.isEmpty;

    return SafeArea(
      child: ResponsiveLayout(
        child: AnimatedBackground(
          accentColor: AppColors.accent,
          child: CustomScrollView(
          slivers: [
            // ── Header section ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title with progress badge
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: GradientText(
                            text: l10n.achievements,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                            gradient: AppGradients.gradientPrimary,
                          ),
                        ),
                        GlowContainer(
                          glowColor: AppColors.primary,
                          borderRadius: 20,
                          pulse: false,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary.withValues(alpha: 0.15),
                                  AppColors.primaryLight.withValues(alpha: 0.08),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedCounter(
                                  value: state.totalUnlocked,
                                  style: TextStyle(
                                    color: AppColors.primaryLight,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  ' / ${state.totalAchievements}',
                                  style: TextStyle(
                                    color: AppColors.primaryLight,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.unlockedOfTotal(state.totalUnlocked, state.totalAchievements),
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: 22),
                    // ── Tier filters ──
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _TierChip(
                            label: l10n.tierAll,
                            color: AppColors.primary,
                            isSelected: state.filterTier == null,
                            onTap: () => notifier.setTierFilter(null),
                          ),
                          const SizedBox(width: 8),
                          _TierChip(
                            label: l10n.tierBronze,
                            color: AppColors.bronze,
                            isSelected: state.filterTier == AchievementTier.bronze,
                            onTap: () => notifier.setTierFilter(AchievementTier.bronze),
                          ),
                          const SizedBox(width: 8),
                          _TierChip(
                            label: l10n.tierSilver,
                            color: AppColors.silver,
                            isSelected: state.filterTier == AchievementTier.silver,
                            onTap: () => notifier.setTierFilter(AchievementTier.silver),
                          ),
                          const SizedBox(width: 8),
                          _TierChip(
                            label: l10n.tierGold,
                            color: AppColors.gold,
                            isSelected: state.filterTier == AchievementTier.gold,
                            onTap: () => notifier.setTierFilter(AchievementTier.gold),
                          ),
                          const SizedBox(width: 8),
                          _TierChip(
                            label: l10n.tierPlatinum,
                            color: AppColors.platinum,
                            isSelected: state.filterTier == AchievementTier.platinum,
                            onTap: () => notifier.setTierFilter(AchievementTier.platinum),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    // ── Collection filters ──
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _collections(l10n).map((collection) {
                          final isSelected = state.filterCollection == collection.id;
                          final isCollComplete = collection.id != null &&
                              completedCollections.contains(collection.id);
                          return Padding(
                            padding: const EdgeInsetsDirectional.only(end: 8),
                            child: _CollectionChip(
                              label: collection.label,
                              color: collection.color,
                              icon: collection.icon,
                              isSelected: isSelected,
                              isComplete: isCollComplete,
                              onTap: () => notifier.setCollectionFilter(collection.id),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 18),
                    // ── Search ──
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.bgCardLight.withValues(alpha: 0.5)),
                      ),
                      child: TextField(
                        onChanged: notifier.setSearchQuery,
                        decoration: InputDecoration(
                          hintText: l10n.searchAchievements,
                          prefixIcon: Icon(LucideIcons.search, size: 18, color: AppColors.textMuted),
                          filled: true,
                          fillColor: AppColors.bgCard.withValues(alpha: 0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            // ── Master Achievements Section ──
            const SliverToBoxAdapter(
              child: MasterAchievementsSection(),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
            // ── Achievement cards ──
            if (showGrouped)
              ..._buildGroupedSlivers(context, ref, state, notifier, geo, l10n)
            else
              ..._buildFlatSlivers(context, filtered, notifier, geo, l10n),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
        ),
      ),
    );
  }

  List<Widget> _buildGroupedSlivers(
    BuildContext context,
    WidgetRef ref,
    AchievementsState state,
    AchievementsNotifier notifier,
    GeolocationState geo,
    AppLocalizations l10n,
  ) {
    final slivers = <Widget>[];
    var animIndex = 0;

    for (final collectionId in _collectionOrder) {
      final achievements = state.filteredAchievements
          .where((a) => a.collectionId == collectionId)
          .toList();
      if (achievements.isEmpty) continue;

      final unlockedCount = achievements.where((a) => a.isUnlocked).length;
      final isComplete = state.completedCollections.contains(collectionId);
      final color = _collectionColor(collectionId);
      final progress = unlockedCount / achievements.length;

      // ── Collection section header ──
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.08),
                    AppColors.bgCard.withValues(alpha: 0.3),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: color.withValues(alpha: isComplete ? 0.4 : 0.12),
                ),
              ),
              child: Row(
                children: [
                  // Emoji icon
                  Text(
                    _collectionEmoji(collectionId),
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 14),
                  // Title + progress
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _collectionTitle(l10n, collectionId),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.2,
                              ),
                            ),
                            if (isComplete) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(LucideIcons.check, size: 12, color: AppColors.success),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Mini progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: AppColors.bgCardLight.withValues(alpha: 0.5),
                            valueColor: AlwaysStoppedAnimation(color),
                            minHeight: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Count badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: color.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      '$unlockedCount/${achievements.length}',
                      style: TextStyle(
                        fontSize: 13,
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // ── Achievement cards for this collection ──
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList.separated(
            itemCount: achievements.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final achievement = achievements[index];
              final distance = _getDistance(geo, achievement);
              return _buildCard(context, achievement, notifier, geo, animIndex++, distance);
            },
          ),
        ),
      );

      slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 28)));
    }

    return slivers;
  }

  List<Widget> _buildFlatSlivers(
    BuildContext context,
    List<Achievement> filtered,
    AchievementsNotifier notifier,
    GeolocationState geo,
    AppLocalizations l10n,
  ) {
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Icon(LucideIcons.mapPin, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                l10n.regularAchievements,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 14)),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverList.separated(
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final achievement = filtered[index];
            final distance = _getDistance(geo, achievement);
            return _buildCard(context, achievement, notifier, geo, index, distance);
          },
        ),
      ),
    ];
  }

  double? _getDistance(GeolocationState geo, Achievement achievement) {
    if (!geo.hasLocation) return null;
    if (achievement.latitude == null || achievement.longitude == null) return null;
    return geo.distanceTo(achievement.latitude!, achievement.longitude!);
  }

  Widget _buildCard(
    BuildContext context,
    Achievement achievement,
    AchievementsNotifier notifier,
    GeolocationState geo,
    int index,
    double? distance,
  ) {
    Widget card = ScaleTap(
      onTap: () => _onCardTap(context, achievement, notifier, geo),
      child: AchievementLocationCard(
        achievement: achievement,
        distanceMeters: distance,
        onTap: () => _onCardTap(context, achievement, notifier, geo),
      ),
    );

    if (!achievement.isUnlocked) {
      card = ShimmerOverlay(child: card);
    }

    return card.animate().fadeIn(duration: 350.ms, delay: (index * 50).ms).slideY(begin: 0.04);
  }

  void _onCardTap(
    BuildContext context,
    Achievement achievement,
    AchievementsNotifier notifier,
    GeolocationState geo,
  ) async {
    if (achievement.isUnlocked) {
      _showUnlockedDetail(context, achievement);
      return;
    }

    final result = await RetroactiveClaimModal.show(context, achievement);
    bool claimed;
    if (result == null) {
      claimed = notifier.claimAchievement(
        achievement.id,
        userLat: geo.latitude,
        userLng: geo.longitude,
      );
    } else {
      claimed = notifier.claimAchievement(
        achievement.id,
        retroactiveData: result,
      );
    }
    if (claimed && context.mounted) {
      final completedCollection = notifier.lastCompletedCollection;
      if (completedCollection != null) {
        notifier.clearLastCompletedCollection();
        await CollectionCompleteDialog.show(context, completedCollection);
      }
    }
  }

  void _showUnlockedDetail(BuildContext context, Achievement achievement) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);

    final tierColor = switch (achievement.tier) {
      AchievementTier.bronze => AppColors.bronze,
      AchievementTier.silver => AppColors.silver,
      AchievementTier.gold => AppColors.gold,
      AchievementTier.platinum => AppColors.platinum,
    };

    final tierLabel = switch (achievement.tier) {
      AchievementTier.bronze => 'BRONZE',
      AchievementTier.silver => 'SILVER',
      AchievementTier.gold => 'GOLD',
      AchievementTier.platinum => 'PLATINUM',
    };

    final collectionEmoji = switch (achievement.collectionId) {
      'beaches' => '\u{1F30A}',
      'landmarks' => '\u{1F3DB}',
      'parks' => '\u{1F333}',
      'culture' => '\u{1F3AD}',
      _ => '\u{1F4CD}',
    };

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            // Emoji + checkmark
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Text(collectionEmoji, style: const TextStyle(fontSize: 48)),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.bgCard, width: 2),
                  ),
                  child: const Icon(LucideIcons.check, size: 12, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Title
            Text(
              RegistryL10n.achievementTitle(locale, achievement.id, achievement.title),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            // Description
            Text(
              RegistryL10n.achievementDescription(locale, achievement.id, achievement.description),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            // Tier + XP row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: tierColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: tierColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    tierLabel,
                    style: TextStyle(
                      color: tierColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.xpGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.xpGreen.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.zap, size: 12, color: AppColors.xpGreen),
                      const SizedBox(width: 4),
                      Text(
                        '+${achievement.xpReward} XP',
                        style: TextStyle(
                          color: AppColors.xpGreen,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Unlocked date
            if (achievement.unlockedAt != null) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.calendarCheck, size: 14, color: AppColors.success.withValues(alpha: 0.7)),
                  const SizedBox(width: 6),
                  Text(
                    l10n.unlockedOn(
                      DateFormat.yMMMd(locale.languageCode).format(achievement.unlockedAt!),
                    ),
                    style: TextStyle(
                      color: AppColors.success.withValues(alpha: 0.8),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
            // Notes if retroactive
            if (achievement.notes != null && achievement.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.bgCardLight.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  achievement.notes!,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Tier filter chip ──
class _TierChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _TierChip({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleTap(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.2),
                    color.withValues(alpha: 0.1),
                  ],
                )
              : null,
          color: isSelected ? null : AppColors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.5)
                : AppColors.bgCardLight.withValues(alpha: 0.5),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _CollectionFilter {
  final String? id;
  final String label;
  final Color color;
  final IconData icon;

  const _CollectionFilter({
    required this.id,
    required this.label,
    required this.color,
    required this.icon,
  });
}

// ── Collection filter chip ──
class _CollectionChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final bool isSelected;
  final bool isComplete;
  final VoidCallback onTap;

  const _CollectionChip({
    required this.label,
    required this.color,
    required this.icon,
    required this.isSelected,
    this.isComplete = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleTap(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.18),
                    color.withValues(alpha: 0.08),
                  ],
                )
              : null,
          color: isSelected ? null : AppColors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.4)
                : AppColors.bgCardLight.withValues(alpha: 0.5),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isComplete) ...[
              Icon(LucideIcons.checkCircle, size: 14, color: color),
              const SizedBox(width: 5),
            ] else ...[
              Icon(icon, size: 14, color: isSelected ? color : AppColors.textMuted),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
