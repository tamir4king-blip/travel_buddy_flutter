import 'package:flutter/material.dart';
import 'package:travel_buddy_mobile/features/map/models/map_marker_item.dart';

/// Platform-agnostic map controller interface.
abstract class MapViewController {
  bool get isInitialized;
  void Function(String markerId, MapMarkerType type)? onMarkerClick;

  void flyTo(double lat, double lng, [double altitude = 2000]);
  void animateCamera(double lat, double lng, double zoom, {int durationMs = 1000});
  Future<({double lat, double lng, double zoom})?> getCameraState();
  void setMarkers(List<MapMarkerItem> markers);
  void setUserLocation(double lat, double lng);
  void resetCompass({int durationMs = 500});
  void zoomIn({int durationMs = 300});
  void zoomOut({int durationMs = 300});

  /// Convert geographic coordinates to screen pixel position.
  Future<({double x, double y})?> pixelForCoordinate(double lat, double lng);

  /// Callback for long-press on the map (lat, lng of the pressed point).
  void Function(double lat, double lng)? onMapLongPress;

  /// Callback for tap on an empty area of the map (lat, lng of the tapped point).
  void Function(double lat, double lng)? onMapClick;

  /// Callback fired on every camera change (pan, zoom, rotate).
  VoidCallback? onCameraChanged;

  /// Show a translucent circle on the map at the given coordinate with radius in meters.
  Future<void> showRadiusCircle(double lat, double lng, double radiusMeters, Color color);

  /// Remove the radius circle from the map.
  Future<void> clearRadiusCircle();

  void dispose();
}

/// Platform-agnostic map view widget interface.
abstract class PlatformMapView extends StatefulWidget {
  const PlatformMapView({super.key});
}
