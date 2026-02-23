import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:travel_buddy_mobile/core/theme/app_theme.dart';
import 'package:travel_buddy_mobile/features/map/presentation/map_view_interface.dart';
import 'package:travel_buddy_mobile/features/map/presentation/widgets/achievement_marker.dart';
import 'package:travel_buddy_mobile/shared/models/achievement.dart';

/// Mobile map controller using Mapbox Maps SDK.
class PlatformMapController extends MapViewController {
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _markerManager;
  bool _initialized = false;

  // Current state for rebuilds
  List<Achievement> _achievements = [];
  double? _userLat;
  double? _userLng;
  VoidCallback? onStateChanged;

  // Cache: annotation ID → achievement ID
  final Map<String, String> _annotationToAchievement = {};

  @override
  bool get isInitialized => _initialized;

  @override
  void Function(String achievementId)? onMarkerClick;

  List<Achievement> get achievements => _achievements;
  double? get userLat => _userLat;
  double? get userLng => _userLng;

  void attachMap(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
    _initialized = true;
  }

  void setAnnotationManager(PointAnnotationManager manager) {
    _markerManager = manager;
  }

  @override
  void flyTo(double lat, double lng, [double altitude = 2000]) {
    if (!_initialized || _mapboxMap == null) return;
    final zoom = altitude < 3000 ? 14.0 : 12.0;
    _mapboxMap!.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(lng, lat)),
        zoom: zoom,
      ),
      MapAnimationOptions(duration: 1000),
    );
  }

  @override
  void setMarkers(List<Achievement> achievements) {
    _achievements = achievements;
    onStateChanged?.call();
  }

  @override
  void setUserLocation(double lat, double lng) {
    _userLat = lat;
    _userLng = lng;
    onStateChanged?.call();
  }

  @override
  void dispose() {
    _markerManager = null;
    _mapboxMap = null;
  }
}

/// Creates a [PlatformMapController] (mobile implementation).
PlatformMapController createMapController({required String token}) {
  return PlatformMapController();
}

/// Generates a colored map pin icon as PNG bytes.
Future<Uint8List> _renderMarkerIcon(Color color, {int size = 96}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final paint = Paint()..color = color;
  final borderPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = size * 0.06;

  final center = Offset(size / 2, size * 0.38);
  final radius = size * 0.3;

  // Circle body
  canvas.drawCircle(center, radius, paint);
  canvas.drawCircle(center, radius, borderPaint);

  // Pin tail
  final tailPath = Path()
    ..moveTo(center.dx - radius * 0.45, center.dy + radius * 0.7)
    ..lineTo(center.dx, size * 0.92)
    ..lineTo(center.dx + radius * 0.45, center.dy + radius * 0.7)
    ..close();
  canvas.drawPath(tailPath, paint);

  // Shadow
  final shadowPaint = Paint()
    ..color = color.withValues(alpha: 0.4)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  canvas.drawCircle(center, radius, shadowPaint);

  // Redraw on top of shadow
  canvas.drawCircle(center, radius, paint);
  canvas.drawCircle(center, radius, borderPaint);

  // Trophy icon (simple circle highlight)
  final dotPaint = Paint()..color = Colors.white.withValues(alpha: 0.9);
  canvas.drawCircle(center, radius * 0.3, dotPaint);

  final picture = recorder.endRecording();
  final image = await picture.toImage(size, size);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}

/// Converts a [Color] to an ARGB int for the Mapbox SDK.
int _colorToArgbInt(Color c) {
  return (c.a * 255).round() << 24 |
      (c.r * 255).round() << 16 |
      (c.g * 255).round() << 8 |
      (c.b * 255).round();
}

/// Mobile map view using Mapbox Maps SDK with native vector tiles.
class PlatformMapViewWidget extends StatefulWidget {
  final PlatformMapController controller;

  const PlatformMapViewWidget({super.key, required this.controller});

  @override
  State<PlatformMapViewWidget> createState() => _PlatformMapViewWidgetState();
}

class _PlatformMapViewWidgetState extends State<PlatformMapViewWidget> {
  // Cached marker icons per tier
  final Map<AchievementTier, Uint8List> _tierIcons = {};
  bool _iconsReady = false;
  Cancelable? _tapCancelable;

  @override
  void initState() {
    super.initState();
    widget.controller.onStateChanged = () {
      if (mounted) _syncAnnotations();
    };
    _prepareIcons();
  }

  @override
  void dispose() {
    _tapCancelable?.cancel();
    super.dispose();
  }

  Future<void> _prepareIcons() async {
    for (final tier in AchievementTier.values) {
      _tierIcons[tier] =
          await _renderMarkerIcon(AchievementMarker.tierColor(tier));
    }
    _iconsReady = true;
    if (mounted) _syncAnnotations();
  }

  Future<void> _syncAnnotations() async {
    final manager = widget.controller._markerManager;
    if (manager == null || !_iconsReady) return;

    // Clear existing annotations
    await manager.deleteAll();
    widget.controller._annotationToAchievement.clear();

    final ctrl = widget.controller;

    final locationAchievements = ctrl.achievements
        .where((a) => a.latitude != null && a.longitude != null)
        .toList();

    if (locationAchievements.isEmpty) return;

    final options = <PointAnnotationOptions>[];
    final achievementIds = <String>[];

    for (final a in locationAchievements) {
      final icon = _tierIcons[a.tier];
      if (icon == null) continue;

      options.add(PointAnnotationOptions(
        geometry: Point(coordinates: Position(a.longitude!, a.latitude!)),
        image: icon,
        iconSize: 0.5,
      ));
      achievementIds.add(a.id);
    }

    final annotations = await manager.createMulti(options);
    for (var i = 0; i < annotations.length; i++) {
      final annotation = annotations[i];
      if (annotation != null) {
        ctrl._annotationToAchievement[annotation.id] = achievementIds[i];
      }
    }
  }

  void _onMapCreated(MapboxMap mapboxMap) async {
    widget.controller.attachMap(mapboxMap);

    // Enable user location puck
    await mapboxMap.location.updateSettings(LocationComponentSettings(
      enabled: true,
      pulsingEnabled: true,
      pulsingColor: _colorToArgbInt(AppColors.info),
    ));

    // Create annotation manager for achievement markers
    final manager = await mapboxMap.annotations.createPointAnnotationManager();
    widget.controller.setAnnotationManager(manager);

    // Listen for marker taps
    _tapCancelable = manager.tapEvents(onTap: (annotation) {
      final achievementId =
          widget.controller._annotationToAchievement[annotation.id];
      if (achievementId != null) {
        widget.controller.onMarkerClick?.call(achievementId);
      }
    });

    // Sync markers if data already available
    _syncAnnotations();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.controller;
    final userLat = ctrl.userLat;
    final userLng = ctrl.userLng;
    final hasLocation = userLat != null && userLng != null;

    final centerLng = hasLocation ? userLng : -122.4194;
    final centerLat = hasLocation ? userLat : 37.7749;

    return MapWidget(
      cameraOptions: CameraOptions(
        center: Point(coordinates: Position(centerLng, centerLat)),
        zoom: 12,
      ),
      styleUri: MapboxStyles.MAPBOX_STREETS,
      onMapCreated: _onMapCreated,
    );
  }
}
