import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_buddy_mobile/core/config/supabase_config.dart';
import 'package:travel_buddy_mobile/core/utils/error_logger.dart';
import 'package:travel_buddy_mobile/shared/data/achievement_definitions_repository.dart';
import 'package:travel_buddy_mobile/shared/models/achievement.dart';
import 'package:travel_buddy_mobile/shared/providers/achievements_provider.dart'
    show achievementRegistry;
import 'package:travel_buddy_mobile/shared/providers/persistence_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/supabase_provider.dart';

/// Provides the merged achievement definitions list.
/// Priority: Supabase definitions > cached definitions > hardcoded registry.
class AchievementDefinitionsNotifier extends StateNotifier<List<Achievement>> {
  final Ref ref;

  AchievementDefinitionsNotifier(this.ref) : super(achievementRegistry) {
    _load();
  }

  void _load() {
    // 1. Start with hardcoded registry
    final hardcoded = achievementRegistry;

    // 2. Try loading cached Supabase definitions
    try {
      final persistence = ref.read(persistenceServiceProvider);
      final cached = persistence.loadAchievementDefinitions();
      if (cached != null) {
        final remote = _parseDefinitions(cached);
        state = _merge(hardcoded, remote);
      }
    } catch (e, st) {
      // Cached definitions corrupted — fall back to hardcoded registry.
      logError(e, st, context: 'achievementDefinitions.loadCache',
          report: true);
    }

    // 3. Fetch fresh from Supabase in background
    _syncFromRemote();
  }

  Future<void> _syncFromRemote() async {
    if (!SupabaseConfig.isConfigured) return;

    try {
      final client = ref.read(supabaseClientProvider);
      final repo = AchievementDefinitionsRepository(client);
      final remote = await repo.fetchAll();

      if (remote.isNotEmpty) {
        final merged = _merge(achievementRegistry, remote);
        state = merged;

        // Cache for offline use + background service
        final persistence = ref.read(persistenceServiceProvider);
        await persistence.saveAchievementDefinitions(_serializeDefinitions(remote));
      }
    } catch (e, st) {
      // Supabase unavailable — keep using cached/hardcoded
      logError(e, st, context: 'achievementDefinitions.syncFromRemote',
          report: true);
    }
  }

  /// Force a refresh from Supabase. Called from dev panel.
  Future<void> refresh() async => _syncFromRemote();

  /// Merge: remote definitions override hardcoded by id.
  static List<Achievement> _merge(
    List<Achievement> hardcoded,
    List<Achievement> remote,
  ) {
    final remoteMap = {for (final a in remote) a.id: a};
    final merged = hardcoded.map((a) {
      final r = remoteMap.remove(a.id);
      if (r == null) return a;
      // Remote overrides definition fields but keeps hardcoded defaults for
      // fields that might not be in Supabase (e.g. tags fallback)
      return Achievement(
        id: r.id,
        title: r.title,
        description: r.description,
        iconName: r.iconName ?? a.iconName,
        tier: r.tier,
        xpReward: r.xpReward,
        latitude: r.latitude ?? a.latitude,
        longitude: r.longitude ?? a.longitude,
        claimRadius: r.claimRadius ?? a.claimRadius,
        claimPolygon: r.claimPolygon,
        collectionId: r.collectionId ?? a.collectionId,
        tags: r.tags.isNotEmpty ? r.tags : a.tags,
      );
    }).toList();

    // Add any new achievements that exist in Supabase but not hardcoded
    merged.addAll(remoteMap.values);
    return merged;
  }

  static List<Achievement> _parseDefinitions(String json) {
    final list = jsonDecode(json) as List<dynamic>;
    return list.map((e) {
      final row = e as Map<String, dynamic>;

      List<List<double>>? polygon;
      final rawPolygon = row['claim_polygon'];
      if (rawPolygon is List && rawPolygon.isNotEmpty) {
        polygon = rawPolygon
            .map<List<double>>(
                (p) => (p as List).map<double>((v) => (v as num).toDouble()).toList())
            .toList();
      }

      return Achievement(
        id: row['id'] as String,
        title: row['title'] as String,
        description: row['description'] as String? ?? '',
        iconName: row['icon_name'] as String?,
        tier: AchievementTier.values.byName(row['tier'] as String),
        xpReward: row['xp_reward'] as int,
        latitude: (row['latitude'] as num?)?.toDouble(),
        longitude: (row['longitude'] as num?)?.toDouble(),
        claimRadius: (row['claim_radius'] as num?)?.toDouble(),
        claimPolygon: polygon,
        collectionId: row['collection_id'] as String?,
        tags: (row['tags'] as List?)?.cast<String>() ?? const [],
      );
    }).toList();
  }

  static String _serializeDefinitions(List<Achievement> definitions) {
    return jsonEncode(definitions.map((a) => {
      'id': a.id,
      'title': a.title,
      'description': a.description,
      'icon_name': a.iconName,
      'tier': a.tier.name,
      'xp_reward': a.xpReward,
      'latitude': a.latitude,
      'longitude': a.longitude,
      'claim_radius': a.claimRadius,
      'claim_polygon': a.claimPolygon,
      'collection_id': a.collectionId,
      'tags': a.tags,
    }).toList());
  }
}

final achievementDefinitionsProvider =
    StateNotifierProvider<AchievementDefinitionsNotifier, List<Achievement>>(
  (ref) => AchievementDefinitionsNotifier(ref),
);
