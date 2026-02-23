import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:travel_buddy_mobile/core/theme/app_theme.dart';
import 'package:travel_buddy_mobile/shared/models/user_profile.dart';
import 'package:travel_buddy_mobile/shared/providers/achievements_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/quests_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/user_profile_provider.dart';
import 'package:travel_buddy_mobile/shared/widgets/directional_icon.dart';
import 'package:travel_buddy_mobile/shared/widgets/xp_progress_bar.dart';
import 'package:travel_buddy_mobile/shared/widgets/responsive_layout.dart';
import 'package:travel_buddy_mobile/shared/widgets/visual_extras.dart';
import 'package:travel_buddy_mobile/shared/providers/city_name_provider.dart';
import 'package:travel_buddy_mobile/features/profile/presentation/widgets/profile_avatar.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
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
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(userProfileProvider);
    final achievements = ref.watch(achievementsProvider);
    final quests = ref.watch(questsProvider);

    final cityName = ref.watch(cityNameProvider);
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
                            activeSkillCount: quests.skillLevels.length,
                            totalSkillXp: quests.skillXp.values.fold(0, (a, b) => a + b),
                            unlockedAchievements: achievements.totalUnlocked,
                            totalAchievements: achievements.totalAchievements,
                            completedQuests: quests.completedCount,
                            streakDays: quests.currentStreak,
                            onAvatarTap: () => context.go('/profile'),
                            onSkillsTap: () => context.go('/skills'),
                            onAchievementsTap: () => context.go('/achievements'),
                            onQuestsTap: () => context.go('/quests'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 36),

                      // ── Adventures Section ──
                      FadeTransition(
                        opacity: _adventureFade,
                        child: SlideTransition(
                          position: _adventureSlide,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionHeader(title: l10n.nearbyAdventures),
                              const SizedBox(height: 16),
                              _AdventureCard(
                                title: cityName != null ? l10n.exploreCity(cityName) : l10n.exploreYourCity,
                                subtitle: l10n.achievementsToUnlock(achievements.totalAchievements - achievements.totalUnlocked),
                                icon: LucideIcons.mapPin,
                                color: AppColors.primary,
                                onTap: () => context.go('/map'),
                              ),
                              const SizedBox(height: 14),
                              _AdventureCard(
                                title: l10n.dailyQuestAvailable,
                                subtitle: l10n.takePhotoAtLandmark,
                                icon: LucideIcons.camera,
                                color: AppColors.accent,
                                onTap: () => context.go('/quests'),
                              ),
                            ],
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
  final int activeSkillCount;
  final int totalSkillXp;
  final int unlockedAchievements;
  final int totalAchievements;
  final int completedQuests;
  final int streakDays;
  final VoidCallback onAvatarTap;
  final VoidCallback onSkillsTap;
  final VoidCallback onAchievementsTap;
  final VoidCallback onQuestsTap;

  const _ProfileUnit({
    required this.user,
    required this.activeSkillCount,
    required this.totalSkillXp,
    required this.unlockedAchievements,
    required this.totalAchievements,
    required this.completedQuests,
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
                        label: l10n.skills,
                        value: '$activeSkillCount',
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
                        value: '$completedQuests',
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

// ─── Adventure Card ─────────────────────────────────────────────────────────

class _AdventureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _AdventureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.10),
              AppColors.bgCard,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: color.withValues(alpha: 0.15),
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.15),
                    blurRadius: 8,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            DirectionalChevron(color: AppColors.textMuted, size: 20),
          ],
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
