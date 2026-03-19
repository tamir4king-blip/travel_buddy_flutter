import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:travel_buddy_mobile/shared/models/achievement.dart';
import 'package:travel_buddy_mobile/shared/providers/achievements_provider.dart';

class BackgroundService {
  static final FlutterBackgroundService _service = FlutterBackgroundService();

  /// Creates the notification channel before the service starts.
  /// Required on Android 8+ and strictly enforced on Android 16.
  static Future<void> _ensureNotificationChannel() async {
    final plugin = FlutterLocalNotificationsPlugin();
    final android = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    const channel = AndroidNotificationChannel(
      'gps_scanning',
      'GPS Scanning',
      description: 'Persistent notification while GPS is actively scanning for achievements',
      importance: Importance.low,
      showBadge: false,
    );
    await android.createNotificationChannel(channel);
  }

  static Future<void> initialize() async {
    await _ensureNotificationChannel();
    await _service.configure(
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: _onStart,
        onBackground: _onIosBackground,
      ),
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        isForegroundMode: true,
        autoStart: false,
        autoStartOnBoot: true,
        notificationChannelId: 'gps_scanning',
        initialNotificationTitle: 'Travel Bounty',
        initialNotificationContent: '\u{1F5FA}\uFE0F GPS active \u2014 scanning for achievements',
        foregroundServiceNotificationId: 888,
        foregroundServiceTypes: [AndroidForegroundType.location],
      ),
    );
  }

  static Future<void> start() async {
    await _service.startService();
  }

  static Future<void> stop() async {
    _service.invoke('stop');
  }

  static Future<bool> isRunning() async {
    return await _service.isRunning();
  }
}

// ── Background isolate entry points ──────────────────────────────────────────

@pragma('vm:entry-point')
Future<bool> _onIosBackground(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void _onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  service.on('stop').listen((event) {
    service.stopSelf();
  });

  final checker = _ProximityChecker();
  await checker.init();

  Timer.periodic(const Duration(seconds: 15), (_) async {
    await checker.poll(service);
  });

  // Run immediately on start
  await checker.poll(service);
}

// ── Proximity checker (runs in background isolate) ───────────────────────────

/// Keys for SharedPreferences
const _keyPendingClaims = 'pending_claims';
const _keyNotifiedAchievements = 'bg_notified_achievements';
const _keyUnlockedAchievements = 'unlocked_achievements';

/// Minimum distance change (meters) to trigger a new proximity check.
const _minMovementMeters = 10.0;

/// Cooldown before re-notifying the same achievement (milliseconds).
const _notifyCooldownMs = 5 * 60 * 1000; // 5 minutes

class _ProximityChecker {
  late FlutterLocalNotificationsPlugin _notifications;
  late SharedPreferences _prefs;

  double? _lastLat;
  double? _lastLng;

  /// Pre-filter: only achievements that have coordinates and a claim radius.
  late List<Achievement> _locationAchievements;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    _notifications = FlutterLocalNotificationsPlugin();
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _notifications.initialize(initSettings);

    _locationAchievements = achievementRegistry
        .where((a) => a.latitude != null && a.longitude != null && a.claimRadius != null)
        .toList();
  }

  Future<void> poll(ServiceInstance service) async {
    try {
      final position = await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final lat = position.latitude;
      final lng = position.longitude;

      // Battery optimization: skip if hasn't moved > 10m
      if (_lastLat != null && _lastLng != null) {
        final moved = _haversineMeters(_lastLat!, _lastLng!, lat, lng);
        if (moved < _minMovementMeters) return;
      }

      _lastLat = lat;
      _lastLng = lng;

      // Load current state from SharedPreferences
      final unlockedIds = _loadUnlockedIds();
      final pendingClaims = _loadPendingClaims();
      final notifiedMap = _loadNotifiedMap();

      final now = DateTime.now();
      final nowMs = now.millisecondsSinceEpoch;

      int nearbyCount = 0;

      for (final achievement in _locationAchievements) {
        // Skip already unlocked
        if (unlockedIds.contains(achievement.id)) continue;

        final distance = _haversineMeters(
          lat, lng,
          achievement.latitude!, achievement.longitude!,
        );

        if (distance <= achievement.claimRadius!) {
          nearbyCount++;

          // Mark as pending claim
          if (!pendingClaims.containsKey(achievement.id)) {
            pendingClaims[achievement.id] = now.toIso8601String();
          }

          // Fire notification (with cooldown)
          final lastNotified = notifiedMap[achievement.id] ?? 0;
          if (nowMs - lastNotified > _notifyCooldownMs) {
            await _showAchievementNotification(achievement);
            notifiedMap[achievement.id] = nowMs;
          }
        }
      }

      // Persist updated state
      _savePendingClaims(pendingClaims);
      _saveNotifiedMap(notifiedMap);

      // Update the foreground notification body
      if (service is AndroidServiceInstance) {
        final body = nearbyCount > 0
            ? '\u{1F5FA}\uFE0F GPS active \u2014 $nearbyCount achievement${nearbyCount == 1 ? '' : 's'} nearby'
            : '\u{1F5FA}\uFE0F GPS active \u2014 scanning for achievements';
        service.setForegroundNotificationInfo(
          title: 'Travel Bounty',
          content: body,
        );
      }
    } catch (_) {
      // GPS timeout or error — skip this cycle
    }
  }

  // ── Notification ───────────────────────────────────────────────────────────

  Future<void> _showAchievementNotification(Achievement achievement) async {
    const androidDetails = AndroidNotificationDetails(
      'achievement_unlocked',
      'Achievement Alerts',
      channelDescription: 'Notifications when you unlock an achievement',
      importance: Importance.high,
      priority: Priority.high,
      ongoing: false,
      autoCancel: true,
    );
    const details = NotificationDetails(android: androidDetails);
    await _notifications.show(
      achievement.id.hashCode,
      '\u{1F3C6} Achievement Unlocked!',
      '${achievement.title} \u2014 tap to claim',
      details,
    );
  }

  // ── Haversine ──────────────────────────────────────────────────────────────

  static double _haversineMeters(
    double lat1, double lon1, double lat2, double lon2,
  ) {
    const R = 6371000.0; // Earth radius in meters
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  static double _toRad(double deg) => deg * pi / 180;

  // ── SharedPreferences helpers ──────────────────────────────────────────────

  Set<String> _loadUnlockedIds() {
    final raw = _prefs.getString(_keyUnlockedAchievements);
    if (raw == null) return {};
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => (e as Map<String, dynamic>)['id'] as String?)
          .whereType<String>()
          .toSet();
    } catch (_) {
      return {};
    }
  }

  Map<String, String> _loadPendingClaims() {
    final raw = _prefs.getString(_keyPendingClaims);
    if (raw == null) return {};
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, v as String));
    } catch (_) {
      return {};
    }
  }

  void _savePendingClaims(Map<String, String> claims) {
    _prefs.setString(_keyPendingClaims, jsonEncode(claims));
  }

  Map<String, int> _loadNotifiedMap() {
    final raw = _prefs.getString(_keyNotifiedAchievements);
    if (raw == null) return {};
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, v as int));
    } catch (_) {
      return {};
    }
  }

  void _saveNotifiedMap(Map<String, int> map) {
    _prefs.setString(_keyNotifiedAchievements, jsonEncode(map));
  }
}
