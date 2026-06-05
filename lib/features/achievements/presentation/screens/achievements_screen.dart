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
import 'package:travel_buddy_mobile/shared/widgets/achievement_unlock_popup.dart';
import 'package:travel_buddy_mobile/features/achievements/presentation/widgets/achievement_detail_sheet.dart';

// ══════════════════════════════════════════════════════════════
// Constants
// ══════════════════════════════════════════════════════════════

const _continentCollectionIds = {
  'europe', 'americas', 'africa', 'asia', 'south-america', 'oceania'
};
const _themedCollectionIds = {
  'national-parks', 'ski-resorts', 'capitals', 'ancient-sites',
  'holy-sites', 'seas', 'tourist-destinations'
};
const _localCollectionIds = {'landmarks', 'beaches', 'parks', 'culture'};

// Geographic difficulty tiers — each level in the cascade
enum _GeoTier { zone, country, continent, global }

Color _geoTierColor(_GeoTier tier) => switch (tier) {
  _GeoTier.zone => AppColors.bronze,
  _GeoTier.country => AppColors.silver,
  _GeoTier.continent => AppColors.gold,
  _GeoTier.global => AppColors.platinum,
};

String _geoTierLabel(_GeoTier tier) => switch (tier) {
  _GeoTier.zone => 'Zone',
  _GeoTier.country => 'Country',
  _GeoTier.continent => 'Continent',
  _GeoTier.global => 'Earth',
};

class _ContinentInfo {
  final String id;
  final String label;
  final String emoji;
  const _ContinentInfo(
      {required this.id, required this.label, required this.emoji});
}

const _continents = [
  _ContinentInfo(id: 'europe', label: 'Europe', emoji: '\u{1F30D}'),
  _ContinentInfo(id: 'asia', label: 'Asia', emoji: '\u{1F30F}'),
  _ContinentInfo(id: 'africa', label: 'Africa', emoji: '\u{1F30D}'),
  _ContinentInfo(id: 'americas', label: 'North America', emoji: '\u{1F30E}'),
  _ContinentInfo(
      id: 'south-america', label: 'South America', emoji: '\u{1F30E}'),
  _ContinentInfo(id: 'oceania', label: 'Oceania', emoji: '\u{1F30F}'),
];

/// Map continent id → adjectival form for section labels like "European Countries".
const _continentAdjective = <String, String>{
  'europe': 'European',
  'asia': 'Asian',
  'africa': 'African',
  'americas': 'North American',
  'south-america': 'South American',
  'oceania': 'Oceanian',
};

const _countryToContinent = <String, String>{
  'france': 'europe', 'italy': 'europe', 'spain': 'europe',
  'germany': 'europe', 'uk': 'europe', 'netherlands': 'europe',
  'greece': 'europe', 'switzerland': 'europe', 'portugal': 'europe',
  'austria': 'europe', 'croatia': 'europe', 'turkey': 'europe',
  'usa': 'americas', 'canada': 'americas', 'mexico': 'americas',
  'chile': 'south-america', 'peru': 'south-america',
  'south-africa': 'africa', 'egypt': 'africa',
  'japan': 'asia', 'india': 'asia', 'cambodia': 'asia',
  'saudi-arabia': 'asia', 'israel': 'asia', 'uae': 'asia',
  'thailand': 'asia', 'singapore': 'asia', 'indonesia': 'asia',
  'nepal': 'asia', 'china': 'asia', 'pakistan': 'asia',
  'sri-lanka': 'asia', 'myanmar': 'asia',
  'morocco': 'africa', 'ethiopia': 'africa',
  'united-kingdom': 'europe',
  'australia': 'oceania', 'new-zealand': 'oceania',
};

const _countryLabels = <String, String>{
  'france': 'France', 'italy': 'Italy', 'spain': 'Spain',
  'germany': 'Germany', 'uk': 'United Kingdom', 'netherlands': 'Netherlands',
  'greece': 'Greece', 'switzerland': 'Switzerland', 'portugal': 'Portugal',
  'austria': 'Austria', 'croatia': 'Croatia', 'turkey': 'Turkey',
  'usa': 'United States', 'canada': 'Canada', 'mexico': 'Mexico',
  'chile': 'Chile', 'peru': 'Peru',
  'south-africa': 'South Africa', 'egypt': 'Egypt',
  'japan': 'Japan', 'india': 'India', 'cambodia': 'Cambodia',
  'saudi-arabia': 'Saudi Arabia', 'israel': 'Israel', 'uae': 'UAE',
  'thailand': 'Thailand', 'singapore': 'Singapore', 'indonesia': 'Indonesia',
  'nepal': 'Nepal', 'china': 'China', 'pakistan': 'Pakistan',
  'sri-lanka': 'Sri Lanka', 'myanmar': 'Myanmar',
  'morocco': 'Morocco', 'ethiopia': 'Ethiopia',
  'united-kingdom': 'United Kingdom',
  'australia': 'Australia', 'new-zealand': 'New Zealand',
};

const _themedLabels = <String, String>{
  'national-parks': 'All National Parks on Earth',
  'ski-resorts': 'All Ski Resorts on Earth',
  'capitals': 'All Capitals on Earth',
  'ancient-sites': 'All Ancient Sites on Earth',
  'holy-sites': 'All Holy Sites on Earth',
  'seas': 'All Seas on Earth',
  'tourist-destinations': 'All Destinations on Earth',
};

const _themedIcons = <String, IconData>{
  'national-parks': LucideIcons.trees,
  'ski-resorts': LucideIcons.snowflake,
  'capitals': LucideIcons.building2,
  'ancient-sites': LucideIcons.church,
  'holy-sites': LucideIcons.church,
  'seas': LucideIcons.waves,
  'tourist-destinations': LucideIcons.mapPin,
};

const _localLabels = <String, String>{
  'landmarks': 'Landmarks',
  'beaches': 'Beaches',
  'parks': 'Parks',
  'culture': 'Culture',
};

const _localIcons = <String, IconData>{
  'landmarks': LucideIcons.landmark,
  'beaches': LucideIcons.umbrella,
  'parks': LucideIcons.palmtree,
  'culture': LucideIcons.palette,
};

// ── Helpers ──

/// Derive continent for a themed-collection achievement via its tags.
String? _continentOfThemed(Achievement a) {
  for (final tag in a.tags) {
    if (_continentCollectionIds.contains(tag)) return tag;
    final mapped = _countryToContinent[tag];
    if (mapped != null) return mapped;
  }
  return null;
}

/// Extract the country tag from a themed-collection achievement.
String? _countryOf(Achievement a) {
  for (final tag in a.tags) {
    if (_countryToContinent.containsKey(tag)) return tag;
  }
  return null;
}

/// Unified country key for any achievement (works across collection types).
String? _countryKey(Achievement a) {
  // Countries collection: extract from ID  e.g. "europe-france" → "france"
  if (_continentCollectionIds.contains(a.collectionId)) {
    final prefix = '${a.collectionId}-';
    if (a.id.startsWith(prefix)) return a.id.substring(prefix.length);
    return null;
  }
  // Themed collection: extract from tags
  return _countryOf(a);
}

/// Unified continent key for any achievement.
String? _continentKey(Achievement a) {
  if (_continentCollectionIds.contains(a.collectionId)) {
    return a.collectionId;
  }
  return _continentOfThemed(a);
}

// ══════════════════════════════════════════════════════════════
// Main Screen
// ══════════════════════════════════════════════════════════════

class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() =>
      _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
            child: Text(
              l10n.navAchievements,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const _AchievementsPendingClaims(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.bgCardLight.withValues(alpha: 0.5)),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicatorColor: Colors.transparent,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(colors: [
                    AppColors.primary.withValues(alpha: 0.2),
                    AppColors.primaryLight.withValues(alpha: 0.1),
                  ]),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.4)),
                ),
                indicatorPadding: const EdgeInsets.all(2),
                labelColor: AppColors.primaryLight,
                unselectedLabelColor: AppColors.textMuted,
                labelStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700),
                unselectedLabelStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.compass, size: 16),
                        const SizedBox(width: 6),
                        Text(l10n.navExplore),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.calendarClock, size: 16),
                        const SizedBox(width: 6),
                        Text(l10n.unlockTimeline),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _ExploreTab(),
                _AchievementTimelineTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Explore Tab
// ══════════════════════════════════════════════════════════════

class _ExploreTab extends ConsumerStatefulWidget {
  const _ExploreTab();

  @override
  ConsumerState<_ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends ConsumerState<_ExploreTab> {
  String? _selectedContinent;
  String? _selectedCountry;

  bool _matchesFilter(Achievement a) {
    if (_localCollectionIds.contains(a.collectionId)) return true;
    if (a.collectionId == 'continents' || a.collectionId == 'zones') return true;
    if (_selectedContinent != null) {
      if (_continentKey(a) != _selectedContinent) return false;
    }
    if (_selectedCountry != null) {
      if (_countryKey(a) != _selectedCountry) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(achievementsProvider).allAchievements;

    // Build dynamic country labels from Countries collection IDs
    final countryLabelsMap = <String, String>{..._countryLabels};
    for (final a in all) {
      if (_continentCollectionIds.contains(a.collectionId)) {
        final key = _countryKey(a);
        if (key != null) countryLabelsMap.putIfAbsent(key, () => a.title);
      }
    }

    // Available countries for selected continent
    List<MapEntry<String, String>> availableCountries = [];
    if (_selectedContinent != null) {
      final countryKeys = <String>{};
      for (final a in all) {
        if (_localCollectionIds.contains(a.collectionId)) continue;
        if (_continentKey(a) != _selectedContinent) continue;
        final ck = _countryKey(a);
        if (ck != null) countryKeys.add(ck);
      }
      availableCountries = countryKeys
          .map((k) => MapEntry(k, countryLabelsMap[k] ?? k))
          .toList()
        ..sort((a, b) => a.value.compareTo(b.value));
    }

    // Apply filter
    final filtered = all.where(_matchesFilter).toList();

    // ── Group achievements by geographic tier ──

    // GLOBAL: Countries collection + themed collections
    final globalAchievements = filtered
        .where((a) =>
            _continentCollectionIds.contains(a.collectionId) ||
            _themedCollectionIds.contains(a.collectionId))
        .toList();

    // CONTINENTAL: continents collection
    final continentalAchievements = filtered
        .where((a) => a.collectionId == 'continents')
        .toList();

    // COUNTRY: Countries collection grouped per-country (reuse from global)
    final countryAchievements = filtered
        .where((a) => _continentCollectionIds.contains(a.collectionId))
        .toList();

    // ZONE: zones + local collections
    final zoneAchievements = filtered
        .where((a) =>
            a.collectionId == 'zones' ||
            _localCollectionIds.contains(a.collectionId))
        .toList();

    // Build themed sub-collections for global tier
    final themed = <String, List<Achievement>>{};
    for (final a in filtered) {
      if (_themedCollectionIds.contains(a.collectionId)) {
        themed.putIfAbsent(a.collectionId!, () => []).add(a);
      }
    }

    // Build local sub-collections for zone tier
    final local = <String, List<Achievement>>{};
    for (final a in filtered) {
      if (_localCollectionIds.contains(a.collectionId)) {
        local.putIfAbsent(a.collectionId!, () => []).add(a);
      }
    }

    final zonesOnly = filtered
        .where((a) => a.collectionId == 'zones')
        .toList();

    final totalAll = all.length;
    final unlockedAll = all.where((a) => a.isUnlocked).length;

    final hasFilter = _selectedContinent != null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      children: [
        // Filter bar
        _FilterBar(
          selectedContinent: _selectedContinent,
          selectedCountry: _selectedCountry,
          availableCountries: availableCountries,
          onContinentChanged: (c) => setState(() {
            _selectedContinent = c;
            _selectedCountry = null;
          }),
          onCountryChanged: (c) => setState(() {
            _selectedCountry = c;
          }),
        ),
        const SizedBox(height: 12),

        // Progress card
        _GlobalProgressCard(
          total: hasFilter
              ? filtered.length
              : totalAll,
          unlocked: hasFilter
              ? filtered.where((a) => a.isUnlocked).length
              : unlockedAll,
          label: hasFilter ? 'Filtered Progress' : 'Overall Progress',
        ),
        const SizedBox(height: 16),

        // ── GLOBAL tier ──
        if (globalAchievements.isNotEmpty)
          _TierSection(
            tier: _GeoTier.global,
            achievements: globalAchievements,
            collections: [
              if (countryAchievements.isNotEmpty)
                _CollectionInfo(
                  label: 'All Countries on Earth',
                  icon: LucideIcons.flag,
                  achievements: countryAchievements,
                  isCountryCollection: true,
                ),
              for (final id in const [
                'holy-sites', 'ancient-sites', 'seas', 'national-parks',
                'capitals', 'ski-resorts', 'tourist-destinations',
              ])
                if (themed.containsKey(id))
                  _CollectionInfo(
                    label: _themedLabels[id] ?? id,
                    icon: _themedIcons[id] ?? LucideIcons.star,
                    achievements: themed[id]!,
                    isCountryCollection: false,
                  ),
            ],
          ),

        // ── CONTINENTAL tier ──
        if (continentalAchievements.isNotEmpty)
          _TierSection(
            tier: _GeoTier.continent,
            achievements: continentalAchievements,
            collections: [
              _CollectionInfo(
                label: 'All Continents on Earth',
                icon: LucideIcons.globe,
                achievements: continentalAchievements,
                isCountryCollection: false,
              ),
            ],
          ),

        // ── COUNTRY tier ──
        if (countryAchievements.isNotEmpty)
          _TierSection(
            tier: _GeoTier.country,
            achievements: countryAchievements,
            collections: [
              // Group by continent, each continent is a "collection"
              for (final cInfo in _continents)
                ..._buildCountryContinent(cInfo, countryAchievements),
            ],
          ),

        // ── ZONE tier ──
        if (zoneAchievements.isNotEmpty)
          _TierSection(
            tier: _GeoTier.zone,
            achievements: zoneAchievements,
            collections: [
              // Split zones by country tag → "Israeli Zones", "Bulgarian Zones"
              ..._buildZonesByCountry(zonesOnly),
              for (final entry in local.entries)
                _CollectionInfo(
                  label: _localLabels[entry.key] ?? entry.key,
                  icon: _localIcons[entry.key] ?? LucideIcons.star,
                  achievements: entry.value,
                  isCountryCollection: false,
                ),
            ],
          ),
      ],
    );
  }

  /// Split zone achievements into per-country buckets.
  /// Matches country tags against the known country-label map; anything
  /// without a recognized country tag falls into a generic "Zones" group.
  List<_CollectionInfo> _buildZonesByCountry(List<Achievement> zones) {
    if (zones.isEmpty) return const [];
    final byCountry = <String, List<Achievement>>{};
    final untagged = <Achievement>[];
    for (final z in zones) {
      String? country;
      for (final tag in z.tags) {
        if (_countryLabels.containsKey(tag)) {
          country = tag;
          break;
        }
      }
      if (country != null) {
        byCountry.putIfAbsent(country, () => []).add(z);
      } else {
        untagged.add(z);
      }
    }

    final out = <_CollectionInfo>[];
    // Sort by country label for stable order
    final sortedKeys = byCountry.keys.toList()
      ..sort((a, b) => (_countryLabels[a] ?? a).compareTo(_countryLabels[b] ?? b));
    for (final key in sortedKeys) {
      final countryName = _countryLabels[key] ?? key;
      out.add(_CollectionInfo(
        label: '$countryName Zones',
        icon: LucideIcons.mapPin,
        achievements: byCountry[key]!,
        isCountryCollection: false,
      ));
    }
    if (untagged.isNotEmpty) {
      out.add(_CollectionInfo(
        label: 'Other Zones',
        icon: LucideIcons.mapPin,
        achievements: untagged,
        isCountryCollection: false,
      ));
    }
    return out;
  }

  List<_CollectionInfo> _buildCountryContinent(
    _ContinentInfo cInfo,
    List<Achievement> countryAchievements,
  ) {
    final inContinent = countryAchievements
        .where((a) => a.collectionId == cInfo.id)
        .toList();
    if (inContinent.isEmpty) return [];
    final adjective = _continentAdjective[cInfo.id] ?? cInfo.label;
    return [
      _CollectionInfo(
        label: '${cInfo.emoji} $adjective Countries',
        icon: LucideIcons.flag,
        achievements: inContinent,
        isCountryCollection: false,
      ),
    ];
  }
}

// ── Global Progress Card ──

class _GlobalProgressCard extends StatelessWidget {
  final int total;
  final int unlocked;
  final String label;

  const _GlobalProgressCard({
    required this.total,
    required this.unlocked,
    this.label = 'Global Progress',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppColors.bgCardLight.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Text('\u{1F30D}', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$unlocked / $total achievements unlocked',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Text(
            total == 0
                ? '0%'
                : '${(unlocked / total * 100).round()}%',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Filter Bar
// ══════════════════════════════════════════════════════════════

class _FilterBar extends StatelessWidget {
  final String? selectedContinent;
  final String? selectedCountry;
  final List<MapEntry<String, String>> availableCountries;
  final ValueChanged<String?> onContinentChanged;
  final ValueChanged<String?> onCountryChanged;

  const _FilterBar({
    required this.selectedContinent,
    required this.selectedCountry,
    required this.availableCountries,
    required this.onContinentChanged,
    required this.onCountryChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Find continent info for selected
    final continentLabel = selectedContinent == null
        ? null
        : _continents
            .where((c) => c.id == selectedContinent)
            .firstOrNull
            ?.label;

    return Row(
      children: [
        // Continent dropdown
        Expanded(
          child: _FilterDropdown(
            icon: LucideIcons.globe2,
            hint: 'Continent',
            value: selectedContinent,
            items: [
              const _DropdownItem(value: null, label: 'All Continents'),
              for (final c in _continents)
                _DropdownItem(
                  value: c.id,
                  label: c.label,
                  leading: c.emoji,
                ),
            ],
            onChanged: onContinentChanged,
          ),
        ),
        const SizedBox(width: 8),
        // Country dropdown (only when continent is selected)
        Expanded(
          child: selectedContinent != null && availableCountries.isNotEmpty
              ? _FilterDropdown(
                  icon: LucideIcons.mapPin,
                  hint: 'Country',
                  value: selectedCountry,
                  items: [
                    _DropdownItem(
                      value: null,
                      label: 'All in ${continentLabel ?? "region"}',
                    ),
                    for (final entry in availableCountries)
                      _DropdownItem(
                        value: entry.key,
                        label: entry.value,
                      ),
                  ],
                  onChanged: onCountryChanged,
                )
              : _FilterDropdown(
                  icon: LucideIcons.mapPin,
                  hint: 'Country',
                  value: null,
                  items: const [],
                  onChanged: (_) {},
                  enabled: false,
                ),
        ),
      ],
    );
  }
}

class _DropdownItem {
  final String? value;
  final String label;
  final String? leading;

  const _DropdownItem({
    required this.value,
    required this.label,
    this.leading,
  });
}

class _FilterDropdown extends StatelessWidget {
  final IconData icon;
  final String hint;
  final String? value;
  final List<_DropdownItem> items;
  final ValueChanged<String?> onChanged;
  final bool enabled;

  const _FilterDropdown({
    required this.icon,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    final displayLabel = hasValue
        ? items.where((i) => i.value == value).firstOrNull?.label ?? hint
        : hint;

    return GestureDetector(
      onTap: enabled && items.isNotEmpty
          ? () => _showPicker(context)
          : null,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: hasValue
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.bgCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasValue
                ? AppColors.primary.withValues(alpha: 0.4)
                : AppColors.bgCardLight.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: hasValue
                  ? AppColors.primaryLight
                  : AppColors.textMuted,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                displayLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      hasValue ? FontWeight.w600 : FontWeight.w400,
                  color: hasValue
                      ? AppColors.primaryLight
                      : enabled
                          ? AppColors.textSecondary
                          : AppColors.textMuted.withValues(alpha: 0.5),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              LucideIcons.chevronDown,
              size: 14,
              color: enabled
                  ? AppColors.textMuted
                  : AppColors.textMuted.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    hint,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              const Divider(height: 1, color: Color(0xFF2A2A2A)),
              // Items
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.45,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isSelected = item.value == value;
                    return ListTile(
                      dense: true,
                      leading: item.leading != null
                          ? Text(item.leading!,
                              style: const TextStyle(fontSize: 18))
                          : null,
                      title: Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: isSelected
                              ? AppColors.primaryLight
                              : AppColors.textPrimary,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(LucideIcons.check,
                              size: 16,
                              color: AppColors.primaryLight)
                          : null,
                      onTap: () {
                        Navigator.pop(context);
                        onChanged(item.value);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Collection Info (data holder for a collection inside a tier)
// ══════════════════════════════════════════════════════════════

class _CollectionInfo {
  final String label;
  final IconData icon;
  final List<Achievement> achievements;
  final bool isCountryCollection;

  const _CollectionInfo({
    required this.label,
    required this.icon,
    required this.achievements,
    this.isCountryCollection = false,
  });
}

// ══════════════════════════════════════════════════════════════
// Tier Section (top-level: Global / Continental / Country / Zone)
// ══════════════════════════════════════════════════════════════

class _TierSection extends StatelessWidget {
  final _GeoTier tier;
  final List<Achievement> achievements;
  final List<_CollectionInfo> collections;

  const _TierSection({
    required this.tier,
    required this.achievements,
    required this.collections,
  });

  @override
  Widget build(BuildContext context) {
    final unlocked = achievements.where((a) => a.isUnlocked).length;
    final total = achievements.length;
    final isComplete = total > 0 && unlocked == total;
    final color = _geoTierColor(tier);

    final tierIcon = switch (tier) {
      _GeoTier.global => LucideIcons.globe2,
      _GeoTier.continent => LucideIcons.globe,
      _GeoTier.country => LucideIcons.flag,
      _GeoTier.zone => LucideIcons.mapPin,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isComplete
                ? color.withValues(alpha: 0.4)
                : AppColors.bgCardLight.withValues(alpha: 0.5),
          ),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            shape: const RoundedRectangleBorder(),
            collapsedShape: const RoundedRectangleBorder(),
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withValues(alpha: 0.25)),
              ),
              child: Icon(tierIcon, size: 18, color: color),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    _geoTierLabel(tier),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                _GeoTierBadge(tier: tier),
              ],
            ),
            subtitle: Row(
              children: [
                Text(
                  '$unlocked / $total',
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(width: 8),
                Text(
                  '${collections.length} ${collections.length == 1 ? 'collection' : 'collections'}',
                  style: TextStyle(
                    fontSize: 11,
                    color: color.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            trailing: _ProgressBadge(
                value: total > 0 ? unlocked / total : 0),
            children: [
              const Divider(height: 1, indent: 16, endIndent: 16),
              for (final collection in collections)
                _CollectionAccordion(collection: collection),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Collection Accordion (inside a tier section)
// ══════════════════════════════════════════════════════════════

class _CollectionAccordion extends StatelessWidget {
  final _CollectionInfo collection;

  const _CollectionAccordion({required this.collection});

  @override
  Widget build(BuildContext context) {
    final unlocked =
        collection.achievements.where((a) => a.isUnlocked).length;
    final total = collection.achievements.length;
    final isComplete = total > 0 && unlocked == total;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
        leading: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.bgCardLight.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            collection.icon,
            size: 14,
            color: isComplete ? AppColors.success : AppColors.textMuted,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                collection.label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                'COLLECTION',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary.withValues(alpha: 0.6),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          '$unlocked / $total',
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
        children: collection.isCountryCollection
            ? _buildByContinentGroups(context)
            : [
                for (var i = 0; i < collection.achievements.length; i++)
                  _AchievementRow(
                      achievement: collection.achievements[i], index: i),
              ],
      ),
    );
  }

  List<Widget> _buildByContinentGroups(BuildContext context) {
    final byContinent = <String, List<Achievement>>{};
    for (final a in collection.achievements) {
      final continent = a.collectionId;
      if (continent == null) continue;
      byContinent.putIfAbsent(continent, () => []).add(a);
    }

    return [
      for (final cInfo in _continents)
        if (byContinent.containsKey(cInfo.id))
          _ContinentSubAccordion(
            continent: cInfo,
            achievements: byContinent[cInfo.id]!,
          ),
    ];
  }
}

// ══════════════════════════════════════════════════════════════
// Continent Sub-Accordion (inside a collection)
// ══════════════════════════════════════════════════════════════

class _ContinentSubAccordion extends StatelessWidget {
  final _ContinentInfo continent;
  final List<Achievement> achievements;

  const _ContinentSubAccordion({
    required this.continent,
    required this.achievements,
  });

  @override
  Widget build(BuildContext context) {
    final unlocked = achievements.where((a) => a.isUnlocked).length;
    final total = achievements.length;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding:
            const EdgeInsets.symmetric(horizontal: 30, vertical: 0),
        leading: Text(continent.emoji, style: const TextStyle(fontSize: 18)),
        title: Text(
          continent.label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          '$unlocked / $total',
          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
        ),
        children: [
          for (var i = 0; i < achievements.length; i++)
            _AchievementRow(achievement: achievements[i], index: i),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Achievement Row
// ══════════════════════════════════════════════════════════════

class _AchievementRow extends ConsumerWidget {
  final Achievement achievement;
  final int index;

  const _AchievementRow({required this.achievement, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch fresh state so pending claim status is reactive
    final fresh = ref.watch(achievementsProvider).allAchievements
        .firstWhere((a) => a.id == achievement.id, orElse: () => achievement);
    final isPending = fresh.isPendingClaim && !fresh.isUnlocked;

    final locale = Localizations.localeOf(context);
    final geo = ref.watch(geolocationProvider);
    final title = RegistryL10n.achievementTitle(
        locale, achievement.id, achievement.title);

    String? distanceLabel;
    if (geo.hasLocation &&
        achievement.latitude != null &&
        achievement.longitude != null) {
      final dist =
          geo.distanceTo(achievement.latitude!, achievement.longitude!);
      distanceLabel = dist < 1000
          ? '${dist.round()}m'
          : '${(dist / 1000).toStringAsFixed(1)}km';
    }

    final tierColor = switch (achievement.tier) {
      AchievementTier.bronze => AppColors.bronze,
      AchievementTier.silver => AppColors.silver,
      AchievementTier.gold => AppColors.gold,
      AchievementTier.platinum => AppColors.platinum,
    };

    return InkWell(
      onTap: () => AchievementDetailSheet.show(context, fresh),
      child: Container(
        decoration: isPending
            ? BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              )
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 6),
        child: Row(
          children: [
            if (isPending)
              Icon(LucideIcons.sparkles, size: 12, color: AppColors.gold)
            else
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tierColor,
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  color: isPending
                      ? AppColors.gold
                      : fresh.isUnlocked
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                  fontWeight: isPending || fresh.isUnlocked
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (distanceLabel != null) ...[
              const SizedBox(width: 8),
              Text(
                distanceLabel,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textMuted),
              ),
            ],
            const SizedBox(width: 8),
            if (isPending)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                fresh.isUnlocked
                    ? LucideIcons.check
                    : LucideIcons.circle,
                size: 14,
                color: fresh.isUnlocked
                    ? AppColors.success
                    : AppColors.textMuted.withValues(alpha: 0.3),
              ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Shared Widgets
// ══════════════════════════════════════════════════════════════

/// Badge showing the geographic difficulty tier.
class _GeoTierBadge extends StatelessWidget {
  final _GeoTier tier;

  const _GeoTierBadge({required this.tier});

  @override
  Widget build(BuildContext context) {
    final color = _geoTierColor(tier);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        _geoTierLabel(tier),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

/// Percentage completion badge.
class _ProgressBadge extends StatelessWidget {
  final double value;

  const _ProgressBadge({required this.value});

  @override
  Widget build(BuildContext context) {
    final pct = (value * 100).round();
    final color = pct == 100
        ? AppColors.success
        : pct > 0
            ? AppColors.primaryLight
            : AppColors.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$pct%',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Achievement Timeline Tab
// ══════════════════════════════════════════════════════════════

class _TimelineEntry {
  final Achievement achievement;
  final DateTime timestamp;
  final bool isRevisit;
  final int? visitNumber;

  const _TimelineEntry({
    required this.achievement,
    required this.timestamp,
    this.isRevisit = false,
    this.visitNumber,
  });
}

class _AchievementTimelineTab extends ConsumerWidget {
  const _AchievementTimelineTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final achievements = ref.watch(achievementsProvider);

    final entries = <_TimelineEntry>[];
    for (final a in achievements.allAchievements) {
      if (!a.isUnlocked || a.unlockedAt == null) continue;

      entries
          .add(_TimelineEntry(achievement: a, timestamp: a.unlockedAt!));

      for (var i = 0; i < a.revisitHistory.length; i++) {
        entries.add(_TimelineEntry(
          achievement: a,
          timestamp: a.revisitHistory[i],
          isRevisit: true,
          visitNumber: i + 2,
        ));
      }
    }

    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.calendarClock,
                size: 48,
                color: AppColors.textMuted.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text(
              l10n.noUnlockedTrophiesYet,
              style:
                  const TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
          ],
        ),
      );
    }

    final grouped = <String, List<_TimelineEntry>>{};
    for (final entry in entries) {
      final dateKey =
          DateFormat.yMMMd(locale.languageCode).format(entry.timestamp);
      grouped.putIfAbsent(dateKey, () => []).add(entry);
    }

    final dateKeys = grouped.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: dateKeys.length,
      itemBuilder: (context, dateIndex) {
        final dateLabel = dateKeys[dateIndex];
        final items = grouped[dateLabel]!;
        final date = items.first.timestamp;
        final isToday = DateUtils.isSameDay(date, DateTime.now());
        final isYesterday = DateUtils.isSameDay(
            date, DateTime.now().subtract(const Duration(days: 1)));

        String displayDate = dateLabel;
        if (isToday) {
          displayDate =
              locale.languageCode == 'he' ? '\u05d4\u05d9\u05d5\u05dd' : 'Today';
        } else if (isYesterday) {
          displayDate =
              locale.languageCode == 'he' ? '\u05d0\u05ea\u05de\u05d5\u05dc' : 'Yesterday';
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (dateIndex > 0) const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color:
                              AppColors.primary.withValues(alpha: 0.15)),
                    ),
                    child: Text(
                      displayDate,
                      style: TextStyle(
                        color: AppColors.primaryLight,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 1,
                      color:
                          AppColors.bgCardLight.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
            ...items.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              final globalIndex = entries.indexOf(item);
              return Padding(
                padding: EdgeInsets.only(
                    bottom: idx < items.length - 1 ? 8 : 0),
                child: _TimelineRow(
                  achievement: item.achievement,
                  timestamp: item.timestamp,
                  isRevisit: item.isRevisit,
                  visitNumber: item.visitNumber,
                  index: globalIndex,
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

// ── Timeline Row ──

class _TimelineRow extends StatelessWidget {
  final Achievement achievement;
  final DateTime timestamp;
  final bool isRevisit;
  final int? visitNumber;
  final int index;

  const _TimelineRow({
    required this.achievement,
    required this.timestamp,
    this.isRevisit = false,
    this.visitNumber,
    required this.index,
  });

  Color get _tierColor => switch (achievement.tier) {
        AchievementTier.bronze => AppColors.bronze,
        AchievementTier.silver => AppColors.silver,
        AchievementTier.gold => AppColors.gold,
        AchievementTier.platinum => AppColors.platinum,
      };

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final time = DateFormat.Hm(locale.languageCode).format(timestamp);
    final title = RegistryL10n.achievementTitle(
        locale, achievement.id, achievement.title);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isRevisit
              ? AppColors.info.withValues(alpha: 0.3)
              : AppColors.bgCardLight.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isRevisit
                  ? AppColors.info.withValues(alpha: 0.15)
                  : _tierColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isRevisit
                    ? AppColors.info.withValues(alpha: 0.3)
                    : _tierColor.withValues(alpha: 0.3),
              ),
            ),
            child: Center(
              child: Icon(
                isRevisit ? LucideIcons.footprints : LucideIcons.trophy,
                size: 18,
                color: isRevisit ? AppColors.info : _tierColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: (isRevisit ? AppColors.info : _tierColor)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isRevisit
                        ? 'Visit #${visitNumber ?? ""}'
                        : _tierLabel,
                    style: TextStyle(
                      color: isRevisit ? AppColors.info : _tierColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                time,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              if (isRevisit)
                Text(
                  'Revisit',
                  style: TextStyle(
                    color: AppColors.info,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.zap,
                        size: 12, color: AppColors.xpGlow),
                    const SizedBox(width: 2),
                    Text(
                      '${achievement.xpReward}',
                      style: TextStyle(
                        color: AppColors.xpGlow,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    ).animate(delay: Duration(milliseconds: (index * 40).clamp(0, 600)))
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.03);
  }

  String get _tierLabel => switch (achievement.tier) {
        AchievementTier.bronze => 'Bronze',
        AchievementTier.silver => 'Silver',
        AchievementTier.gold => 'Gold',
        AchievementTier.platinum => 'Platinum',
      };
}

// ══════════════════════════════════════════════════════════════
// Pending Claims Banner (achievements only)
// ══════════════════════════════════════════════════════════════

class _AchievementsPendingClaims extends ConsumerWidget {
  const _AchievementsPendingClaims();

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

  Future<void> _claimSingle(
    BuildContext context,
    WidgetRef ref,
    Achievement achievement,
  ) async {
    final navContext = Navigator.of(context, rootNavigator: true).context;
    final notifier = ref.read(achievementsProvider.notifier);
    final claimed = await notifier.confirmPendingClaim(achievement.id);
    if (claimed && navContext.mounted) {
      await AchievementUnlockPopup.show(navContext, achievement);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievements = ref.watch(achievementsProvider);
    final pendingClaims = achievements.allAchievements
        .where((a) => a.isPendingClaim && !a.isUnlocked)
        .toList();

    if (pendingClaims.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
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
                  Icon(LucideIcons.trophy, size: 16, color: AppColors.gold),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${pendingClaims.length} ${pendingClaims.length == 1 ? 'achievement' : 'achievements'} ready to claim!',
                      style: TextStyle(
                        color: AppColors.gold,
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
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                itemCount: pendingClaims.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final achievement = pendingClaims[index];
                  return GestureDetector(
                    onTap: () => _claimSingle(context, ref, achievement),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryLight],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.sparkles,
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
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
      ),
    );
  }
}
