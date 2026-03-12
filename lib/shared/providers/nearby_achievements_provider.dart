import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_buddy_mobile/shared/models/achievement.dart';
import 'package:travel_buddy_mobile/shared/providers/achievements_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/geolocation_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/notification_provider.dart';
import 'package:travel_buddy_mobile/shared/services/notification_service.dart';

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

    // Auto-mark newly discovered achievements as pending claims
    // and send phone notifications
    if (newlyDiscovered.isNotEmpty && geo.isLiveTracking) {
      final achievementsNotifier = _ref.read(achievementsProvider.notifier);
      final notificationsEnabled = _ref.read(notificationsEnabledProvider);
      NotificationService? notificationService;
      try {
        notificationService = _ref.read(notificationServiceProvider);
      } catch (_) {
        // Provider not yet available
      }

      for (final achievement in newlyDiscovered) {
        // Skip if already pending
        if (achievement.isPendingClaim) continue;

        final wasMarked = achievementsNotifier.markPendingClaim(achievement.id);
        if (wasMarked && notificationsEnabled && notificationService != null) {
          final distance = geo.distanceTo(achievement.latitude!, achievement.longitude!);
          notificationService.showProximityNotification(
            id: achievement.hashCode,
            title: 'Trophy nearby: ${achievement.title}',
            body: '${distance.round()}m away - ${achievement.xpReward} XP! Open the app to claim it.',
          );
        }
      }
    }

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
