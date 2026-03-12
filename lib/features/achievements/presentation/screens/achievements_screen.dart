import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:travel_buddy_mobile/l10n/app_localizations.dart';
import 'package:travel_buddy_mobile/core/theme/app_theme.dart';
import 'package:travel_buddy_mobile/l10n/registry_l10n.dart';
import 'package:travel_buddy_mobile/shared/models/achievement.dart';
import 'package:travel_buddy_mobile/shared/providers/achievements_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/geolocation_provider.dart';
import 'package:travel_buddy_mobile/features/achievements/presentation/widgets/retroactive_claim_modal.dart';
import 'package:travel_buddy_mobile/shared/widgets/responsive_layout.dart';
import 'package:travel_buddy_mobile/shared/widgets/collection_complete_dialog.dart';
import 'package:travel_buddy_mobile/shared/widgets/visual_extras.dart';
import 'package:travel_buddy_mobile/shared/data/country_details_registry.dart';
import 'package:travel_buddy_mobile/features/achievements/presentation/screens/country_detail_screen.dart';

// ── Category tab definition ──
class _CategoryTab {
  final String id;
  final String label;
  final String emoji;
  final IconData icon;
  final Color color;
  final List<Color> heroGradient;
  final String subtitle;

  const _CategoryTab({
    required this.id,
    required this.label,
    required this.emoji,
    required this.icon,
    required this.color,
    required this.heroGradient,
    required this.subtitle,
  });
}

enum _QuickTrophyFilter { all, unlocked, locked, nearby, highXp }

class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static List<_CategoryTab> _getCategories(AppLocalizations l10n) => [
    _CategoryTab(
      id: 'europe',
      label: l10n.tabCountries,
      emoji: '\u{1F30D}',
      icon: LucideIcons.globe,
      color: Color(0xFF3B82F6),
      heroGradient: [Color(0xFF1E3A5F), Color(0xFF2563EB), Color(0xFF1E40AF)],
      subtitle: l10n.exploreNationsSubtitle,
    ),
    _CategoryTab(
      id: 'capitals',
      label: l10n.tabCapitals,
      emoji: '\u{1F3DB}',
      icon: LucideIcons.building2,
      color: Color(0xFFD97706),
      heroGradient: [Color(0xFF78350F), Color(0xFFD97706), Color(0xFF92400E)],
      subtitle: l10n.capitalCitiesSubtitle,
    ),
    _CategoryTab(
      id: 'national-parks',
      label: l10n.tabNationalParks,
      emoji: '\u{1F3DE}',
      icon: LucideIcons.mountain,
      color: Color(0xFF10B981),
      heroGradient: [Color(0xFF064E3B), Color(0xFF059669), Color(0xFF065F46)],
      subtitle: l10n.nationalParksSubtitle,
    ),
    _CategoryTab(
      id: 'ski-resorts',
      label: l10n.tabSkiResorts,
      emoji: '\u{26F7}',
      icon: LucideIcons.snowflake,
      color: Color(0xFF8B5CF6),
      heroGradient: [Color(0xFF312E81), Color(0xFF7C3AED), Color(0xFF4C1D95)],
      subtitle: l10n.skiResortsSubtitle,
    ),
    _CategoryTab(
      id: 'ancient-sites',
      label: l10n.tabAncientSites,
      emoji: '\u{1F54C}',
      icon: LucideIcons.church,
      color: Color(0xFFDC2626),
      heroGradient: [Color(0xFF7F1D1D), Color(0xFFB91C1C), Color(0xFF991B1B)],
      subtitle: l10n.ancientSitesSubtitle,
    ),
    _CategoryTab(
      id: 'tourist-destinations',
      label: l10n.tabTopDestinations,
      emoji: '\u{2708}',
      icon: LucideIcons.plane,
      color: Color(0xFF0EA5E9),
      heroGradient: [Color(0xFF0C4A6E), Color(0xFF0284C7), Color(0xFF075985)],
      subtitle: l10n.topDestinationsSubtitle,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(achievementsProvider);
    final geo = ref.watch(geolocationProvider);
    final categories = _getCategories(l10n);

    return SafeArea(
      child: ResponsiveLayout(
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
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
                  _ProgressBadge(
                    unlocked: state.totalUnlocked,
                    total: state.totalAchievements,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  l10n.unlockedOfTotal(state.totalUnlocked, state.totalAchievements),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
              ),
            ),
            // ── Pending Claims Banner ──
            _PendingClaimsBanner(),
            const SizedBox(height: 16),
            // ── Tab bar ──
            _buildTabBar(categories),
            const SizedBox(height: 2),
            // ── Tab content ──
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: categories.map((cat) {
                  // Combine europe + americas for the Countries tab
                  final List<Achievement> achievements;
                  if (cat.id == 'europe') {
                    achievements = state.allAchievements
                        .where((a) =>
                            a.collectionId == 'europe' ||
                            a.collectionId == 'americas')
                        .toList();
                  } else {
                    achievements = state.allAchievements
                        .where((a) => a.collectionId == cat.id)
                        .toList();
                  }
                  return _CategoryPage(
                    category: cat,
                    achievements: achievements,
                    geo: geo,
                    completedCollections: state.completedCollections,
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(List<_CategoryTab> categories) {
    return Container(
      height: 42,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.2),
              AppColors.primaryLight.withValues(alpha: 0.1),
            ],
          ),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
        ),
        labelColor: AppColors.primaryLight,
        unselectedLabelColor: AppColors.textMuted,
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
        tabs: categories.map((cat) {
          return Tab(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(cat.emoji, style: const TextStyle(fontSize: 15)),
                  const SizedBox(width: 6),
                  Text(cat.label),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Progress Badge ──
class _ProgressBadge extends StatelessWidget {
  final int unlocked;
  final int total;
  const _ProgressBadge({required this.unlocked, required this.total});

  @override
  Widget build(BuildContext context) {
    return GlowContainer(
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
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedCounter(
              value: unlocked,
              style: TextStyle(
                color: AppColors.primaryLight,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            Text(
              ' / $total',
              style: TextStyle(
                color: AppColors.primaryLight,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Category Page (content for each tab) ──
class _CategoryPage extends ConsumerStatefulWidget {
  final _CategoryTab category;
  final List<Achievement> achievements;
  final GeolocationState geo;
  final Set<String> completedCollections;

  const _CategoryPage({
    required this.category,
    required this.achievements,
    required this.geo,
    required this.completedCollections,
  });

  @override
  ConsumerState<_CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends ConsumerState<_CategoryPage> {
  String _searchQuery = '';
  _QuickTrophyFilter _quickFilter = _QuickTrophyFilter.all;
  String? _heatmapFilterKey;

  bool get _isCountriesTab => widget.category.id == 'europe';

  /// For the countries tab: merge all Americas achievements into a single
  /// "United States" representative card, keeping Europe as individual cards.
  static const _usRepresentativeId = 'americas-nyc';

  /// A synthetic Achievement used as the single US card.
  static const _usCard = Achievement(
    id: 'americas-usa',
    title: 'United States',
    description: 'Explore iconic American destinations from coast to coast',
    tier: AchievementTier.gold,
    xpReward: 35,
    latitude: 38.9072,
    longitude: -77.0369,
    claimRadius: 50000,
    collectionId: 'americas',
    tags: ['americas'],
  );

  /// Build the display list: Europe countries + one US card.
  List<Achievement> get _displayList {
    if (!_isCountriesTab) return widget.achievements;
    final europe = widget.achievements.where((a) => a.collectionId == 'europe').toList();
    // Add single US card
    return [...europe, _usCard];
  }

  /// Grouped display: list of (header, achievements) pairs for continent sections.
  List<(String header, String emoji, List<Achievement>)> _groupedDisplay(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final isHe = locale.languageCode == 'he';
    final europe = widget.achievements.where((a) => a.collectionId == 'europe').toList();
    final americas = <Achievement>[_usCard];
    return [
      (isHe ? 'אירופה' : 'Europe', '\u{1F1EA}\u{1F1FA}', europe),
      (isHe ? 'אמריקה' : 'Americas', '\u{1F30E}', americas),
    ];
  }

  List<Achievement> get _filtered {
    final base = _displayList.where(_matchesQuickFilter).where(_matchesHeatmapFilter).toList();
    if (_searchQuery.isEmpty) return base;
    final q = _searchQuery.toLowerCase();
    return base
        .where((a) => a.title.toLowerCase().contains(q) || a.description.toLowerCase().contains(q))
        .toList();
  }

  bool _matchesHeatmapFilter(Achievement achievement) {
    if (_heatmapFilterKey == null) return true;
    return _heatmapKeyFor(achievement) == _heatmapFilterKey;
  }

  String _heatmapKeyFor(Achievement achievement) {
    if (_isCountriesTab) return achievement.collectionId ?? 'other';
    if (achievement.tags.isNotEmpty) return achievement.tags.first;
    return achievement.collectionId ?? 'other';
  }

  String _labelForHeatmapKey(String key, AppLocalizations l10n) {
    if (key.isEmpty) return l10n.heatmapOther;
    final normalized = key.replaceAll('-', ' ').trim();
    if (normalized.isEmpty) return l10n.heatmapOther;
    final words = normalized.split(RegExp(r'\s+'));
    return words
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  bool _matchesQuickFilter(Achievement achievement) {
    switch (_quickFilter) {
      case _QuickTrophyFilter.all:
        return true;
      case _QuickTrophyFilter.unlocked:
        return achievement.isUnlocked;
      case _QuickTrophyFilter.locked:
        return !achievement.isUnlocked;
      case _QuickTrophyFilter.nearby:
        if (achievement.isUnlocked) return false;
        final distance = _getDistance(widget.geo, achievement);
        return distance != null && distance <= 15000;
      case _QuickTrophyFilter.highXp:
        return !achievement.isUnlocked && achievement.xpReward >= 35;
    }
  }

  Achievement? _nextBestTarget(List<Achievement> all) {
    final locked = all.where((a) => !a.isUnlocked).toList();
    if (locked.isEmpty) return null;
    if (widget.geo.hasLocation) {
      locked.sort((a, b) {
        final da = _getDistance(widget.geo, a) ?? double.infinity;
        final db = _getDistance(widget.geo, b) ?? double.infinity;
        final byDistance = da.compareTo(db);
        if (byDistance != 0) return byDistance;
        return b.xpReward.compareTo(a.xpReward);
      });
      return locked.first;
    }
    locked.sort((a, b) => b.xpReward.compareTo(a.xpReward));
    return locked.first;
  }

  String _formatDistanceLabel(double meters) {
    if (meters >= 1000) return '${(meters / 1000).toStringAsFixed(1)} km';
    return '${meters.round()} m';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final all = widget.achievements;
    final shown = _filtered;
    final unlockedCount = all.where((a) => a.isUnlocked).length;
    final lockedCount = all.length - unlockedCount;
    final nearbyCount = all.where((a) {
      if (a.isUnlocked) return false;
      final distance = _getDistance(widget.geo, a);
      return distance != null && distance <= 15000;
    }).length;
    final highXpCount = all.where((a) => !a.isUnlocked && a.xpReward >= 35).length;
    final progress = all.isEmpty ? 0.0 : unlockedCount / all.length;
    final nextTarget = _nextBestTarget(all);
    final tierCounts = <AchievementTier, int>{
      AchievementTier.bronze: all.where((a) => a.tier == AchievementTier.bronze).length,
      AchievementTier.silver: all.where((a) => a.tier == AchievementTier.silver).length,
      AchievementTier.gold: all.where((a) => a.tier == AchievementTier.gold).length,
      AchievementTier.platinum: all.where((a) => a.tier == AchievementTier.platinum).length,
    };
    final heatmapTotals = <String, int>{};
    final heatmapUnlocked = <String, int>{};
    for (final achievement in all) {
      final key = _heatmapKeyFor(achievement);
      heatmapTotals[key] = (heatmapTotals[key] ?? 0) + 1;
      if (achievement.isUnlocked) {
        heatmapUnlocked[key] = (heatmapUnlocked[key] ?? 0) + 1;
      }
    }
    final heatmapData = heatmapTotals.entries
        .map((entry) {
          final unlocked = heatmapUnlocked[entry.key] ?? 0;
          return (
            key: entry.key,
            label: _labelForHeatmapKey(entry.key, l10n),
            unlocked: unlocked,
            total: entry.value,
            progress: entry.value == 0 ? 0.0 : unlocked / entry.value,
          );
        })
        .toList()
      ..sort((a, b) => b.progress.compareTo(a.progress));
    final timelineUnlocked = all
        .where((a) => a.isUnlocked && a.unlockedAt != null)
        .toList()
      ..sort((a, b) => b.unlockedAt!.compareTo(a.unlockedAt!));

    // For the dropdown, use the display list (grouped)
    final dropdownList = _displayList;

    return CustomScrollView(
      slivers: [
        // ── Hero card ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _HeroCard(
              category: widget.category,
              unlockedCount: unlockedCount,
              totalCount: all.length,
              progress: progress,
            ),
          ),
        ),
        // ── Search bar + dropdown (countries tab only) ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: _TrophyCommandCenter(
              filter: _quickFilter,
              onFilterSelected: (f) => setState(() => _quickFilter = f),
              shownCount: shown.length,
              totalCount: _displayList.length,
              unlockedCount: unlockedCount,
              lockedCount: lockedCount,
              nearbyCount: nearbyCount,
              highXpCount: highXpCount,
              tierCounts: tierCounts,
              nextTarget: nextTarget,
              nextTargetDistance: nextTarget == null ? null : _getDistance(widget.geo, nextTarget),
              formatDistance: _formatDistanceLabel,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: _CollectionHeatmap(
              cells: heatmapData,
              selectedKey: _heatmapFilterKey,
              onCellTap: (key) => setState(
                () => _heatmapFilterKey = _heatmapFilterKey == key ? null : key,
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: _UnlockTimelineStrip(unlocked: timelineUnlocked),
          ),
        ),
        if (_isCountriesTab) ...[
          const SliverToBoxAdapter(child: SizedBox(height: 14)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Search bar
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.bgCardLight.withValues(alpha: 0.5)),
                      ),
                      child: TextField(
                        onChanged: (v) => setState(() => _searchQuery = v),
                        decoration: InputDecoration(
                          hintText: l10n.searchCountries,
                          prefixIcon: Icon(LucideIcons.search, size: 18, color: AppColors.textMuted),
                          filled: true,
                          fillColor: AppColors.bgCard.withValues(alpha: 0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Dropdown
                  Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.bgCard.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.bgCardLight.withValues(alpha: 0.5)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: null,
                        hint: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.list, size: 16, color: AppColors.textMuted),
                            const SizedBox(width: 6),
                            Text(l10n.allCountries, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                          ],
                        ),
                        dropdownColor: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(14),
                        icon: Icon(LucideIcons.chevronDown, size: 16, color: AppColors.textMuted),
                        items: dropdownList.map((a) {
                          final flag = _countryFlags[a.id];
                          return DropdownMenuItem(
                            value: a.id,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (flag != null) ...[
                                  Text(flag.emoji, style: const TextStyle(fontSize: 16)),
                                  const SizedBox(width: 8),
                                ],
                                Text(a.title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (id) {
                          if (id == null) return;
                          if (id == 'americas-usa') {
                            _openCountryDetail(context, _usCard);
                          } else {
                            final achievement = dropdownList.firstWhere((a) => a.id == id);
                            _openCountryDetail(context, achievement);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 14)),
        // ── Achievement list ──
        if (_isCountriesTab && _searchQuery.isEmpty)
          ..._buildGroupedCountries(context)
        else if (_isCountriesTab)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.35,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final achievement = shown[index];
                  return _CountryFlagCard(
                    achievement: achievement,
                    index: index,
                    onTap: () => _openCountryDetail(context, achievement),
                  );
                },
                childCount: shown.length,
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList.separated(
              itemCount: shown.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final achievement = shown[index];
                final distance = _getDistance(widget.geo, achievement);
                return _AchievementRow(
                  achievement: achievement,
                  distance: distance,
                  categoryColor: widget.category.color,
                  index: index,
                  onTap: () => _onTap(context, achievement, ref.read(achievementsProvider.notifier), widget.geo),
                );
              },
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  List<Widget> _buildGroupedCountries(BuildContext context) {
    final groups = _groupedDisplay(context);
    final slivers = <Widget>[];
    var globalIndex = 0;

    for (final (header, emoji, achievements) in groups) {
      // Section header
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(
                  header,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 1,
                    color: AppColors.bgCardLight.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${achievements.length}',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Grid of countries for this continent
      final startIndex = globalIndex;
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.35,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final achievement = achievements[index];
                return _CountryFlagCard(
                  achievement: achievement,
                  index: startIndex + index,
                  onTap: () => _openCountryDetail(context, achievement),
                );
              },
              childCount: achievements.length,
            ),
          ),
        ),
      );
      globalIndex += achievements.length;

      // Spacing between sections
      slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 8)));
    }

    return slivers;
  }

  void _openCountryDetail(BuildContext context, Achievement achievement) {
    final details = countryDetailsRegistry[achievement.id];
    if (details != null) {
      final flag = _countryFlags[achievement.id];
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CountryDetailScreen(
            achievement: achievement,
            details: details,
            flagWidget: flag != null
                ? CustomPaint(
                    painter: _FlagPainter(flag: flag, desaturate: !achievement.isUnlocked),
                  )
                : Container(color: AppColors.bgCard),
          ),
        ),
      );
    } else {
      // No detail data — fall back to claim/detail modal
      _onTap(context, achievement, ref.read(achievementsProvider.notifier), widget.geo);
    }
  }

  double? _getDistance(GeolocationState geo, Achievement achievement) {
    if (!geo.hasLocation) return null;
    if (achievement.latitude == null || achievement.longitude == null) return null;
    return geo.distanceTo(achievement.latitude!, achievement.longitude!);
  }

  void _onTap(
    BuildContext context,
    Achievement achievement,
    AchievementsNotifier notifier,
    GeolocationState geo,
  ) async {
    if (achievement.isUnlocked) {
      _showDetail(context, achievement);
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

  void _showDetail(BuildContext context, Achievement achievement) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);

    final tierColor = switch (achievement.tier) {
      AchievementTier.bronze => AppColors.bronze,
      AchievementTier.silver => AppColors.silver,
      AchievementTier.gold => AppColors.gold,
      AchievementTier.platinum => AppColors.platinum,
    };

    final tierLabel = switch (achievement.tier) {
      AchievementTier.bronze => l10n.tierBronzeLabel,
      AchievementTier.silver => l10n.tierSilverLabel,
      AchievementTier.gold => l10n.tierGoldLabel,
      AchievementTier.platinum => l10n.tierPlatinumLabel,
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
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.bgCard, width: 2),
              ),
              child: const Icon(LucideIcons.check, size: 20, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              RegistryL10n.achievementTitle(locale, achievement.id, achievement.title),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              RegistryL10n.achievementDescription(locale, achievement.id, achievement.description),
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 20),
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

// ── Hero Card with Custom Paint visual ──
class _CollectionHeatmap extends StatelessWidget {
  final List<({String key, String label, int unlocked, int total, double progress})> cells;
  final String? selectedKey;
  final ValueChanged<String> onCellTap;

  const _CollectionHeatmap({
    required this.cells,
    required this.selectedKey,
    required this.onCellTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.bgCardLight.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.list, size: 16, color: AppColors.primaryLight),
              const SizedBox(width: 8),
              Text(
                l10n.collectionHeatmap,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (cells.isEmpty)
            Text(
              l10n.noHeatmapData,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: cells.map((cell) {
                final isSelected = cell.key == selectedKey;
                final tint = Color.lerp(
                  AppColors.bgCardLight.withValues(alpha: 0.5),
                  AppColors.primary.withValues(alpha: 0.35),
                  cell.progress.clamp(0.0, 1.0),
                )!;
                return GestureDetector(
                  onTap: () => onCellTap(cell.key),
                  child: Container(
                    width: 130,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: tint,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryLight
                            : AppColors.bgCardLight.withValues(alpha: 0.6),
                        width: isSelected ? 1.4 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cell.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isSelected ? AppColors.primaryLight : AppColors.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          l10n.heatmapUnlockedOfTotal(cell.unlocked, cell.total),
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: cell.progress,
                            minHeight: 5,
                            backgroundColor: AppColors.bgCardLight.withValues(alpha: 0.5),
                            valueColor: AlwaysStoppedAnimation(AppColors.primaryLight),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _UnlockTimelineStrip extends StatelessWidget {
  final List<Achievement> unlocked;

  const _UnlockTimelineStrip({
    required this.unlocked,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.bgCardLight.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.calendarClock, size: 16, color: AppColors.primaryLight),
              const SizedBox(width: 8),
              Text(
                l10n.unlockTimeline,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (unlocked.isEmpty)
            Text(
              l10n.noUnlockedTrophiesYet,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            )
          else
            SizedBox(
              height: 92,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: unlocked.length > 10 ? 10 : unlocked.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final item = unlocked[index];
                  final date = DateFormat.MMMd(locale.languageCode).format(item.unlockedAt!);
                  final title = RegistryL10n.achievementTitle(locale, item.id, item.title);
                  return Container(
                    width: 180,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.bgCardLight.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.bgCardLight.withValues(alpha: 0.65)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              date,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            if (item.isRetroactive)
                              const Icon(LucideIcons.history, size: 12, color: AppColors.warning),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '+${item.xpReward} XP',
                          style: const TextStyle(
                            color: AppColors.xpGlow,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
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

class _TrophyCommandCenter extends StatelessWidget {
  final _QuickTrophyFilter filter;
  final ValueChanged<_QuickTrophyFilter> onFilterSelected;
  final int shownCount;
  final int totalCount;
  final int unlockedCount;
  final int lockedCount;
  final int nearbyCount;
  final int highXpCount;
  final Map<AchievementTier, int> tierCounts;
  final Achievement? nextTarget;
  final double? nextTargetDistance;
  final String Function(double meters) formatDistance;

  const _TrophyCommandCenter({
    required this.filter,
    required this.onFilterSelected,
    required this.shownCount,
    required this.totalCount,
    required this.unlockedCount,
    required this.lockedCount,
    required this.nearbyCount,
    required this.highXpCount,
    required this.tierCounts,
    required this.nextTarget,
    required this.nextTargetDistance,
    required this.formatDistance,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final tierTotal = tierCounts.values.fold<int>(0, (sum, c) => sum + c);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.bgCardLight.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.sparkles, size: 16, color: AppColors.primaryLight),
              const SizedBox(width: 8),
              Text(
                l10n.trophyCommandCenter,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Text(
                l10n.shownCountOfTotal(shownCount, totalCount),
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _QuickFilterChip(
                label: l10n.tierAll,
                selected: filter == _QuickTrophyFilter.all,
                onTap: () => onFilterSelected(_QuickTrophyFilter.all),
              ),
              _QuickFilterChip(
                label: l10n.quickFilterUnlockedCount(unlockedCount),
                selected: filter == _QuickTrophyFilter.unlocked,
                onTap: () => onFilterSelected(_QuickTrophyFilter.unlocked),
              ),
              _QuickFilterChip(
                label: l10n.quickFilterLockedCount(lockedCount),
                selected: filter == _QuickTrophyFilter.locked,
                onTap: () => onFilterSelected(_QuickTrophyFilter.locked),
              ),
              _QuickFilterChip(
                label: l10n.quickFilterNearbyCount(nearbyCount),
                selected: filter == _QuickTrophyFilter.nearby,
                onTap: () => onFilterSelected(_QuickTrophyFilter.nearby),
              ),
              _QuickFilterChip(
                label: l10n.quickFilterHighXpCount(highXpCount),
                selected: filter == _QuickTrophyFilter.highXp,
                onTap: () => onFilterSelected(_QuickTrophyFilter.highXp),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _TierMiniBar(
                  label: l10n.tierBronze,
                  value: tierCounts[AchievementTier.bronze] ?? 0,
                  total: tierTotal,
                  color: AppColors.bronze,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TierMiniBar(
                  label: l10n.tierSilver,
                  value: tierCounts[AchievementTier.silver] ?? 0,
                  total: tierTotal,
                  color: AppColors.silver,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TierMiniBar(
                  label: l10n.tierGold,
                  value: tierCounts[AchievementTier.gold] ?? 0,
                  total: tierTotal,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TierMiniBar(
                  label: l10n.tierPlatinum,
                  value: tierCounts[AchievementTier.platinum] ?? 0,
                  total: tierTotal,
                  color: AppColors.platinum,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.bgCardLight.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(12),
            ),
            child: nextTarget == null
                ? Text(
                    l10n.allTrophiesInCategoryUnlocked,
                    style: const TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w600),
                  )
                : Row(
                    children: [
                      const Icon(LucideIcons.target, size: 15, color: AppColors.primaryLight),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.nextTargetLabel(RegistryL10n.achievementTitle(locale, nextTarget!.id, nextTarget!.title)),
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (nextTargetDistance != null)
                        Text(
                          formatDistance(nextTargetDistance!),
                          style: const TextStyle(color: AppColors.primaryLight, fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _QuickFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _QuickFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.18) : AppColors.bgCardLight.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primaryLight.withValues(alpha: 0.8) : AppColors.bgCardLight.withValues(alpha: 0.6),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.primaryLight : AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _TierMiniBar extends StatelessWidget {
  final String label;
  final int value;
  final int total;
  final Color color;

  const _TierMiniBar({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : value / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label $value',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AppColors.bgCardLight.withValues(alpha: 0.45),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  final _CategoryTab category;
  final int unlockedCount;
  final int totalCount;
  final double progress;

  const _HeroCard({
    required this.category,
    required this.unlockedCount,
    required this.totalCount,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: category.color.withValues(alpha: 0.3),
            blurRadius: 24,
            spreadRadius: -4,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Painted background ──
          CustomPaint(
            painter: _HeroPainter(
              gradient: category.heroGradient,
              accentColor: category.color,
              categoryId: category.id,
            ),
          ),
          // ── Content overlay ──
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Category emoji in a glass circle
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.15),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          category.emoji,
                          style: const TextStyle(fontSize: 26),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            category.subtitle,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // ── Progress section ──
                Row(
                  children: [
                    Text(
                      '$unlockedCount / $totalCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.nUnlocked,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    // XP reward badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.zap,
                            size: 13,
                            color: AppColors.xpGlow,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${(progress * 100).round()}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // ── Progress bar ──
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation(Colors.white.withValues(alpha: 0.9)),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05);
  }
}

// ── Hero Painter — category-specific background art ──
class _HeroPainter extends CustomPainter {
  final List<Color> gradient;
  final Color accentColor;
  final String categoryId;

  _HeroPainter({
    required this.gradient,
    required this.accentColor,
    required this.categoryId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Base gradient
    final bgPaint = Paint()
      ..shader = LinearGradient(
        colors: gradient,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    // Decorative elements based on category
    switch (categoryId) {
      case 'europe':
        _paintGlobeDecor(canvas, size);
        break;
      case 'capitals':
        _paintBuildingDecor(canvas, size);
        break;
      case 'national-parks':
        _paintMountainDecor(canvas, size);
        break;
      case 'ski-resorts':
        _paintSnowDecor(canvas, size);
        break;
      case 'ancient-sites':
        _paintTempleDecor(canvas, size);
        break;
      case 'tourist-destinations':
        _paintPlaneDecor(canvas, size);
        break;
    }

    // Atmospheric rim light top-right
    final rimPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.topRight,
        radius: 1.0,
        colors: [
          Colors.white.withValues(alpha: 0.08),
          Colors.transparent,
        ],
      ).createShader(rect);
    canvas.drawRect(rect, rimPaint);
  }

  void _paintGlobeDecor(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.82, size.height * 0.45);
    final radius = size.height * 0.42;

    // Globe sphere
    final spherePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        colors: [
          Colors.white.withValues(alpha: 0.12),
          Colors.white.withValues(alpha: 0.03),
          Colors.transparent,
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, spherePaint);

    // Grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (var i = -2; i <= 2; i++) {
      final offset = i * radius * 0.3;
      final w = math.sqrt(math.max(0, radius * radius - offset * offset));
      canvas.drawOval(
        Rect.fromCenter(center: center.translate(0, offset), width: w * 2, height: radius * 0.25),
        gridPaint,
      );
    }
  }

  void _paintBuildingDecor(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;

    // Skyline silhouette
    final path = Path();
    final bottom = size.height;
    final right = size.width;

    path.moveTo(right * 0.55, bottom);
    path.lineTo(right * 0.55, bottom * 0.4);
    path.lineTo(right * 0.58, bottom * 0.35);
    path.lineTo(right * 0.61, bottom * 0.4);
    path.lineTo(right * 0.61, bottom);
    // Second building
    path.lineTo(right * 0.65, bottom);
    path.lineTo(right * 0.65, bottom * 0.3);
    path.lineTo(right * 0.72, bottom * 0.3);
    path.lineTo(right * 0.72, bottom);
    // Third building (dome)
    path.lineTo(right * 0.76, bottom);
    path.lineTo(right * 0.76, bottom * 0.45);
    path.quadraticBezierTo(right * 0.82, bottom * 0.2, right * 0.88, bottom * 0.45);
    path.lineTo(right * 0.88, bottom);
    // Fourth building
    path.lineTo(right * 0.92, bottom);
    path.lineTo(right * 0.92, bottom * 0.35);
    path.lineTo(right, bottom * 0.35);
    path.lineTo(right, bottom);
    path.close();

    canvas.drawPath(path, paint);
  }

  void _paintMountainDecor(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width * 0.5, size.height);
    path.lineTo(size.width * 0.65, size.height * 0.2);
    path.lineTo(size.width * 0.7, size.height * 0.35);
    path.lineTo(size.width * 0.8, size.height * 0.15);
    path.lineTo(size.width * 0.95, size.height * 0.6);
    path.lineTo(size.width, size.height * 0.55);
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);

    // Snow caps
    final snowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final snowPath = Path();
    snowPath.moveTo(size.width * 0.62, size.height * 0.3);
    snowPath.lineTo(size.width * 0.65, size.height * 0.2);
    snowPath.lineTo(size.width * 0.68, size.height * 0.3);
    snowPath.close();
    canvas.drawPath(snowPath, snowPaint);

    final snowPath2 = Path();
    snowPath2.moveTo(size.width * 0.77, size.height * 0.25);
    snowPath2.lineTo(size.width * 0.8, size.height * 0.15);
    snowPath2.lineTo(size.width * 0.83, size.height * 0.25);
    snowPath2.close();
    canvas.drawPath(snowPath2, snowPaint);
  }

  void _paintSnowDecor(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08);

    final rng = math.Random(42);
    for (var i = 0; i < 30; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final r = 1.0 + rng.nextDouble() * 3;
      canvas.drawCircle(Offset(x, y), r, paint);
    }

    // Mountain silhouette
    final mountainPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width * 0.6, size.height);
    path.lineTo(size.width * 0.75, size.height * 0.25);
    path.lineTo(size.width * 0.85, size.height * 0.45);
    path.lineTo(size.width * 0.95, size.height * 0.2);
    path.lineTo(size.width, size.height * 0.5);
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, mountainPaint);
  }

  void _paintTempleDecor(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;

    // Temple / arch silhouette
    final path = Path();
    final cx = size.width * 0.8;
    final bottom = size.height;

    // Left pillar
    path.moveTo(cx - 40, bottom);
    path.lineTo(cx - 40, bottom * 0.35);
    // Arch
    path.quadraticBezierTo(cx, bottom * 0.1, cx + 40, bottom * 0.35);
    // Right pillar
    path.lineTo(cx + 40, bottom);
    path.close();
    canvas.drawPath(path, paint);

    // Radiating light lines
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final lightCenter = Offset(cx, bottom * 0.15);
    for (var i = 0; i < 8; i++) {
      final angle = -math.pi / 2 + (i - 3.5) * 0.18;
      final endX = lightCenter.dx + math.cos(angle) * size.height * 0.6;
      final endY = lightCenter.dy + math.sin(angle) * size.height * 0.6;
      canvas.drawLine(lightCenter, Offset(endX, endY), linePaint);
    }
  }

  void _paintPlaneDecor(Canvas canvas, Size size) {
    // Curved flight trail
    final trailPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    path.moveTo(size.width * 0.1, size.height * 0.8);
    path.quadraticBezierTo(
      size.width * 0.4, size.height * 0.1,
      size.width * 0.9, size.height * 0.3,
    );
    canvas.drawPath(path, trailPaint);

    // Dashed continuation
    final dashPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (var t = 0.0; t < 1.0; t += 0.04) {
      final x1 = size.width * (0.1 + t * 0.8);
      final y1 = size.height * (0.8 - math.sin(t * math.pi) * 0.5);
      canvas.drawCircle(Offset(x1, y1), 1.5, dashPaint..style = PaintingStyle.fill);
    }

    // Globe dots
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06);
    final rng = math.Random(7);
    for (var i = 0; i < 12; i++) {
      final x = size.width * 0.5 + rng.nextDouble() * size.width * 0.5;
      final y = rng.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), 2 + rng.nextDouble() * 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Flag data for each country/destination ──
class _FlagData {
  final String emoji;
  /// 'horizontal' or 'vertical' stripe direction, or 'custom' for special flags.
  final String type;
  final List<Color> stripes;

  const _FlagData(this.emoji, this.type, this.stripes);
}

const _countryFlags = <String, _FlagData>{
  // ── Europe ──
  'europe-france':       _FlagData('\u{1F1EB}\u{1F1F7}', 'vertical',   [Color(0xFF002395), Colors.white, Color(0xFFED2939)]),
  'europe-italy':        _FlagData('\u{1F1EE}\u{1F1F9}', 'vertical',   [Color(0xFF009246), Colors.white, Color(0xFFCE2B37)]),
  'europe-spain':        _FlagData('\u{1F1EA}\u{1F1F8}', 'horizontal', [Color(0xFFAA151B), Color(0xFFF1BF00), Color(0xFFAA151B)]),
  'europe-germany':      _FlagData('\u{1F1E9}\u{1F1EA}', 'horizontal', [Color(0xFF000000), Color(0xFFDD0000), Color(0xFFFFCC00)]),
  'europe-uk':           _FlagData('\u{1F1EC}\u{1F1E7}', 'custom',     [Color(0xFF012169), Color(0xFFFFFFFF), Color(0xFFC8102E)]),
  'europe-netherlands':  _FlagData('\u{1F1F3}\u{1F1F1}', 'horizontal', [Color(0xFFAE1C28), Colors.white, Color(0xFF21468B)]),
  'europe-greece':       _FlagData('\u{1F1EC}\u{1F1F7}', 'custom',     [Color(0xFF0D5EAF), Colors.white]),
  'europe-switzerland':  _FlagData('\u{1F1E8}\u{1F1ED}', 'custom',     [Color(0xFFFF0000), Colors.white]),
  'europe-portugal':     _FlagData('\u{1F1F5}\u{1F1F9}', 'vertical2',  [Color(0xFF006600), Color(0xFFFF0000)]),
  'europe-czech':        _FlagData('\u{1F1E8}\u{1F1FF}', 'custom',     [Colors.white, Color(0xFFD7141A), Color(0xFF11457E)]),
  'europe-austria':      _FlagData('\u{1F1E6}\u{1F1F9}', 'horizontal', [Color(0xFFED2939), Colors.white, Color(0xFFED2939)]),
  'europe-sweden':       _FlagData('\u{1F1F8}\u{1F1EA}', 'custom',     [Color(0xFF006AA7), Color(0xFFFECC00)]),
  'europe-norway':       _FlagData('\u{1F1F3}\u{1F1F4}', 'custom',     [Color(0xFFEF2B2D), Colors.white, Color(0xFF002868)]),
  'europe-denmark':      _FlagData('\u{1F1E9}\u{1F1F0}', 'custom',     [Color(0xFFC60C30), Colors.white]),
  'europe-poland':       _FlagData('\u{1F1F5}\u{1F1F1}', 'horizontal', [Colors.white, Color(0xFFDC143C)]),
  'europe-ireland':      _FlagData('\u{1F1EE}\u{1F1EA}', 'vertical',   [Color(0xFF169B62), Colors.white, Color(0xFFFF883E)]),
  'europe-croatia':      _FlagData('\u{1F1ED}\u{1F1F7}', 'horizontal', [Color(0xFFFF0000), Colors.white, Color(0xFF171796)]),
  'europe-hungary':      _FlagData('\u{1F1ED}\u{1F1FA}', 'horizontal', [Color(0xFFCE2939), Colors.white, Color(0xFF477050)]),
  'europe-belgium':      _FlagData('\u{1F1E7}\u{1F1EA}', 'vertical',   [Color(0xFF000000), Color(0xFFFAE042), Color(0xFFED2939)]),
  'europe-turkey':       _FlagData('\u{1F1F9}\u{1F1F7}', 'custom',     [Color(0xFFE30A17), Colors.white]),
  'europe-finland':      _FlagData('\u{1F1EB}\u{1F1EE}', 'custom',     [Colors.white, Color(0xFF003580)]),
  'europe-romania':      _FlagData('\u{1F1F7}\u{1F1F4}', 'vertical',   [Color(0xFF002B7F), Color(0xFFFCD116), Color(0xFFCE1126)]),
  'europe-iceland':      _FlagData('\u{1F1EE}\u{1F1F8}', 'custom',     [Color(0xFF02529C), Colors.white, Color(0xFFDC1E35)]),
  'europe-slovenia':     _FlagData('\u{1F1F8}\u{1F1EE}', 'horizontal', [Colors.white, Color(0xFF003DA5), Color(0xFFED1C24)]),
  'europe-slovakia':     _FlagData('\u{1F1F8}\u{1F1F0}', 'horizontal', [Colors.white, Color(0xFF0B4EA2), Color(0xFFEE1C25)]),
  'europe-serbia':       _FlagData('\u{1F1F7}\u{1F1F8}', 'horizontal', [Color(0xFFC6363C), Color(0xFF0C4076), Colors.white]),
  'europe-bulgaria':     _FlagData('\u{1F1E7}\u{1F1EC}', 'horizontal', [Colors.white, Color(0xFF00966E), Color(0xFFD62612)]),
  'europe-cyprus':       _FlagData('\u{1F1E8}\u{1F1FE}', 'custom',     [Colors.white, Color(0xFFD47600)]),
  'europe-malta':        _FlagData('\u{1F1F2}\u{1F1F9}', 'vertical',   [Colors.white, Color(0xFFCF142B)]),
  'europe-luxembourg':   _FlagData('\u{1F1F1}\u{1F1FA}', 'horizontal', [Color(0xFFEF3340), Colors.white, Color(0xFF00A3E0)]),
  // ── Americas (all US) ──
  'americas-nyc':        _FlagData('\u{1F1FA}\u{1F1F8}', 'custom',     [Color(0xFF3C3B6E), Colors.white, Color(0xFFB22234)]),
  'americas-california': _FlagData('\u{1F1FA}\u{1F1F8}', 'custom',     [Color(0xFF3C3B6E), Colors.white, Color(0xFFB22234)]),
  'americas-florida':    _FlagData('\u{1F1FA}\u{1F1F8}', 'custom',     [Color(0xFF3C3B6E), Colors.white, Color(0xFFB22234)]),
  'americas-hawaii':     _FlagData('\u{1F1FA}\u{1F1F8}', 'custom',     [Color(0xFF3C3B6E), Colors.white, Color(0xFFB22234)]),
  'americas-grand-canyon': _FlagData('\u{1F1FA}\u{1F1F8}', 'custom',   [Color(0xFF3C3B6E), Colors.white, Color(0xFFB22234)]),
  // ── Combined US card ──
  'americas-usa':          _FlagData('\u{1F1FA}\u{1F1F8}', 'custom',   [Color(0xFF3C3B6E), Colors.white, Color(0xFFB22234)]),
};

// ── Country Flag Card — grid card filled with the country's flag ──
class _CountryFlagCard extends StatelessWidget {
  final Achievement achievement;
  final int index;
  final VoidCallback onTap;

  const _CountryFlagCard({
    required this.achievement,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final isUnlocked = achievement.isUnlocked;
    final flag = _countryFlags[achievement.id];

    return ScaleTap(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isUnlocked
                ? AppColors.success.withValues(alpha: 0.5)
                : AppColors.bgCardLight.withValues(alpha: 0.4),
            width: isUnlocked ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isUnlocked
                  ? AppColors.success.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Flag background ──
            if (flag != null)
              CustomPaint(
                painter: _FlagPainter(flag: flag, desaturate: !isUnlocked),
              )
            else
              Container(color: AppColors.bgCard),
            // ── Dark gradient overlay for text readability ──
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: isUnlocked ? 0.15 : 0.5),
                    Colors.black.withValues(alpha: isUnlocked ? 0.55 : 0.7),
                  ],
                ),
              ),
            ),
            // ── Content overlay ──
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top: flag emoji + status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (flag != null)
                        Text(flag.emoji, style: const TextStyle(fontSize: 22)),
                      if (isUnlocked)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(LucideIcons.check, size: 12, color: Colors.white),
                        )
                      else
                        Icon(
                          LucideIcons.lock,
                          size: 16,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                    ],
                  ),
                  const Spacer(),
                  // Bottom: country name + XP
                  Text(
                    RegistryL10n.achievementTitle(locale, achievement.id, achievement.title),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: isUnlocked ? 1.0 : 0.8),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                      shadows: const [
                        Shadow(color: Colors.black54, blurRadius: 6),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // XP badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.xpGreen.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.zap, size: 10, color: AppColors.xpGlow),
                            const SizedBox(width: 3),
                            Text(
                              '+${achievement.xpReward}',
                              style: TextStyle(
                                color: AppColors.xpGlow,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
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
    ).animate().fadeIn(duration: 350.ms, delay: (index * 60).ms).scale(begin: const Offset(0.95, 0.95));
  }
}

// ── Flag Painter — draws simplified country flags ──
class _FlagPainter extends CustomPainter {
  final _FlagData flag;
  final bool desaturate;

  _FlagPainter({required this.flag, this.desaturate = false});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final colors = flag.stripes;

    switch (flag.type) {
      case 'horizontal':
        _paintHorizontalStripes(canvas, size, colors);
        break;
      case 'vertical':
        _paintVerticalStripes(canvas, size, colors);
        break;
      case 'vertical2':
        _paintVerticalStripes2(canvas, size, colors);
        break;
      case 'custom':
        _paintCustomFlag(canvas, size, colors);
        break;
    }

    // Desaturate overlay for locked achievements
    if (desaturate) {
      canvas.drawRect(
        rect,
        Paint()..color = const Color(0xFF1A1A2E).withValues(alpha: 0.45),
      );
    }
  }

  void _paintHorizontalStripes(Canvas canvas, Size size, List<Color> colors) {
    final stripeH = size.height / colors.length;
    for (var i = 0; i < colors.length; i++) {
      canvas.drawRect(
        Rect.fromLTWH(0, i * stripeH, size.width, stripeH),
        Paint()..color = colors[i],
      );
    }
  }

  void _paintVerticalStripes(Canvas canvas, Size size, List<Color> colors) {
    final stripeW = size.width / colors.length;
    for (var i = 0; i < colors.length; i++) {
      canvas.drawRect(
        Rect.fromLTWH(i * stripeW, 0, stripeW, size.height),
        Paint()..color = colors[i],
      );
    }
  }

  void _paintVerticalStripes2(Canvas canvas, Size size, List<Color> colors) {
    // Portugal style: green (2/5) + red (3/5)
    final divider = size.width * 0.4;
    canvas.drawRect(Rect.fromLTWH(0, 0, divider, size.height), Paint()..color = colors[0]);
    canvas.drawRect(Rect.fromLTWH(divider, 0, size.width - divider, size.height), Paint()..color = colors[1]);
  }

  void _paintCustomFlag(Canvas canvas, Size size, List<Color> colors) {
    final id = flag.emoji;
    // Detect which flag by emoji and draw accordingly
    if (colors.length == 3 && colors[0] == const Color(0xFF3C3B6E)) {
      // ── USA ──
      _paintUSA(canvas, size, colors);
    } else if (colors.length == 3 && colors[0] == const Color(0xFF012169)) {
      // ── UK ──
      _paintUK(canvas, size, colors);
    } else if (colors.length == 2 && colors[0] == const Color(0xFF0D5EAF)) {
      // ── Greece ──
      _paintGreece(canvas, size, colors);
    } else if (colors.length == 2 && colors[0] == const Color(0xFFFF0000)) {
      // ── Switzerland ──
      _paintSwitzerland(canvas, size, colors);
    } else if (colors.length == 3 && colors[0] == Colors.white && colors[2] == const Color(0xFF11457E)) {
      // ── Czech Republic ──
      _paintCzech(canvas, size, colors);
    } else if (colors.length == 2 && colors[0] == const Color(0xFF006AA7)) {
      // ── Sweden ──
      _paintSweden(canvas, size, colors);
    } else if (colors.length == 3 && colors[0] == const Color(0xFFEF2B2D) && colors[2] == const Color(0xFF002868)) {
      // ── Norway ──
      _paintNorway(canvas, size, colors);
    } else if (colors.length == 2 && colors[0] == const Color(0xFFC60C30)) {
      // ── Denmark ──
      _paintDenmark(canvas, size, colors);
    } else if (colors.length == 2 && colors[0] == const Color(0xFFE30A17)) {
      // ── Turkey ──
      _paintTurkey(canvas, size, colors);
    } else if (colors.length == 2 && colors[0] == Colors.white && colors[1] == const Color(0xFF003580)) {
      // ── Finland ──
      _paintFinland(canvas, size, colors);
    } else if (colors.length == 3 && colors[0] == const Color(0xFF02529C) && colors[2] == const Color(0xFFDC1E35)) {
      // ── Iceland ──
      _paintIceland(canvas, size, colors);
    } else if (colors.length == 2 && colors[0] == Colors.white && colors[1] == const Color(0xFFD47600)) {
      // ── Cyprus ──
      _paintCyprus(canvas, size, colors);
    } else {
      // Fallback: horizontal stripes
      _paintHorizontalStripes(canvas, size, colors);
    }
  }

  void _paintUSA(Canvas canvas, Size size, List<Color> colors) {
    final stripeH = size.height / 13;
    // 13 alternating red & white stripes
    for (var i = 0; i < 13; i++) {
      canvas.drawRect(
        Rect.fromLTWH(0, i * stripeH, size.width, stripeH),
        Paint()..color = (i.isEven ? colors[2] : colors[1]),
      );
    }
    // Blue canton (top-left)
    final cantonW = size.width * 0.4;
    final cantonH = stripeH * 7;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, cantonW, cantonH),
      Paint()..color = colors[0],
    );
    // Stars (simplified as dots)
    final starPaint = Paint()..color = Colors.white;
    final rng = math.Random(50);
    for (var row = 0; row < 5; row++) {
      for (var col = 0; col < 6; col++) {
        final cx = cantonW * 0.1 + col * (cantonW * 0.15);
        final cy = cantonH * 0.12 + row * (cantonH * 0.19);
        canvas.drawCircle(Offset(cx, cy), 2.2, starPaint);
      }
    }
  }

  void _paintUK(Canvas canvas, Size size, List<Color> colors) {
    // Blue background
    canvas.drawRect(Offset.zero & size, Paint()..color = colors[0]);

    final cx = size.width / 2;
    final cy = size.height / 2;
    final paint = Paint()..style = PaintingStyle.stroke;

    // White diagonals (thick)
    paint.color = colors[1];
    paint.strokeWidth = size.height * 0.12;
    canvas.drawLine(Offset.zero, Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), paint);

    // Red diagonals (thin)
    paint.color = colors[2];
    paint.strokeWidth = size.height * 0.06;
    canvas.drawLine(Offset.zero, Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), paint);

    // White cross (thick)
    paint.color = colors[1];
    paint.strokeWidth = size.height * 0.2;
    canvas.drawLine(Offset(cx, 0), Offset(cx, size.height), paint);
    canvas.drawLine(Offset(0, cy), Offset(size.width, cy), paint);

    // Red cross (thin)
    paint.color = colors[2];
    paint.strokeWidth = size.height * 0.12;
    canvas.drawLine(Offset(cx, 0), Offset(cx, size.height), paint);
    canvas.drawLine(Offset(0, cy), Offset(size.width, cy), paint);
  }

  void _paintGreece(Canvas canvas, Size size, List<Color> colors) {
    final stripeH = size.height / 9;
    // 9 alternating blue/white stripes
    for (var i = 0; i < 9; i++) {
      canvas.drawRect(
        Rect.fromLTWH(0, i * stripeH, size.width, stripeH),
        Paint()..color = (i.isEven ? colors[0] : colors[1]),
      );
    }
    // Blue canton with white cross (top-left, 5 stripes high)
    final cantonSize = stripeH * 5;
    canvas.drawRect(Rect.fromLTWH(0, 0, cantonSize, cantonSize), Paint()..color = colors[0]);
    // White cross
    final crossW = stripeH * 0.8;
    canvas.drawRect(
      Rect.fromLTWH(cantonSize / 2 - crossW / 2, 0, crossW, cantonSize),
      Paint()..color = colors[1],
    );
    canvas.drawRect(
      Rect.fromLTWH(0, cantonSize / 2 - crossW / 2, cantonSize, crossW),
      Paint()..color = colors[1],
    );
  }

  void _paintSwitzerland(Canvas canvas, Size size, List<Color> colors) {
    // Red background
    canvas.drawRect(Offset.zero & size, Paint()..color = colors[0]);
    // White cross
    final crossW = size.width * 0.15;
    final crossH = size.height * 0.5;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final paint = Paint()..color = colors[1];
    // Vertical bar
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy), width: crossW, height: crossH),
        const Radius.circular(2),
      ),
      paint,
    );
    // Horizontal bar
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy), width: crossH, height: crossW),
        const Radius.circular(2),
      ),
      paint,
    );
  }

  void _paintCzech(Canvas canvas, Size size, List<Color> colors) {
    // Top half white, bottom half red
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height / 2), Paint()..color = colors[0]);
    canvas.drawRect(Rect.fromLTWH(0, size.height / 2, size.width, size.height / 2), Paint()..color = colors[1]);
    // Blue triangle on left
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.5, size.height / 2)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = colors[2]);
  }

  void _paintSweden(Canvas canvas, Size size, List<Color> colors) {
    // Blue background
    canvas.drawRect(Offset.zero & size, Paint()..color = colors[0]);
    // Yellow Scandinavian cross
    final crossW = size.height * 0.16;
    final cx = size.width * 0.36;
    final cy = size.height / 2;
    final paint = Paint()..color = colors[1];
    canvas.drawRect(Rect.fromLTWH(cx - crossW / 2, 0, crossW, size.height), paint);
    canvas.drawRect(Rect.fromLTWH(0, cy - crossW / 2, size.width, crossW), paint);
  }

  void _paintNorway(Canvas canvas, Size size, List<Color> colors) {
    // Red background
    canvas.drawRect(Offset.zero & size, Paint()..color = colors[0]);
    // White Scandinavian cross (thick)
    final crossW = size.height * 0.22;
    final cx = size.width * 0.36;
    final cy = size.height / 2;
    final whitePaint = Paint()..color = colors[1];
    canvas.drawRect(Rect.fromLTWH(cx - crossW / 2, 0, crossW, size.height), whitePaint);
    canvas.drawRect(Rect.fromLTWH(0, cy - crossW / 2, size.width, crossW), whitePaint);
    // Blue cross (thin, inside white)
    final blueW = size.height * 0.12;
    final bluePaint = Paint()..color = colors[2];
    canvas.drawRect(Rect.fromLTWH(cx - blueW / 2, 0, blueW, size.height), bluePaint);
    canvas.drawRect(Rect.fromLTWH(0, cy - blueW / 2, size.width, blueW), bluePaint);
  }

  void _paintDenmark(Canvas canvas, Size size, List<Color> colors) {
    // Red background
    canvas.drawRect(Offset.zero & size, Paint()..color = colors[0]);
    // White Scandinavian cross
    final crossW = size.height * 0.16;
    final cx = size.width * 0.36;
    final cy = size.height / 2;
    final paint = Paint()..color = colors[1];
    canvas.drawRect(Rect.fromLTWH(cx - crossW / 2, 0, crossW, size.height), paint);
    canvas.drawRect(Rect.fromLTWH(0, cy - crossW / 2, size.width, crossW), paint);
  }

  void _paintTurkey(Canvas canvas, Size size, List<Color> colors) {
    // Red background
    canvas.drawRect(Offset.zero & size, Paint()..color = colors[0]);
    // White crescent and star
    final cx = size.width * 0.42;
    final cy = size.height / 2;
    final r = size.height * 0.28;
    final paint = Paint()..color = colors[1];
    // Full moon
    canvas.drawCircle(Offset(cx, cy), r, paint);
    // Cutout (crescent) — slightly offset red circle
    canvas.drawCircle(Offset(cx + r * 0.3, cy), r * 0.8, Paint()..color = colors[0]);
    // Star (simplified as a small circle)
    canvas.drawCircle(Offset(cx + r * 0.85, cy), r * 0.18, paint);
  }

  void _paintFinland(Canvas canvas, Size size, List<Color> colors) {
    // White background
    canvas.drawRect(Offset.zero & size, Paint()..color = colors[0]);
    // Blue Scandinavian cross
    final crossW = size.height * 0.16;
    final cx = size.width * 0.36;
    final cy = size.height / 2;
    final paint = Paint()..color = colors[1];
    canvas.drawRect(Rect.fromLTWH(cx - crossW / 2, 0, crossW, size.height), paint);
    canvas.drawRect(Rect.fromLTWH(0, cy - crossW / 2, size.width, crossW), paint);
  }

  void _paintIceland(Canvas canvas, Size size, List<Color> colors) {
    // Blue background
    canvas.drawRect(Offset.zero & size, Paint()..color = colors[0]);
    // White Scandinavian cross (thick)
    final crossW = size.height * 0.22;
    final cx = size.width * 0.36;
    final cy = size.height / 2;
    final whitePaint = Paint()..color = colors[1];
    canvas.drawRect(Rect.fromLTWH(cx - crossW / 2, 0, crossW, size.height), whitePaint);
    canvas.drawRect(Rect.fromLTWH(0, cy - crossW / 2, size.width, crossW), whitePaint);
    // Red cross (thin, inside white)
    final redW = size.height * 0.12;
    final redPaint = Paint()..color = colors[2];
    canvas.drawRect(Rect.fromLTWH(cx - redW / 2, 0, redW, size.height), redPaint);
    canvas.drawRect(Rect.fromLTWH(0, cy - redW / 2, size.width, redW), redPaint);
  }

  void _paintCyprus(Canvas canvas, Size size, List<Color> colors) {
    // White background
    canvas.drawRect(Offset.zero & size, Paint()..color = colors[0]);
    // Simplified copper-orange island shape in center
    final cx = size.width / 2;
    final cy = size.height * 0.45;
    final paint = Paint()..color = colors[1];
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: size.width * 0.4, height: size.height * 0.25),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _FlagPainter oldDelegate) =>
      oldDelegate.desaturate != desaturate;
}

// ── Achievement Row — compact card for each achievement ──
class _AchievementRow extends StatelessWidget {
  final Achievement achievement;
  final double? distance;
  final Color categoryColor;
  final int index;
  final VoidCallback onTap;

  const _AchievementRow({
    required this.achievement,
    this.distance,
    required this.categoryColor,
    required this.index,
    required this.onTap,
  });

  Color get _tierColor => switch (achievement.tier) {
    AchievementTier.bronze => AppColors.bronze,
    AchievementTier.silver => AppColors.silver,
    AchievementTier.gold => AppColors.gold,
    AchievementTier.platinum => AppColors.platinum,
  };

  String get _tierLabel => switch (achievement.tier) {
    AchievementTier.bronze => 'BRONZE',
    AchievementTier.silver => 'SILVER',
    AchievementTier.gold => 'GOLD',
    AchievementTier.platinum => 'PLATINUM',
  };

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.round()} m';
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final isUnlocked = achievement.isUnlocked;

    return ScaleTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnlocked
                ? _tierColor.withValues(alpha: 0.4)
                : AppColors.bgCardLight.withValues(alpha: 0.5),
            width: isUnlocked ? 1.5 : 1,
          ),
          boxShadow: isUnlocked
              ? [
                  BoxShadow(
                    color: _tierColor.withValues(alpha: 0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // ── Left: icon/status indicator ──
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: isUnlocked
                    ? LinearGradient(
                        colors: [
                          _tierColor.withValues(alpha: 0.25),
                          _tierColor.withValues(alpha: 0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [
                          AppColors.bgCardLight.withValues(alpha: 0.8),
                          AppColors.bgCardLight.withValues(alpha: 0.4),
                        ],
                      ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isUnlocked
                      ? _tierColor.withValues(alpha: 0.3)
                      : AppColors.bgCardLight.withValues(alpha: 0.3),
                ),
              ),
              child: Center(
                child: isUnlocked
                    ? Icon(LucideIcons.check, color: _tierColor, size: 22)
                    : Icon(
                        LucideIcons.lock,
                        color: AppColors.textMuted.withValues(alpha: 0.5),
                        size: 18,
                      ),
              ),
            ),
            const SizedBox(width: 14),
            // ── Center: title + description ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    RegistryL10n.achievementTitle(locale, achievement.id, achievement.title),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isUnlocked ? AppColors.textPrimary : AppColors.textSecondary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    RegistryL10n.achievementDescription(locale, achievement.id, achievement.description),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // ── Tags row ──
                  Row(
                    children: [
                      // Tier badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: _tierColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _tierLabel,
                          style: TextStyle(
                            color: _tierColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Distance or unlocked date
                      if (isUnlocked && achievement.unlockedAt != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.calendarCheck, size: 10, color: AppColors.success.withValues(alpha: 0.7)),
                            const SizedBox(width: 3),
                            Text(
                              DateFormat.yMMMd(locale.languageCode).format(achievement.unlockedAt!),
                              style: TextStyle(
                                color: AppColors.success.withValues(alpha: 0.8),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        )
                      else if (distance != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.navigation, size: 10, color: AppColors.primaryLight.withValues(alpha: 0.7)),
                            const SizedBox(width: 3),
                            Text(
                              _formatDistance(distance!),
                              style: TextStyle(
                                color: AppColors.primaryLight.withValues(alpha: 0.8),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // ── Right: XP reward ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isUnlocked
                      ? [
                          AppColors.xpGreen.withValues(alpha: 0.2),
                          AppColors.xpGlow.withValues(alpha: 0.1),
                        ]
                      : [
                          AppColors.xpGreen.withValues(alpha: 0.08),
                          AppColors.xpGreen.withValues(alpha: 0.03),
                        ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.xpGreen.withValues(alpha: isUnlocked ? 0.3 : 0.12),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.zap,
                    size: 12,
                    color: isUnlocked ? AppColors.xpGlow : AppColors.xpGreen.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '+${achievement.xpReward}',
                    style: TextStyle(
                      color: isUnlocked ? AppColors.xpGlow : AppColors.xpGreen.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: (index * 40).ms).slideX(begin: 0.03);
  }
}

// ── Pending Claims Banner ──

class _PendingClaimsBanner extends ConsumerWidget {
  const _PendingClaimsBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievements = ref.watch(achievementsProvider);
    final pending = achievements.allAchievements
        .where((a) => a.isPendingClaim && !a.isUnlocked)
        .toList();

    if (pending.isEmpty) return const SizedBox.shrink();

    final locale = Localizations.localeOf(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.gold.withValues(alpha: 0.15),
              AppColors.accent.withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: Row(
                children: [
                  Icon(LucideIcons.bell, size: 16, color: AppColors.gold),
                  const SizedBox(width: 8),
                  Text(
                    '${pending.length} ${pending.length == 1 ? 'trophy' : 'trophies'} ready to claim!',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 68,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                itemCount: pending.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final achievement = pending[index];
                  return _PendingClaimChip(
                    achievement: achievement,
                    locale: locale,
                    onClaim: () {
                      ref
                          .read(achievementsProvider.notifier)
                          .confirmPendingClaim(achievement.id);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1);
  }
}

class _PendingClaimChip extends StatelessWidget {
  final Achievement achievement;
  final Locale locale;
  final VoidCallback onClaim;

  const _PendingClaimChip({
    required this.achievement,
    required this.locale,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bgCardLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.trophy, size: 16, color: AppColors.gold),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: Text(
              RegistryL10n.achievementTitle(locale, achievement.id, achievement.title),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onClaim,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Claim',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
