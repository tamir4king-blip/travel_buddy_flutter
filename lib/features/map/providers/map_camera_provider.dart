import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Commands that can be sent to the map camera from outside MapScreen.
sealed class MapCameraCommand {
  const MapCameraCommand();
}

/// Cinematic zoom to user's current location (zoom 14, 1200ms ease-in-out).
class CenterOnUserCommand extends MapCameraCommand {
  const CenterOnUserCommand();
}

/// Cinematic zoom out to globe view (lat 20, lng 0, zoom 2, 1200ms ease-in-out).
class ZoomToGlobeCommand extends MapCameraCommand {
  const ZoomToGlobeCommand();
}

/// Provider for issuing camera commands to the map.
/// Set to a command to trigger it; MapScreen watches and reacts.
final mapCameraCommandProvider = StateProvider<MapCameraCommand?>((ref) => null);

/// Tracks whether the map is currently in globe view.
final isGlobeViewProvider = StateProvider<bool>((ref) => false);

/// Cached map camera state — persisted in memory between map visits
/// so returning to the map restores the previous view.
class CachedCameraState {
  final double latitude;
  final double longitude;
  final double zoom;

  const CachedCameraState({
    required this.latitude,
    required this.longitude,
    required this.zoom,
  });
}

final cachedCameraStateProvider = StateProvider<CachedCameraState?>((ref) => null);

/// Tracks whether the map is in immersive full-screen mode.
/// AppShell watches this to hide/show the nav bar.
final mapImmersiveProvider = StateProvider<bool>((ref) => false);

/// Whether the zone settings popover (mode toggle + per-mode controls) is
/// expanded. Lifted to a provider so the popover can be rendered as an
/// overlay on the map area while the trigger lives in the top bar banner.
final mapZoneSettingsOpenProvider = StateProvider<bool>((ref) => false);
