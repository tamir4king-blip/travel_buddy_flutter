import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:travel_buddy_mobile/core/theme/app_theme.dart';
import 'package:travel_buddy_mobile/core/utils/error_logger.dart';
import 'package:travel_buddy_mobile/features/map/models/map_marker_item.dart';
import 'package:travel_buddy_mobile/features/map/presentation/map_view_interface.dart';

/// Mobile map controller using Mapbox Maps SDK.
class PlatformMapController extends MapViewController {
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _markerManager;
  bool _initialized = false;

  // Current state for rebuilds
  List<MapMarkerItem> _markers = [];
  double? _userLat;
  double? _userLng;
  VoidCallback? onStateChanged;

  // Cache: annotation ID → MapMarkerItem
  final Map<String, MapMarkerItem> _annotationToMarker = {};

  // Radius circle / single-polygon preview (cleared on each new selection)
  PolygonAnnotationManager? _radiusManager;

  // Persistent overlay for "show all unlocked areas" toggle (independent from
  // the radius preview — doesn't get wiped by pin taps).
  PolygonAnnotationManager? _unlockedAreasManager;

  // Currently-selected marker (tapped) — draws the black arrow above.
  String? _selectedMarkerId;
  void Function(String? newId, String? previousId)? _onSelectionChanged;

  /// Highlight a marker as "selected" — re-renders its pin with the black
  /// arrow indicator. Pass null to clear the selection.
  @override
  void setSelectedMarker(String? markerId) {
    if (_selectedMarkerId == markerId) return;
    final previous = _selectedMarkerId;
    _selectedMarkerId = markerId;
    _onSelectionChanged?.call(markerId, previous);
  }

  @override
  bool get isInitialized => _initialized;

  @override
  void Function(String markerId, MapMarkerType type)? onMarkerClick;

  @override
  void Function(double lat, double lng)? onMapLongPress;

  @override
  void Function(double lat, double lng)? onMapClick;

  @override
  VoidCallback? onCameraChanged;

  List<MapMarkerItem> get markers => _markers;
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
  void animateCamera(double lat, double lng, double zoom, {int durationMs = 1000}) {
    if (!_initialized || _mapboxMap == null) return;
    _mapboxMap!.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(lng, lat)),
        zoom: zoom,
      ),
      MapAnimationOptions(duration: durationMs),
    );
  }

  @override
  Future<({double lat, double lng, double zoom})?> getCameraState() async {
    if (!_initialized || _mapboxMap == null) return null;
    final state = await _mapboxMap!.getCameraState();
    final center = state.center.coordinates;
    return (lat: center.lat.toDouble(), lng: center.lng.toDouble(), zoom: state.zoom);
  }

  @override
  void setMarkers(List<MapMarkerItem> markers) {
    _markers = markers;
    onStateChanged?.call();
  }

  @override
  void setUserLocation(double lat, double lng) {
    _userLat = lat;
    _userLng = lng;
    onStateChanged?.call();
  }

  @override
  Future<({double x, double y})?> pixelForCoordinate(double lat, double lng) async {
    if (!_initialized || _mapboxMap == null) return null;
    final screen = await _mapboxMap!.pixelForCoordinate(
      Point(coordinates: Position(lng, lat)),
    );
    return (x: screen.x, y: screen.y);
  }

  @override
  void resetCompass({int durationMs = 500}) {
    if (!_initialized || _mapboxMap == null) return;
    _mapboxMap!.flyTo(
      CameraOptions(bearing: 0),
      MapAnimationOptions(duration: durationMs),
    );
  }

  @override
  void zoomIn({int durationMs = 300}) async {
    if (!_initialized || _mapboxMap == null) return;
    final state = await _mapboxMap!.getCameraState();
    final newZoom = (state.zoom + 1).clamp(0.0, 22.0);
    _mapboxMap!.flyTo(
      CameraOptions(zoom: newZoom),
      MapAnimationOptions(duration: durationMs),
    );
  }

  @override
  void zoomOut({int durationMs = 300}) async {
    if (!_initialized || _mapboxMap == null) return;
    final state = await _mapboxMap!.getCameraState();
    final newZoom = (state.zoom - 1).clamp(0.0, 22.0);
    _mapboxMap!.flyTo(
      CameraOptions(zoom: newZoom),
      MapAnimationOptions(duration: durationMs),
    );
  }

  @override
  Future<void> showRadiusCircle(double lat, double lng, double radiusMeters, Color color) async {
    if (!_initialized || _mapboxMap == null) return;
    await clearRadiusCircle();

    _radiusManager = await _mapboxMap!.annotations.createPolygonAnnotationManager();
    final points = _geoCircle(lat, lng, radiusMeters, 64);
    await _radiusManager!.create(PolygonAnnotationOptions(
      geometry: Polygon(coordinates: [points.map((p) => Position(p.$2, p.$1)).toList()]),
      fillColor: _colorToArgbInt(color.withValues(alpha: 0.2)),
      fillOutlineColor: _colorToArgbInt(color),
      fillOpacity: 1.0,
    ));
  }

  @override
  Future<void> showClaimPolygon(List<List<double>> polygon, Color color) async {
    if (!_initialized || _mapboxMap == null) return;
    if (polygon.length < 3) return;
    await clearRadiusCircle();

    _radiusManager = await _mapboxMap!.annotations.createPolygonAnnotationManager();
    final positions = polygon.map((p) => Position(p[1], p[0])).toList();
    // Close the ring if not already closed
    if (positions.first.lng != positions.last.lng ||
        positions.first.lat != positions.last.lat) {
      positions.add(positions.first);
    }
    await _radiusManager!.create(PolygonAnnotationOptions(
      geometry: Polygon(coordinates: [positions]),
      fillColor: _colorToArgbInt(color.withValues(alpha: 0.55)),
      fillOutlineColor: _colorToArgbInt(color),
      fillOpacity: 1.0,
    ));
  }

  @override
  Future<void> clearRadiusCircle() async {
    if (_radiusManager != null) {
      await _radiusManager!.deleteAll();
      _radiusManager = null;
    }
  }

  @override
  Future<void> showUnlockedAreasOverlay(
      List<({List<List<double>> polygon, Color color})> areas) async {
    if (!_initialized || _mapboxMap == null) return;
    await clearUnlockedAreasOverlay();
    if (areas.isEmpty) return;

    _unlockedAreasManager =
        await _mapboxMap!.annotations.createPolygonAnnotationManager();

    for (final a in areas) {
      if (a.polygon.length < 3) continue;
      final positions = a.polygon.map((p) => Position(p[1], p[0])).toList();
      if (positions.first.lng != positions.last.lng ||
          positions.first.lat != positions.last.lat) {
        positions.add(positions.first);
      }
      await _unlockedAreasManager!.create(PolygonAnnotationOptions(
        geometry: Polygon(coordinates: [positions]),
        fillColor: _colorToArgbInt(a.color.withValues(alpha: 0.55)),
        fillOutlineColor: _colorToArgbInt(a.color),
        fillOpacity: 1.0,
      ));
    }
  }

  @override
  Future<void> clearUnlockedAreasOverlay() async {
    if (_unlockedAreasManager != null) {
      await _unlockedAreasManager!.deleteAll();
      _unlockedAreasManager = null;
    }
  }

  /// Generate geo-circle points (lat, lng) around a center.
  static List<(double, double)> _geoCircle(double lat, double lng, double radiusM, int segments) {
    const earthRadius = 6371000.0;
    final latRad = lat * math.pi / 180;
    final lngRad = lng * math.pi / 180;
    final d = radiusM / earthRadius;
    final points = <(double, double)>[];
    for (var i = 0; i <= segments; i++) {
      final bearing = 2 * math.pi * i / segments;
      final pLat = math.asin(
        math.sin(latRad) * math.cos(d) + math.cos(latRad) * math.sin(d) * math.cos(bearing),
      );
      final pLng = lngRad + math.atan2(
        math.sin(bearing) * math.sin(d) * math.cos(latRad),
        math.cos(d) - math.sin(latRad) * math.sin(pLat),
      );
      points.add((pLat * 180 / math.pi, pLng * 180 / math.pi));
    }
    return points;
  }

  @override
  void dispose() {
    _radiusManager = null;
    _unlockedAreasManager = null;
    _markerManager = null;
    _mapboxMap = null;
  }
}

/// Creates a [PlatformMapController] (mobile implementation).
PlatformMapController createMapController({required String token}) {
  return PlatformMapController();
}

/// Renders a map pin as PNG bytes: tier-colored stroke around a category
/// icon, with an optional black upward arrow above when [selected].
Future<Uint8List> _renderMarkerIcon({
  required Color tierColor,
  required IconData icon,
  required bool locked,
  required bool selected,
  int size = 96,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  // Reserve top space for the selection arrow
  final arrowBaseY = size * 0.18;
  final circleCenter = Offset(size / 2, size * 0.55);
  final circleRadius = size * 0.3;

  // 1) Selection arrow (small black upward triangle) — above the circle
  if (selected) {
    final tipY = size * 0.03;
    final arrowPath = Path()
      ..moveTo(size / 2 - size * 0.09, arrowBaseY)
      ..lineTo(size / 2, tipY)
      ..lineTo(size / 2 + size * 0.09, arrowBaseY)
      ..close();
    canvas.drawPath(arrowPath, Paint()..color = Colors.black);
  }

  // 2) Drop shadow
  final shadowPaint = Paint()
    ..color = Colors.black.withValues(alpha: 0.25)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  canvas.drawCircle(
      circleCenter.translate(0, 2), circleRadius, shadowPaint);

  // 3) Circle fill — muted for locked, light-tinted for unlocked
  final fillColor = locked
      ? const Color(0xFF2A2A2A)
      : Color.lerp(Colors.white, tierColor, 0.1) ?? Colors.white;
  canvas.drawCircle(circleCenter, circleRadius, Paint()..color = fillColor);

  // 4) Tier-colored stroke
  canvas.drawCircle(
    circleCenter,
    circleRadius,
    Paint()
      ..color = tierColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * 0.075,
  );

  // 5) Category icon in the middle
  final iconColor = locked ? tierColor.withValues(alpha: 0.85) : tierColor;
  final textPainter = TextPainter(
    text: TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: circleRadius * 1.2,
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        color: iconColor,
      ),
    ),
    textDirection: TextDirection.ltr,
  );
  textPainter.layout();
  textPainter.paint(
    canvas,
    Offset(
      circleCenter.dx - textPainter.width / 2,
      circleCenter.dy - textPainter.height / 2,
    ),
  );

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
  final VoidCallback? onMapReady;

  const PlatformMapViewWidget({super.key, required this.controller, this.onMapReady});

  @override
  State<PlatformMapViewWidget> createState() => _PlatformMapViewWidgetState();
}

class _PlatformMapViewWidgetState extends State<PlatformMapViewWidget> {
  // Cached marker icons keyed by composite state.
  // Key: "<argb>|<codePoint>|<locked>|<selected>"
  final Map<String, Uint8List> _iconCache = {};
  bool _iconsReady = false;
  Cancelable? _tapCancelable;
  bool _syncing = false;

  // Previous marker set for diffing
  Set<MapMarkerItem> _previousMarkers = {};
  // Reverse lookup: marker ID → annotation ID (for removal)
  final Map<String, String> _markerIdToAnnotationId = {};

  @override
  void initState() {
    super.initState();
    widget.controller.onStateChanged = () {
      if (mounted) _syncAnnotations();
    };
    widget.controller._onSelectionChanged = _onSelectionChanged;
    _prepareIcons();
  }

  @override
  void dispose() {
    _tapCancelable?.cancel();
    super.dispose();
  }

  Future<void> _prepareIcons() async {
    // Warm-start: icon PNGs are lazily rendered on first use. We only flip
    // the ready flag so `_syncAnnotations` can proceed.
    _iconsReady = true;
    if (mounted) _syncAnnotations();
  }

  String _cacheKey(MapMarkerItem item, bool selected) {
    return '${item.pinColor.toARGB32()}|${item.iconData.codePoint}|'
        '${item.isLocked ? 1 : 0}|${selected ? 1 : 0}';
  }

  Future<Uint8List> _getIcon(MapMarkerItem item, {bool selected = false}) async {
    final key = _cacheKey(item, selected);
    var png = _iconCache[key];
    if (png != null) return png;
    png = await _renderMarkerIcon(
      tierColor: item.pinColor,
      icon: item.iconData,
      locked: item.isLocked,
      selected: selected,
    );
    _iconCache[key] = png;
    return png;
  }

  /// Re-render a single pin when its selection state changes. Previously
  /// selected pin (if any) is reverted to the non-selected PNG.
  Future<void> _onSelectionChanged(String? newId, String? previousId) async {
    final manager = widget.controller._markerManager;
    if (manager == null) return;
    for (final change in [
      if (previousId != null) (previousId, false),
      if (newId != null) (newId, true),
    ]) {
      final (markerId, selected) = change;
      final annotationId = _markerIdToAnnotationId[markerId];
      if (annotationId == null) continue;
      final marker = widget.controller._annotationToMarker[annotationId];
      if (marker == null) continue;
      final icon = await _getIcon(marker, selected: selected);
      try {
        await manager.update(PointAnnotation(
          id: annotationId,
          geometry: Point(
              coordinates: Position(marker.longitude, marker.latitude)),
          image: icon,
          iconSize: 0.8,
        ));
      } catch (e, st) {
        // Annotation may have been removed
        logError(e, st, context: 'map.updateAnnotation');
      }
    }
  }

  Future<void> _syncAnnotations() async {
    final manager = widget.controller._markerManager;
    if (manager == null || !_iconsReady) return;

    // Prevent overlapping syncs
    if (_syncing) return;
    _syncing = true;

    try {
      final ctrl = widget.controller;
      final newMarkers = ctrl.markers.toSet();

      // Diff: find what to remove and what to add
      final toRemove = _previousMarkers.difference(newMarkers);
      final toAdd = newMarkers.difference(_previousMarkers);

      // Nothing changed — skip entirely
      if (toRemove.isEmpty && toAdd.isEmpty) return;

      // Remove old annotations
      if (toRemove.isNotEmpty) {
        final annotationIdsToRemove = <String>[];
        for (final item in toRemove) {
          final annotationId = _markerIdToAnnotationId.remove(item.id);
          if (annotationId != null) {
            ctrl._annotationToMarker.remove(annotationId);
            annotationIdsToRemove.add(annotationId);
          }
        }
        // Delete individually by looking up the PointAnnotation objects
        for (final annId in annotationIdsToRemove) {
          try {
            await manager.delete(PointAnnotation(id: annId, geometry: Point(coordinates: Position(0, 0))));
          } catch (e, st) {
            // Annotation may already be gone
            logError(e, st, context: 'map.deleteAnnotation');
          }
        }
      }

      // Add new annotations
      if (toAdd.isNotEmpty) {
        final options = <PointAnnotationOptions>[];
        final addItems = <MapMarkerItem>[];

        for (final item in toAdd) {
          final selected = widget.controller._selectedMarkerId == item.id;
          final icon = await _getIcon(item, selected: selected);
          options.add(PointAnnotationOptions(
            geometry: Point(coordinates: Position(item.longitude, item.latitude)),
            image: icon,
            iconSize: 0.8,
          ));
          addItems.add(item);
        }

        final annotations = await manager.createMulti(options);
        for (var i = 0; i < annotations.length; i++) {
          final annotation = annotations[i];
          if (annotation != null) {
            ctrl._annotationToMarker[annotation.id] = addItems[i];
            _markerIdToAnnotationId[addItems[i].id] = annotation.id;
          }
        }
      }

      _previousMarkers = newMarkers;
    } finally {
      _syncing = false;
    }
  }

  void _onMapCreated(MapboxMap mapboxMap) async {
    widget.controller.attachMap(mapboxMap);

    // Lock the map orientation — no rotation (always north-up) and no pitch.
    await mapboxMap.gestures.updateSettings(GesturesSettings(
      rotateEnabled: false,
      pitchEnabled: false,
      simultaneousRotateAndPinchToZoomEnabled: false,
    ));

    // Enable user location puck
    await mapboxMap.location.updateSettings(LocationComponentSettings(
      enabled: true,
      pulsingEnabled: true,
      pulsingColor: _colorToArgbInt(AppColors.info),
    ));

    // Create annotation manager for markers
    final manager = await mapboxMap.annotations.createPointAnnotationManager();
    widget.controller.setAnnotationManager(manager);

    // Listen for marker taps
    _tapCancelable = manager.tapEvents(onTap: (annotation) {
      final item = widget.controller._annotationToMarker[annotation.id];
      if (item != null) {
        widget.controller.onMarkerClick?.call(item.id, item.type);
      }
    });

    // Sync markers if data already available
    _syncAnnotations();

    // Notify that the map is ready
    widget.onMapReady?.call();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.controller;
    final userLat = ctrl.userLat;
    final userLng = ctrl.userLng;
    final hasLocation = userLat != null && userLng != null;

    final centerLng = 0.0;
    final centerLat = 20.0;
    final defaultZoom = 1.0;

    return MapWidget(
      cameraOptions: CameraOptions(
        center: Point(coordinates: Position(centerLng, centerLat)),
        zoom: defaultZoom,
      ),
      styleUri: MapboxStyles.MAPBOX_STREETS,
      onMapCreated: _onMapCreated,
      onCameraChangeListener: (_) {
        widget.controller.onCameraChanged?.call();
      },
      onTapListener: (context) {
        final coords = context.point.coordinates;
        widget.controller.onMapClick?.call(
          coords.lat.toDouble(),
          coords.lng.toDouble(),
        );
      },
      onLongTapListener: (context) {
        final coords = context.point.coordinates;
        widget.controller.onMapLongPress?.call(
          coords.lat.toDouble(),
          coords.lng.toDouble(),
        );
      },
    );
  }
}
