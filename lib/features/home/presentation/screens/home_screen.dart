import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:travel_buddy_mobile/l10n/app_localizations.dart';
import 'package:travel_buddy_mobile/core/theme/app_theme.dart';
import 'package:travel_buddy_mobile/shared/models/user_profile.dart';
import 'package:travel_buddy_mobile/shared/providers/achievements_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/quest_chain_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/quests_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/user_profile_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/skills_provider.dart';
import 'package:travel_buddy_mobile/shared/data/skill_registry.dart';
import 'package:travel_buddy_mobile/shared/widgets/directional_icon.dart';
import 'package:travel_buddy_mobile/shared/widgets/xp_progress_bar.dart';
import 'package:travel_buddy_mobile/shared/widgets/responsive_layout.dart';
import 'package:travel_buddy_mobile/shared/widgets/visual_extras.dart';
import 'package:travel_buddy_mobile/features/profile/presentation/widgets/profile_avatar.dart';
import 'package:travel_buddy_mobile/shared/models/achievement.dart';
import 'package:travel_buddy_mobile/shared/models/quest.dart';
import 'package:travel_buddy_mobile/shared/models/side_quest.dart';
import 'package:travel_buddy_mobile/features/achievements/presentation/widgets/achievement_detail_sheet.dart';
import 'package:travel_buddy_mobile/shared/providers/geolocation_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/zone_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/zone_content_provider.dart';
import 'package:travel_buddy_mobile/shared/widgets/achievement_unlock_popup.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  late final AnimationController _staggerController;

  // Interval-based animations for each section
  late final Animation<double> _profileFade;
  late final Animation<Offset> _profileSlide;
  late final Animation<double> _adventureFade;
  late final Animation<Offset> _adventureSlide;
  late final Animation<double> _collectionsFade;
  late final Animation<Offset> _collectionsSlide;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _profileFade = _buildFade(0.0, 0.35);
    _profileSlide = _buildSlide(0.0, 0.35);
    _adventureFade = _buildFade(0.25, 0.60);
    _adventureSlide = _buildSlide(0.25, 0.60);
    _collectionsFade = _buildFade(0.45, 0.80);
    _collectionsSlide = _buildSlide(0.45, 0.80);

    _staggerController.forward();
  }

  Animation<double> _buildFade(double begin, double end) {
    return CurvedAnimation(
      parent: _staggerController,
      curve: Interval(begin, end, curve: Curves.easeOut),
    );
  }

  Animation<Offset> _buildSlide(double begin, double end) {
    return Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _staggerController,
      curve: Interval(begin, end, curve: Curves.easeOut),
    ));
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(userProfileProvider);
    final achievements = ref.watch(achievementsProvider);
    final quests = ref.watch(questsProvider);

    final skills = ref.watch(skillsProvider);
    final gridCols = ResponsiveLayout.gridColumns(context, mobile: 2, tablet: 3, desktop: 4);
    final isComplete = achievements.completedCollections;

    return SafeArea(
      child: ResponsiveLayout(
        child: AnimatedBackground(
          accentColor: AppColors.primary,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Unified Profile Unit ──
                      FadeTransition(
                        opacity: _profileFade,
                        child: SlideTransition(
                          position: _profileSlide,
                          child: _ProfileUnit(
                            user: user,
                            currentTotalLevel: quests.skillLevels.values.fold(0, (a, b) => a + b),
                            maxTotalLevel: skillRegistry.fold<int>(0, (sum, g) => sum + g.maxLevel),
                            unlockedAchievements: achievements.totalUnlocked,
                            totalAchievements: achievements.totalAchievements,
                            completedQuests: quests.completedCount,
                            totalQuests: quests.allQuests.length,
                            streakDays: quests.currentStreak,
                            onAvatarTap: () => context.go('/profile'),
                            onSkillsTap: () => context.go('/skills'),
                            onAchievementsTap: () => context.go('/achievements'),
                            onQuestsTap: () => context.go('/quests'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Pending Trophy Claims ──
                      _HomePendingClaims(),

                      const SizedBox(height: 12),

                      // ── Pending Quest Chain Claims ──
                      const _HomeQuestChainClaims(),

                      const SizedBox(height: 20),

                      // ── Nearby Zone Card ──
                      const _NearbyZoneCard(),

                      const SizedBox(height: 20),

                      // ── Your Stats Section ──
                      FadeTransition(
                        opacity: _adventureFade,
                        child: SlideTransition(
                          position: _adventureSlide,
                          child: _StatsSection(
                            quests: quests,
                            skills: skills,
                            achievements: achievements,
                            onSkillsTap: () => context.go('/skills'),
                            onAchievementsTap: () => context.go('/achievements'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 36),

                      // ── Collections Section ──
                      FadeTransition(
                        opacity: _collectionsFade,
                        child: SlideTransition(
                          position: _collectionsSlide,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionHeader(title: l10n.yourCollections),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _collectionsFade,
                  child: SlideTransition(
                    position: _collectionsSlide,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _CollectionsTabSection(
                        achievements: achievements,
                        completedCollections: isComplete,
                        gridCols: gridCols,
                      ),
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Section Header with Gradient Accent Bar ─────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 3,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.cyan],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
        ),
      ],
    );
  }
}

// ─── Unified Profile Unit ───────────────────────────────────────────────────

class _ProfileUnit extends StatelessWidget {
  final UserProfile user;
  final int currentTotalLevel;
  final int maxTotalLevel;
  final int unlockedAchievements;
  final int totalAchievements;
  final int completedQuests;
  final int totalQuests;
  final int streakDays;
  final VoidCallback onAvatarTap;
  final VoidCallback onSkillsTap;
  final VoidCallback onAchievementsTap;
  final VoidCallback onQuestsTap;

  const _ProfileUnit({
    required this.user,
    required this.currentTotalLevel,
    required this.maxTotalLevel,
    required this.unlockedAchievements,
    required this.totalAchievements,
    required this.completedQuests,
    required this.totalQuests,
    required this.streakDays,
    required this.onAvatarTap,
    required this.onSkillsTap,
    required this.onAchievementsTap,
    required this.onQuestsTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final xpInLevel = user.totalXp % 200;
    final xpNeeded = 200 - xpInLevel;
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F766E),  // teal-700
            Color(0xFF0D9488),  // teal-600
            Color(0xFF115E59),  // teal-800
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative background trophy icon
          Positioned(
            right: -8,
            top: 10,
            child: Icon(
              LucideIcons.trophy,
              size: 90,
              color: Colors.white.withValues(alpha: 0.04),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Avatar row: greeting + avatar ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GradientText(
                            text: l10n.welcomeBack,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFBBF24), Color(0xFFF472B6)],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user.displayName,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                  color: Colors.white,
                                ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: onAvatarTap,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [AppColors.primary, AppColors.cyan],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF115E59),
                              ),
                              child: ProfileAvatar(
                                avatarUrl: user.avatarUrl,
                                displayName: user.displayName,
                                radius: 26,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              l10n.levelN(user.level),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // ── XP progress ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.xpToNextLevel(xpNeeded),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    ShimmerOverlay(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.zap, size: 13, color: AppColors.xpGlow),
                            const SizedBox(width: 4),
                            AnimatedCounter(
                              value: user.totalXp,
                              suffix: ' XP',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      '${user.level}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: XpProgressBar(current: xpInLevel, max: 200)),
                    const SizedBox(width: 8),
                    Text(
                      '${user.level + 1}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // ── Divider ──
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.white.withValues(alpha: 0.15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Progress stats row ──
                Row(
                  children: [
                    Expanded(
                      child: _ProfileStatTile(
                        label: l10n.totalSkillLevel,
                        value: '$currentTotalLevel/$maxTotalLevel',
                        icon: LucideIcons.brain,
                        color: AppColors.xpGlow,
                        onTap: onSkillsTap,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 36,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    Expanded(
                      child: _ProfileStatTile(
                        label: l10n.achievements,
                        value: '$unlockedAchievements/$totalAchievements',
                        icon: LucideIcons.trophy,
                        color: AppColors.purple,
                        onTap: onAchievementsTap,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 36,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    Expanded(
                      child: _ProfileStatTile(
                        label: l10n.quests,
                        value: '$completedQuests/$totalQuests',
                        icon: LucideIcons.swords,
                        color: AppColors.accent,
                        onTap: onQuestsTap,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ProfileStatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── Stats Section ──────────────────────────────────────────────────────────

class _StatsSection extends StatelessWidget {
  final QuestsState quests;
  final SkillsState skills;
  final AchievementsState achievements;
  final VoidCallback onSkillsTap;
  final VoidCallback onAchievementsTap;

  const _StatsSection({
    required this.quests,
    required this.skills,
    required this.achievements,
    required this.onSkillsTap,
    required this.onAchievementsTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Get top skills sorted by level (descending), take top 4
    final topSkillEntries = quests.skillLevels.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topSkills = topSkillEntries.take(4).toList();

    // Group achievements by country using id prefix patterns
    // Local Netanya achievements: collectionId in [beaches, landmarks, parks, culture]
    // Travel achievements: collectionId in [europe, americas, national-parks, ski-resorts, ...]
    final localCollections = {'beaches', 'landmarks', 'parks', 'culture'};
    final localAll = achievements.allAchievements
        .where((a) => localCollections.contains(a.collectionId))
        .toList();
    final localUnlocked = localAll.where((a) => a.isUnlocked).length;

    // Country achievements grouped by collectionId
    final countryGroups = <String, ({int unlocked, int total})>{};
    for (final a in achievements.allAchievements) {
      if (localCollections.contains(a.collectionId)) continue;
      if (a.collectionId == null) continue;
      final group = countryGroups[a.collectionId!] ??
          (unlocked: 0, total: 0);
      countryGroups[a.collectionId!] = (
        unlocked: group.unlocked + (a.isUnlocked ? 1 : 0),
        total: group.total + 1,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Top Skills ──
        _SectionHeader(title: l10n.topSkills),
        const SizedBox(height: 16),
        if (topSkills.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.bgCardLight.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.brain, color: AppColors.textMuted, size: 24),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    l10n.noSkillsYet,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ),
              ],
            ),
          )
        else
          ...topSkills.map((entry) {
            final skill = skills.getSkillById(entry.key);
            if (skill == null) return const SizedBox.shrink();
            final level = entry.value;
            final xp = quests.skillXp[entry.key] ?? 0;
            final xpInLevel = xp % skill.xpPerLevel;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SkillRow(
                icon: skill.icon,
                name: skill.name,
                level: level,
                xpProgress: xpInLevel / skill.xpPerLevel,
                gradientStart: _parseColor(skill.gradientStart),
                gradientEnd: _parseColor(skill.gradientEnd),
                onTap: onSkillsTap,
              ),
            );
          }),
        if (topSkills.isNotEmpty) ...[
          const SizedBox(height: 4),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: GestureDetector(
              onTap: onSkillsTap,
              child: Text(
                l10n.seeAll,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 28),

        // ── Achievement Breakdown ──
        _SectionHeader(title: l10n.achievements),
        const SizedBox(height: 16),

        // Local (Netanya) summary
        _AchievementGroupRow(
          emoji: '\u{1F3D9}\u{FE0F}',
          label: 'Netanya',
          unlocked: localUnlocked,
          total: localAll.length,
          color: AppColors.primary,
          onTap: onAchievementsTap,
        ),

        // Country-based groups
        ..._buildCountryRows(countryGroups, l10n, onAchievementsTap),
      ],
    );
  }

  List<Widget> _buildCountryRows(
    Map<String, ({int unlocked, int total})> groups,
    AppLocalizations l10n,
    VoidCallback onTap,
  ) {
    const collectionMeta = <String, ({String emoji, String label, Color color})>{
      'europe': (emoji: '\u{1F1EA}\u{1F1FA}', label: 'Europe', color: Color(0xFF3B82F6)),
      'americas': (emoji: '\u{1F30E}', label: 'Americas', color: Color(0xFFF59E0B)),
      'national-parks': (emoji: '\u{1F332}', label: 'National Parks', color: Color(0xFF10B981)),
      'ski-resorts': (emoji: '\u{26F7}\u{FE0F}', label: 'Ski Resorts', color: Color(0xFF8B5CF6)),
      'capitals': (emoji: '\u{1F3DB}\u{FE0F}', label: 'Capitals', color: Color(0xFFEF4444)),
      'ancient-sites': (emoji: '\u{1F3DB}\u{FE0F}', label: 'Ancient Sites', color: Color(0xFFB45309)),
      'holy-sites': (emoji: '\u{1F6D0}', label: 'Holy Sites', color: Color(0xFFB07A2E)),
      'seas': (emoji: '\u{1F30A}', label: 'Seas', color: Color(0xFF0277BD)),
      'tourist-destinations': (emoji: '\u{2B50}', label: 'Top Destinations', color: Color(0xFFEC4899)),
    };

    final rows = <Widget>[];
    for (final entry in groups.entries) {
      final meta = collectionMeta[entry.key];
      if (meta == null) continue;
      rows.add(_AchievementGroupRow(
        emoji: meta.emoji,
        label: meta.label,
        unlocked: entry.value.unlocked,
        total: entry.value.total,
        color: meta.color,
        onTap: onTap,
      ));
    }
    return rows;
  }

  static Color _parseColor(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }
}

class _SkillRow extends StatelessWidget {
  final String icon;
  final String name;
  final int level;
  final double xpProgress;
  final Color gradientStart;
  final Color gradientEnd;
  final VoidCallback? onTap;

  const _SkillRow({
    required this.icon,
    required this.name,
    required this.level,
    required this.xpProgress,
    required this.gradientStart,
    required this.gradientEnd,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: gradientStart.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [gradientStart, gradientEnd],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Lv.$level',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: xpProgress,
                      backgroundColor: AppColors.bgCardLight.withValues(alpha: 0.5),
                      valueColor: AlwaysStoppedAnimation(gradientStart),
                      minHeight: 4,
                    ),
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

class _AchievementGroupRow extends StatelessWidget {
  final String emoji;
  final String label;
  final int unlocked;
  final int total;
  final Color color;
  final VoidCallback? onTap;

  const _AchievementGroupRow({
    required this.emoji,
    required this.label,
    required this.unlocked,
    required this.total,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? unlocked / total : 0.0;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '$unlocked / $total',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
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
              const SizedBox(width: 10),
              DirectionalChevron(color: AppColors.textMuted, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Collection Card ────────────────────────────────────────────────────────

class _CollectionCard extends StatelessWidget {
  final String title;
  final String emoji;
  final int progress;
  final int total;
  final IconData icon;
  final Color color;
  final bool isComplete;
  final VoidCallback? onTap;

  const _CollectionCard({
    required this.title,
    required this.emoji,
    required this.progress,
    required this.total,
    required this.icon,
    required this.color,
    this.isComplete = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    Widget card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.06),
            AppColors.bgCard,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isComplete
              ? color.withValues(alpha: 0.4)
              : color.withValues(alpha: 0.1),
          width: isComplete ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 30)),
              if (isComplete)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    l10n.complete,
                    style: TextStyle(
                      color: color,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress / total,
                  backgroundColor: AppColors.bgCardLight.withValues(alpha: 0.5),
                  valueColor: AlwaysStoppedAnimation(color),
                  minHeight: 5,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '$progress / $total',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );

    // Shimmer effect on completed collection cards
    if (isComplete) {
      card = ShimmerOverlay(child: card);
    }

    // Pulsing glow on incomplete collections with progress
    if (!isComplete && progress > 0) {
      card = GlowContainer(
        glowColor: color,
        borderRadius: 18,
        child: card,
      );
    }

    return ScaleTap(
      onTap: onTap,
      child: card,
    );
  }
}

// ─── Tabbed Collections Section ─────────────────────────────────────────────

class _CollectionsTabSection extends StatefulWidget {
  final AchievementsState achievements;
  final Set<String> completedCollections;
  final int gridCols;

  const _CollectionsTabSection({
    required this.achievements,
    required this.completedCollections,
    required this.gridCols,
  });

  @override
  State<_CollectionsTabSection> createState() => _CollectionsTabSectionState();
}

class _CollectionsTabSectionState extends State<_CollectionsTabSection> {
  int _selectedTab = 0;

  int _countByCollection(String collectionId) {
    return widget.achievements.unlockedAchievements
        .where((a) => a.collectionId == collectionId)
        .length;
  }

  int _totalByCollection(String collectionId) {
    final count = widget.achievements.allAchievements
        .where((a) => a.collectionId == collectionId)
        .length;
    return count > 0 ? count : 1;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tab bar
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.bgCardLight.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              _buildTab(0, AppLocalizations.of(context)!.tabCountriesHome, LucideIcons.globe2),
              _buildTab(1, AppLocalizations.of(context)!.tabCollectionsHome, LucideIcons.layoutGrid),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Content
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: _selectedTab == 0
              ? _buildCountriesContent()
              : _buildCollectionsContent(),
        ),
      ],
    );
  }

  Widget _buildTab(int index, String label, IconData icon) {
    final isActive = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isActive ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isActive ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountriesContent() {
    return Container(
      key: const ValueKey('countries'),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF0A1628),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF1E3A5F).withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Globe background — positioned right, extending beyond card
          Positioned(
            right: -50,
            top: -20,
            bottom: -20,
            width: 340,
            child: Opacity(
              opacity: 0.38,
              child: CustomPaint(
                painter: _GlobePainter(),
                size: Size.infinite,
              ),
            ),
          ),
          // Gradient overlay for text readability
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF0A1628),
                    const Color(0xFF0A1628).withValues(alpha: 0.88),
                    const Color(0xFF0A1628).withValues(alpha: 0.35),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                        ),
                      ),
                      child: const Icon(LucideIcons.globe2, color: Color(0xFF38BDF8), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.exploreTheWorld,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            AppLocalizations.of(context)!.trackTravelsAcrossContinents,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                // Continent rows
                _ContinentRow(
                  name: AppLocalizations.of(context)!.continentEurope,
                  emoji: '\u{1F1EA}\u{1F1FA}',
                  progress: _countByCollection('europe'),
                  total: _totalByCollection('europe'),
                  color: const Color(0xFF3B82F6),
                  onTap: () => context.go('/achievements'),
                ),
                _ContinentRow(
                  name: AppLocalizations.of(context)!.continentAmericas,
                  emoji: '\u{1F30E}',
                  progress: _countByCollection('americas'),
                  total: _totalByCollection('americas'),
                  color: const Color(0xFFF59E0B),
                  onTap: () => context.go('/achievements'),
                ),
                _ContinentRow(
                  name: AppLocalizations.of(context)!.continentAsia,
                  emoji: '\u{1F30F}',
                  progress: 0,
                  total: 0,
                  color: const Color(0xFFEF4444),
                  comingSoon: true,
                ),
                _ContinentRow(
                  name: AppLocalizations.of(context)!.continentAfrica,
                  emoji: '\u{1F30D}',
                  progress: 0,
                  total: 0,
                  color: const Color(0xFF10B981),
                  comingSoon: true,
                ),
                _ContinentRow(
                  name: AppLocalizations.of(context)!.continentOceania,
                  emoji: '\u{1F3DD}\u{FE0F}',
                  progress: 0,
                  total: 0,
                  color: const Color(0xFF06B6D4),
                  comingSoon: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionsContent() {
    final l10n = AppLocalizations.of(context)!;
    return GridView.count(
      key: const ValueKey('collections'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: widget.gridCols,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: [
        _CollectionCard(
          title: l10n.collectionBeaches,
          emoji: '\u{1F3D6}',
          progress: _countByCollection('beaches'),
          total: _totalByCollection('beaches'),
          icon: LucideIcons.waves,
          color: const Color(0xFF38BDF8),
          isComplete: widget.completedCollections.contains('beaches'),
          onTap: () => context.go('/achievements'),
        ),
        _CollectionCard(
          title: l10n.collectionLandmarks,
          emoji: '\u{1F3DB}',
          progress: _countByCollection('landmarks'),
          total: _totalByCollection('landmarks'),
          icon: LucideIcons.landmark,
          color: AppColors.accent,
          isComplete: widget.completedCollections.contains('landmarks'),
          onTap: () => context.go('/achievements'),
        ),
        _CollectionCard(
          title: l10n.collectionParks,
          emoji: '\u{1F33F}',
          progress: _countByCollection('parks'),
          total: _totalByCollection('parks'),
          icon: LucideIcons.trees,
          color: AppColors.xpGreen,
          isComplete: widget.completedCollections.contains('parks'),
          onTap: () => context.go('/achievements'),
        ),
        _CollectionCard(
          title: l10n.collectionCulture,
          emoji: '\u{1F3AD}',
          progress: _countByCollection('culture'),
          total: _totalByCollection('culture'),
          icon: LucideIcons.palette,
          color: AppColors.error,
          isComplete: widget.completedCollections.contains('culture'),
          onTap: () => context.go('/achievements'),
        ),
        _CollectionCard(
          title: l10n.collectionNationalParks,
          emoji: '\u{1F332}',
          progress: _countByCollection('national-parks'),
          total: _totalByCollection('national-parks'),
          icon: LucideIcons.mountain,
          color: const Color(0xFF10B981),
          isComplete: widget.completedCollections.contains('national-parks'),
          onTap: () => context.go('/achievements'),
        ),
        _CollectionCard(
          title: l10n.collectionSkiResorts,
          emoji: '\u{26F7}',
          progress: _countByCollection('ski-resorts'),
          total: _totalByCollection('ski-resorts'),
          icon: LucideIcons.snowflake,
          color: const Color(0xFF8B5CF6),
          isComplete: widget.completedCollections.contains('ski-resorts'),
          onTap: () => context.go('/achievements'),
        ),
      ],
    );
  }
}

// ─── Continent Row ──────────────────────────────────────────────────────────

class _ContinentRow extends StatelessWidget {
  final String name;
  final String emoji;
  final int progress;
  final int total;
  final Color color;
  final bool comingSoon;
  final VoidCallback? onTap;

  const _ContinentRow({
    required this.name,
    required this.emoji,
    required this.progress,
    required this.total,
    required this.color,
    this.comingSoon = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: comingSoon ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: comingSoon
                          ? AppColors.textMuted
                          : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 5),
                  if (comingSoon)
                    Text(
                      AppLocalizations.of(context)!.comingSoon,
                      style: TextStyle(
                        color: AppColors.textMuted.withValues(alpha: 0.7),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  else
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: total > 0 ? progress / total : 0,
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        valueColor: AlwaysStoppedAnimation(color),
                        minHeight: 4,
                      ),
                    ),
                ],
              ),
            ),
            if (!comingSoon) ...[
              const SizedBox(width: 12),
              Text(
                '$progress / $total',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              DirectionalChevron(color: AppColors.textMuted, size: 16),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Globe Custom Painter ───────────────────────────────────────────────────

class _GlobePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(cx, cy) * 0.88;
    final center = Offset(cx, cy);

    // Clip to sphere
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: r)));

    // Ocean sphere — radial gradient for 3D depth
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(cx - r * 0.35, cy - r * 0.35),
          r * 1.4,
          const [
            Color(0xFF2196F3), // bright blue (light spot)
            Color(0xFF1565C0), // medium ocean
            Color(0xFF0D47A1), // deep blue
            Color(0xFF062B6E), // dark edge
          ],
          const [0.0, 0.3, 0.6, 1.0],
        ),
    );

    // Continent-like land masses — subtle green/teal blobs
    final landPaint = Paint()..color = const Color(0xFF2E7D32).withValues(alpha: 0.28);
    // Europe
    _drawLand(canvas, center, r, 0.08, -0.2, 0.2, 0.15, landPaint);
    // Africa
    _drawLand(canvas, center, r, 0.12, 0.15, 0.16, 0.28, landPaint);
    // Asia
    _drawLand(canvas, center, r, 0.38, -0.12, 0.28, 0.24, landPaint);
    // North America
    _drawLand(canvas, center, r, -0.38, -0.22, 0.2, 0.22, landPaint);
    // South America
    _drawLand(canvas, center, r, -0.28, 0.18, 0.14, 0.28, landPaint);
    // Australia
    _drawLand(canvas, center, r, 0.42, 0.32, 0.14, 0.1, landPaint);

    // Latitude grid lines
    final gridPaint = Paint()
      ..color = const Color(0x14FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;
    for (var i = 1; i < 7; i++) {
      final ratio = (i / 7) * 2 - 1;
      final y = cy + ratio * r;
      final hw = math.sqrt(math.max(0, r * r - (y - cy) * (y - cy)));
      canvas.drawLine(Offset(cx - hw, y), Offset(cx + hw, y), gridPaint);
    }

    // Longitude grid lines (elliptical arcs)
    for (var i = 1; i < 9; i++) {
      final ratio = (i / 9) * 2 - 1;
      final x = cx + ratio * r;
      final hh = math.sqrt(math.max(0, r * r - (x - cx) * (x - cx)));
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, cy), width: r * 0.04, height: hh * 2),
        gridPaint,
      );
    }

    canvas.restore();

    // Atmospheric glow rim
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.07
        ..shader = ui.Gradient.radial(
          center,
          r * 1.05,
          const [
            Color(0x0038BDF8),
            Color(0x2838BDF8),
            Color(0x0038BDF8),
          ],
          const [0.88, 0.96, 1.0],
        ),
    );

    // Specular highlight for 3D polish
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(cx - r * 0.35, cy - r * 0.35),
          r * 0.55,
          const [
            Color(0x28FFFFFF),
            Color(0x00FFFFFF),
          ],
        ),
    );
  }

  void _drawLand(Canvas canvas, Offset c, double r, double dx, double dy, double w, double h, Paint p) {
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(c.dx + r * dx, c.dy + r * dy),
        width: r * w,
        height: r * h,
      ),
      p,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Nearby Zone Card ──
class _NearbyZoneCard extends ConsumerStatefulWidget {
  const _NearbyZoneCard();

  @override
  ConsumerState<_NearbyZoneCard> createState() => _NearbyZoneCardState();
}

class _NearbyZoneCardState extends ConsumerState<_NearbyZoneCard> {
  bool _isRefreshing = false;

  Future<void> _refreshZone() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      await ref.read(geolocationProvider.notifier).getCurrentLocation();
      await ref.read(zoneProvider.notifier).forceRefresh();
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final zone = ref.watch(zoneProvider);
    final content = ref.watch(zoneContentProvider);
    final geo = ref.watch(geolocationProvider);

    final hasLocation = geo.hasLocation;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasLocation
              ? AppColors.primary.withValues(alpha: 0.2)
              : AppColors.textSecondary.withValues(alpha: 0.15),
        ),
      ),
      child: hasLocation
          ? _buildContent(zone, content)
          : _buildNoLocation(),
    );
  }

  Widget _buildNoLocation() {
    return Row(
      children: [
        Icon(LucideIcons.mapPinOff, size: 18,
            color: AppColors.textSecondary.withValues(alpha: 0.5)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'No location available',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary.withValues(alpha: 0.6),
            ),
          ),
        ),
        GestureDetector(
          onTap: _isRefreshing ? null : _refreshZone,
          child: _isRefreshing
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                  ),
                )
              : Icon(LucideIcons.refreshCw, size: 18,
                  color: AppColors.textSecondary.withValues(alpha: 0.5)),
        ),
      ],
    );
  }

  Widget _buildContent(ZoneState zone, ZoneContentState content) {
    final overallPct = (content.overallProgress * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Row(
          children: [
            Icon(LucideIcons.radar, size: 14, color: AppColors.primary.withValues(alpha: 0.6)),
            const SizedBox(width: 6),
            Text(
              'Current Zone',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.primary.withValues(alpha: 0.6),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Zone name + refresh + progress %
        Row(
          children: [
            Icon(LucideIcons.mapPin, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                zone.hasZone ? zone.displayLabel : 'Your Area',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            GestureDetector(
              onTap: _isRefreshing ? null : _refreshZone,
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _isRefreshing
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary.withValues(alpha: 0.5),
                        ),
                      )
                    : Icon(LucideIcons.refreshCw, size: 16,
                        color: AppColors.primary.withValues(alpha: 0.5)),
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$overallPct%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Overall progress bar
        _ZoneProgressBar(
          progress: content.overallProgress,
          color: AppColors.primary,
        ),
        const SizedBox(height: 16),

        // ── Achievements row (location achievements only) ──
        _ZoneCategory(
          icon: LucideIcons.trophy,
          color: AppColors.gold,
          label: 'Achievements',
          earned: content.unlockedTravelTrophies,
          total: content.totalTravelTrophies,
          progress: content.totalTravelTrophies > 0
              ? content.unlockedTravelTrophies / content.totalTravelTrophies
              : 0,
        ),
        const SizedBox(height: 10),

        // ── Activities row (quests in zone) ──
        _ZoneCategory(
          icon: LucideIcons.compass,
          color: AppColors.accent,
          label: 'Activities',
          earned: content.completedActivities,
          total: content.totalActivitiesInZone,
          progress: content.activityProgress,
        ),

        // ── Story Quests in zone ──
        if (content.nearbyQuests.isNotEmpty) ...[
          const SizedBox(height: 10),
          _ZoneQuestsMiniBar(quests: content.nearbyQuests),
        ],

        // ── View Details tap target ──
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _ZoneDetailSheet.show(context, zone, content),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.list, size: 14,
                    color: AppColors.primary.withValues(alpha: 0.7)),
                const SizedBox(width: 6),
                Text(
                  'View All Nearby',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ZoneProgressBar extends StatelessWidget {
  final double progress;
  final Color color;

  const _ZoneProgressBar({required this.progress, required this.color});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: LinearProgressIndicator(
        value: progress.clamp(0.0, 1.0),
        minHeight: 5,
        backgroundColor: color.withValues(alpha: 0.1),
        valueColor: AlwaysStoppedAnimation(color),
      ),
    );
  }
}

class _ZoneCategory extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final int earned;
  final int total;
  final double progress;

  const _ZoneCategory({
    required this.icon,
    required this.color,
    required this.label,
    required this.earned,
    required this.total,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            Text(
              '$earned / $total',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _ZoneProgressBar(progress: progress, color: color),
      ],
    );
  }
}

// ── Story Quests Mini Bar (inside zone card) ──
class _ZoneQuestsMiniBar extends StatelessWidget {
  final List<Quest> quests;

  const _ZoneQuestsMiniBar({required this.quests});

  @override
  Widget build(BuildContext context) {
    const questColor = Color(0xFF8B5CF6);

    return Column(
      children: [
        Row(
          children: [
            Icon(LucideIcons.scroll, size: 16, color: questColor),
            const SizedBox(width: 8),
            Text(
              'Quests',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            Text(
              '${quests.length} active nearby',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: questColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 28,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: quests.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (context, index) {
              final quest = quests[index];
              final stepsLeft = quest.totalSteps - quest.completedStepCount;
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: questColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: questColor.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(quest.icon, style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 90),
                      child: Text(
                        quest.title,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: questColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$stepsLeft left',
                      style: TextStyle(
                        fontSize: 10,
                        color: questColor.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Zone Detail Sheet ──
class _ZoneDetailSheet extends StatelessWidget {
  final ZoneState zone;
  final ZoneContentState content;

  const _ZoneDetailSheet({required this.zone, required this.content});

  static Future<void> show(
    BuildContext context,
    ZoneState zone,
    ZoneContentState content,
  ) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, scrollController) => _ZoneDetailContent(
          zone: zone,
          content: content,
          scrollController: scrollController,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _ZoneDetailContent extends StatelessWidget {
  final ZoneState zone;
  final ZoneContentState content;
  final ScrollController scrollController;

  const _ZoneDetailContent({
    required this.zone,
    required this.content,
    required this.scrollController,
  });

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()}m';
    return '${(meters / 1000).toStringAsFixed(1)}km';
  }

  @override
  Widget build(BuildContext context) {
    // Build unified list sorted by distance
    final items = <_ZoneDetailItem>[];

    for (final nearby in content.nearbyAchievements) {
      items.add(_ZoneDetailItem(
        type: _ZoneItemType.achievement,
        title: nearby.item.title,
        distanceMeters: nearby.distanceMeters,
        achievement: nearby.item,
        isCompleted: nearby.item.isUnlocked,
        isPending: nearby.item.isPendingClaim && !nearby.item.isUnlocked,
        subtitle: _tierLabel(nearby.item.tier),
        xp: nearby.item.xpReward,
      ));
    }

    for (final nearby in content.nearbyActivities) {
      items.add(_ZoneDetailItem(
        type: _ZoneItemType.activity,
        title: nearby.item.title,
        distanceMeters: nearby.distanceMeters,
        activity: nearby.item,
        isCompleted: nearby.item.completionCount > 0,
        subtitle: nearby.item.category,
        xp: nearby.item.xpReward,
      ));
    }

    for (final quest in content.nearbyQuests) {
      items.add(_ZoneDetailItem(
        type: _ZoneItemType.quest,
        title: quest.title,
        distanceMeters: -1, // quests don't have a single location
        quest: quest,
        isCompleted: quest.isCompleted,
        subtitle:
            '${quest.completedStepCount}/${quest.totalSteps} steps',
        xp: quest.xpReward,
        icon: quest.icon,
      ));
    }

    // Sort: quests first (no distance), then by distance
    items.sort((a, b) {
      if (a.distanceMeters < 0 && b.distanceMeters < 0) return 0;
      if (a.distanceMeters < 0) return 1;
      if (b.distanceMeters < 0) return 1;
      return a.distanceMeters.compareTo(b.distanceMeters);
    });

    final achievementCount = content.nearbyAchievements.length;
    final activityCount = content.nearbyActivities.length;
    final questCount = content.nearbyQuests.length;

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        // Drag handle
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textMuted.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Title
        Row(
          children: [
            Icon(LucideIcons.radar, size: 20, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                zone.hasZone ? zone.displayLabel : 'Your Area',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Within 100km radius',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 16),

        // Summary chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _SummaryChip(
              icon: LucideIcons.trophy,
              color: AppColors.gold,
              label: '$achievementCount achievements',
            ),
            _SummaryChip(
              icon: LucideIcons.compass,
              color: AppColors.accent,
              label: '$activityCount activities',
            ),
            if (questCount > 0)
              _SummaryChip(
                icon: LucideIcons.scroll,
                color: const Color(0xFF8B5CF6),
                label: '$questCount quests',
              ),
          ],
        ),
        const SizedBox(height: 20),

        // Divider
        const Divider(height: 1),
        const SizedBox(height: 12),

        // Items list
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                'No nearby items found',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          )
        else
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: 2),
            _ZoneDetailRow(
              item: items[i],
              formatDistance: _formatDistance,
            ),
          ],
      ],
    );
  }

  String _tierLabel(AchievementTier tier) => switch (tier) {
        AchievementTier.bronze => 'Bronze',
        AchievementTier.silver => 'Silver',
        AchievementTier.gold => 'Gold',
        AchievementTier.platinum => 'Platinum',
      };
}

enum _ZoneItemType { achievement, activity, quest }

class _ZoneDetailItem {
  final _ZoneItemType type;
  final String title;
  final double distanceMeters;
  final Achievement? achievement;
  final SideQuest? activity;
  final Quest? quest;
  final bool isCompleted;
  final bool isPending;
  final String subtitle;
  final int xp;
  final String? icon;

  const _ZoneDetailItem({
    required this.type,
    required this.title,
    required this.distanceMeters,
    this.achievement,
    this.activity,
    this.quest,
    this.isCompleted = false,
    this.isPending = false,
    required this.subtitle,
    required this.xp,
    this.icon,
  });
}

class _ZoneDetailRow extends StatelessWidget {
  final _ZoneDetailItem item;
  final String Function(double) formatDistance;

  const _ZoneDetailRow({
    required this.item,
    required this.formatDistance,
  });

  @override
  Widget build(BuildContext context) {
    final (typeIcon, typeColor) = switch (item.type) {
      _ZoneItemType.achievement => (LucideIcons.trophy, AppColors.gold),
      _ZoneItemType.activity => (LucideIcons.compass, AppColors.accent),
      _ZoneItemType.quest => (LucideIcons.scroll, const Color(0xFF8B5CF6)),
    };

    return InkWell(
      onTap: () => _onTap(context),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          children: [
            // Type icon
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: item.icon != null
                  ? Center(
                      child:
                          Text(item.icon!, style: const TextStyle(fontSize: 16)))
                  : Icon(typeIcon, size: 16, color: typeColor),
            ),
            const SizedBox(width: 12),

            // Title + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: item.isPending
                          ? AppColors.gold
                          : AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        item.subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(LucideIcons.zap,
                          size: 10, color: AppColors.xpGreen),
                      const SizedBox(width: 2),
                      Text(
                        '+${item.xp}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.xpGreen,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Distance
            if (item.distanceMeters >= 0) ...[
              const SizedBox(width: 8),
              Text(
                formatDistance(item.distanceMeters),
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(width: 8),

            // Status
            if (item.isPending)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.gold, AppColors.accent],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Claim',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else
              Icon(
                item.isCompleted ? LucideIcons.check : LucideIcons.chevronRight,
                size: 16,
                color: item.isCompleted
                    ? AppColors.success
                    : AppColors.textMuted.withValues(alpha: 0.4),
              ),
          ],
        ),
      ),
    );
  }

  void _onTap(BuildContext context) {
    switch (item.type) {
      case _ZoneItemType.achievement:
        if (item.achievement != null) {
          AchievementDetailSheet.show(context, item.achievement!);
        }
      case _ZoneItemType.activity:
        if (item.activity != null) {
          context.push(
              '/skills/${item.activity!.skillType}/activity/${item.activity!.id}');
        }
      case _ZoneItemType.quest:
        // No dedicated quest detail screen — just dismiss
        break;
    }
  }
}

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _SummaryChip({
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pending Quest Chain Claims Banner for Home Screen ──
class _HomeQuestChainClaims extends ConsumerWidget {
  const _HomeQuestChainClaims();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chainState = ref.watch(questChainProvider);
    final claimable = chainState.claimableQuests;

    if (claimable.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF8B5CF6).withValues(alpha: 0.15),
            AppColors.primary.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Icon(LucideIcons.scroll, size: 16, color: const Color(0xFF8B5CF6)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${claimable.length} ${claimable.length == 1 ? 'quest' : 'quests'} ready to claim!',
                    style: const TextStyle(
                      color: Color(0xFF8B5CF6),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              itemCount: claimable.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final quest = claimable[index];
                return GestureDetector(
                  onTap: () {
                    ref.read(questChainProvider.notifier).claimQuest(quest.id);
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(quest.icon, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 120),
                          child: Text(
                            quest.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '+${quest.xpReward} XP',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w500,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pending Claims Banner for Home Screen ──
// Always visible — shows pending trophies/revisits, or a waiting state.
class _HomePendingClaims extends ConsumerWidget {
  const _HomePendingClaims();

  Future<void> _claimAll(
    BuildContext context,
    WidgetRef ref,
    List<Achievement> pending,
  ) async {
    final navContext = Navigator.of(context, rootNavigator: true).context;
    final notifier = ref.read(achievementsProvider.notifier);
    final batch = pending.take(claimAllMaxBatch).toList();
    final claimed = <Achievement>[];
    var totalXp = 0;

    for (final achievement in batch) {
      final success = await notifier.confirmPendingClaim(achievement.id);
      if (success) {
        claimed.add(achievement);
        totalXp += achievement.xpReward;
      }
    }

    if (claimed.isEmpty || !navContext.mounted) return;

    await AchievementUnlockPopup.showChain(navContext, claimed);

    if (navContext.mounted) {
      await ClaimAllSummaryDialog.show(
        navContext,
        claimed: claimed,
        totalXp: totalXp,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievements = ref.watch(achievementsProvider);
    final pendingClaims = achievements.allAchievements
        .where((a) => a.isPendingClaim && !a.isUnlocked)
        .toList();
    final pendingRevisits = achievements.allAchievements
        .where((a) => a.isPendingRevisit && a.isUnlocked)
        .toList();
    final hasPending = pendingClaims.isNotEmpty || pendingRevisits.isNotEmpty;
    final totalPending = pendingClaims.length + pendingRevisits.length;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasPending
              ? [
                  AppColors.gold.withValues(alpha: 0.15),
                  AppColors.accent.withValues(alpha: 0.08),
                ]
              : [
                  AppColors.bgCard,
                  AppColors.bgCard,
                ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasPending
              ? AppColors.gold.withValues(alpha: 0.4)
              : AppColors.bgCardLight.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Icon(
                  LucideIcons.trophy,
                  size: 16,
                  color: hasPending ? AppColors.gold : AppColors.textMuted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hasPending
                        ? '$totalPending ${totalPending == 1 ? 'trophy' : 'trophies'} ready to claim!'
                        : 'No trophies to claim yet',
                    style: TextStyle(
                      color: hasPending ? AppColors.gold : AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (pendingClaims.length > 1)
                  GestureDetector(
                    onTap: () => _claimAll(context, ref, pendingClaims),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.gold, AppColors.accent],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Claim All',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (hasPending)
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                itemCount: totalPending,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  // Show pending claims first, then revisits
                  final isRevisit = index >= pendingClaims.length;
                  final achievement = isRevisit
                      ? pendingRevisits[index - pendingClaims.length]
                      : pendingClaims[index];

                  return GestureDetector(
                    onTap: () async {
                      final navContext =
                          Navigator.of(context, rootNavigator: true).context;
                      final notifier =
                          ref.read(achievementsProvider.notifier);
                      if (isRevisit) {
                        final acknowledged =
                            await notifier.acknowledgeRevisit(achievement.id);
                        if (acknowledged && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(LucideIcons.footprints,
                                      size: 16, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text(
                                      'Visit #${achievement.visitCount} claimed — ${achievement.title}'),
                                ],
                              ),
                              backgroundColor: AppColors.info,
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      } else {
                        final claimed =
                            await notifier.confirmPendingClaim(achievement.id);
                        if (claimed && navContext.mounted) {
                          await AchievementUnlockPopup.show(
                              navContext, achievement);
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isRevisit
                              ? [AppColors.info, AppColors.info.withValues(alpha: 0.8)]
                              : [AppColors.primary, AppColors.primaryLight],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isRevisit
                                ? LucideIcons.footprints
                                : LucideIcons.sparkles,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 120),
                            child: Text(
                              achievement.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isRevisit
                                ? 'Claim Revisit'
                                : '+${achievement.xpReward} XP',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontWeight: FontWeight.w500,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Text(
                'Explore the map to discover trophies nearby!',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
