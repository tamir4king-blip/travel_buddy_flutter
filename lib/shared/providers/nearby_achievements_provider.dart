import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_buddy_mobile/shared/models/achievement.dart';
import 'package:travel_buddy_mobile/shared/providers/achievements_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/geolocation_provider.dart';

class NearbyAchievementsState {
  final List<Achievement> nearby;
  final List<Achievement> newlyDiscovered;

  const NearbyAchievementsState({
    this.nearby = const [],
    this.newlyDiscovered = const [],
  });

  bool get hasNearby => nearby.isNotEmpty;
  int get nearbyCount => nearby.length;
}

class NearbyAchievementsNotifier extends StateNotifier<NearbyAchievementsState> {
  NearbyAchievementsNotifier(this._ref) : super(const NearbyAchievementsState()) {
    _ref.listen(geolocationProvider, (_, geo) => _recompute(geo));
    _ref.listen(achievementsProvider, (_, __) => _recompute(_ref.read(geolocationProvider)));
    // Initial computation
    _recompute(_ref.read(geolocationProvider));
  }

  final Ref _ref;
  final Set<String> _previouslyNearby = {};

  void _recompute(GeolocationState geo) {
    if (!geo.hasLocation) {
      state = const NearbyAchievementsState();
      return;
    }

    final achievements = _ref.read(achievementsProvider);
    final nearby = achievements.allAchievements.where((a) {
      if (a.latitude == null || a.longitude == null || a.claimRadius == null) {
        return false;
      }
      if (a.isUnlocked) return false;
      return geo.distanceTo(a.latitude!, a.longitude!) <= a.claimRadius!;
    }).toList();

    final nearbyIds = nearby.map((a) => a.id).toSet();
    final newlyDiscovered = nearby
        .where((a) => !_previouslyNearby.contains(a.id))
        .toList();

    _previouslyNearby
      ..clear()
      ..addAll(nearbyIds);

    state = NearbyAchievementsState(
      nearby: nearby,
      newlyDiscovered: newlyDiscovered,
    );
  }

  void clearNewlyDiscovered() {
    state = NearbyAchievementsState(nearby: state.nearby);
  }
}

final nearbyAchievementsProvider =
    StateNotifierProvider<NearbyAchievementsNotifier, NearbyAchievementsState>(
  (ref) => NearbyAchievementsNotifier(ref),
);
