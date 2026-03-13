import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Requests foreground location permission (while using the app).
  Future<bool> requestLocationPermission() async {
    final status = await Permission.locationWhenInUse.request();
    return status.isGranted;
  }

  /// Requests background location permission (allow all the time).
  /// Must be called after foreground location is granted.
  Future<bool> requestBackgroundLocationPermission() async {
    final status = await Permission.locationAlways.request();
    return status.isGranted;
  }

  /// Requests notification permission (Android 13+).
  Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// Checks if all required permissions are granted.
  Future<bool> hasAllPermissions() async {
    final location = await Permission.locationWhenInUse.isGranted;
    final backgroundLocation = await Permission.locationAlways.isGranted;
    final notification = await Permission.notification.isGranted;
    return location && backgroundLocation && notification;
  }

  /// Opens the app settings page so the user can manually grant permissions.
  Future<void> openSettings() async {
    await openAppSettings();
  }
}
