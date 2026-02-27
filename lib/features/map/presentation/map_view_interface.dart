import 'package:flutter/material.dart';
import 'package:travel_buddy_mobile/features/map/models/map_marker_item.dart';

/// Platform-agnostic map controller interface.
abstract class MapViewController {
  bool get isInitialized;
  void Function(String markerId, MapMarkerType type)? onMarkerClick;

  void flyTo(double lat, double lng, [double altitude = 2000]);
  void setMarkers(List<MapMarkerItem> markers);
  void setUserLocation(double lat, double lng);
  void dispose();
}

/// Platform-agnostic map view widget interface.
abstract class PlatformMapView extends StatefulWidget {
  const PlatformMapView({super.key});
}
