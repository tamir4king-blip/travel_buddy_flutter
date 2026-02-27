import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:travel_buddy_mobile/core/theme/app_theme.dart';
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

  @override
  bool get isInitialized => _initialized;

  @override
  void Function(String markerId, MapMarkerType type)? onMarkerClick;

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
  // Cached marker icons keyed by color ARGB32
  final Map<int, Uint8List> _iconCache = {};
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
    // Pre-render tier colors
    final tierColors = [
      AppColors.bronze,
      AppColors.silver,
      AppColors.gold,
      AppColors.platinum,
    ];
    // Pre-render difficulty colors
    final difficultyColors = [
      AppColors.success,
      AppColors.accent,
      const Color(0xFFF97316),
      const Color(0xFF9333EA),
    ];
    for (final color in [...tierColors, ...difficultyColors]) {
      _iconCache[color.toARGB32()] = await _renderMarkerIcon(color);
    }
    _iconsReady = true;
    if (mounted) _syncAnnotations();
  }

  Future<Uint8List> _getIcon(Color color) async {
    var icon = _iconCache[color.toARGB32()];
    if (icon != null) return icon;
    icon = await _renderMarkerIcon(color);
    _iconCache[color.toARGB32()] = icon;
    return icon;
  }

  Future<void> _syncAnnotations() async {
    final manager = widget.controller._markerManager;
    if (manager == null || !_iconsReady) return;

    // Clear existing annotations
    await manager.deleteAll();
    widget.controller._annotationToMarker.clear();

    final ctrl = widget.controller;
    if (ctrl.markers.isEmpty) return;

    final options = <PointAnnotationOptions>[];
    final markerItems = <MapMarkerItem>[];

    for (final item in ctrl.markers) {
      final icon = await _getIcon(item.pinColor);

      options.add(PointAnnotationOptions(
        geometry: Point(coordinates: Position(item.longitude, item.latitude)),
        image: icon,
        iconSize: 0.5,
      ));
      markerItems.add(item);
    }

    final annotations = await manager.createMulti(options);
    for (var i = 0; i < annotations.length; i++) {
      final annotation = annotations[i];
      if (annotation != null) {
        ctrl._annotationToMarker[annotation.id] = markerItems[i];
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
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.controller;
    final userLat = ctrl.userLat;
    final userLng = ctrl.userLng;
    final hasLocation = userLat != null && userLng != null;

    final centerLng = hasLocation ? userLng : 0.0;
    final centerLat = hasLocation ? userLat : 20.0;
    final defaultZoom = hasLocation ? 12.0 : 1.0;

    return MapWidget(
      cameraOptions: CameraOptions(
        center: Point(coordinates: Position(centerLng, centerLat)),
        zoom: defaultZoom,
      ),
      styleUri: MapboxStyles.MAPBOX_STREETS,
      onMapCreated: _onMapCreated,
    );
  }
}
