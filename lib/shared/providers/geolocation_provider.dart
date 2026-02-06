import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

class GeolocationState {
  final double? latitude;
  final double? longitude;
  final bool isTracking;
  final bool hasPermission;
  final String? error;

  const GeolocationState({
    this.latitude,
    this.longitude,
    this.isTracking = false,
    this.hasPermission = false,
    this.error,
  });

  bool get hasLocation => latitude != null && longitude != null;

  double distanceTo(double lat, double lng) {
    if (!hasLocation) return double.infinity;
    return Geolocator.distanceBetween(latitude!, longitude!, lat, lng);
  }

  GeolocationState copyWith({
    double? latitude,
    double? longitude,
    bool? isTracking,
    bool? hasPermission,
    String? error,
  }) {
    return GeolocationState(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isTracking: isTracking ?? this.isTracking,
      hasPermission: hasPermission ?? this.hasPermission,
      error: error ?? this.error,
    );
  }
}

class GeolocationNotifier extends StateNotifier<GeolocationState> {
  GeolocationNotifier() : super(const GeolocationState());

  Future<void> requestPermission() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = state.copyWith(error: 'Location services are disabled');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          state = state.copyWith(error: 'Location permission denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        state = state.copyWith(error: 'Location permission permanently denied');
        return;
      }

      state = state.copyWith(hasPermission: true);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> getCurrentLocation() async {
    if (!state.hasPermission) await requestPermission();
    if (!state.hasPermission) return;

    try {
      state = state.copyWith(isTracking: true);
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      state = state.copyWith(
        latitude: position.latitude,
        longitude: position.longitude,
        isTracking: false,
      );
    } catch (e) {
      state = state.copyWith(isTracking: false, error: e.toString());
    }
  }

  bool isWithinRadius(double lat, double lng, double radiusMeters) {
    if (!state.hasLocation) return false;
    final distance = state.distanceTo(lat, lng);
    return distance <= radiusMeters;
  }
}

final geolocationProvider =
    StateNotifierProvider<GeolocationNotifier, GeolocationState>(
  (ref) => GeolocationNotifier(),
);
