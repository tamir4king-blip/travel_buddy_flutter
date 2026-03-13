import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:travel_buddy_mobile/l10n/app_localizations.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:travel_buddy_mobile/core/config/supabase_config.dart';
import 'package:travel_buddy_mobile/core/theme/app_theme.dart';
import 'package:travel_buddy_mobile/core/router/app_router.dart';
import 'package:travel_buddy_mobile/shared/services/persistence_service.dart';
import 'package:travel_buddy_mobile/shared/services/notification_service.dart';
import 'package:travel_buddy_mobile/shared/providers/persistence_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/notification_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/locale_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/geolocation_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/nearby_achievements_provider.dart';

const _mapboxToken = String.fromEnvironment('MAPBOX_TOKEN');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Mapbox
  MapboxOptions.setAccessToken(_mapboxToken);

  // Initialize Supabase (only if credentials are provided)
  if (SupabaseConfig.supabaseUrl.isNotEmpty &&
      SupabaseConfig.supabaseAnonKey.isNotEmpty) {
    try {
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        anonKey: SupabaseConfig.supabaseAnonKey,
      );
      SupabaseConfig.initialized = true;
    } catch (_) {
      // Supabase init failed -- app will still work with local-only mode
    }
  }

  final prefs = await SharedPreferences.getInstance();
  final persistenceService = PersistenceService(prefs);

  final notificationService = NotificationService();
  await notificationService.init();

  // Check if live tracking was enabled before app closed
  final shouldRestoreTracking = persistenceService.loadLiveTracking();

  await SentryFlutter.init(
    (options) {
      options.dsn = SupabaseConfig.sentryDsn;
      options.tracesSampleRate = 1.0;
      options.debug = false;
    },
    appRunner: () => runApp(
      ProviderScope(
        overrides: [
          persistenceServiceProvider.overrideWithValue(persistenceService),
          notificationServiceProvider.overrideWithValue(notificationService),
        ],
        child: TravelBuddyApp(restoreTracking: shouldRestoreTracking),
      ),
    ),
  );
}

class TravelBuddyApp extends ConsumerStatefulWidget {
  final bool restoreTracking;
  const TravelBuddyApp({super.key, this.restoreTracking = false});

  @override
  ConsumerState<TravelBuddyApp> createState() => _TravelBuddyAppState();
}

class _TravelBuddyAppState extends ConsumerState<TravelBuddyApp>
    with WidgetsBindingObserver {
  bool _trackingRestored = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Restore live tracking after first frame
    if (widget.restoreTracking) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _restoreTracking();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _restoreTracking() async {
    if (_trackingRestored) return;
    _trackingRestored = true;

    final geoNotifier = ref.read(geolocationProvider.notifier);
    await geoNotifier.startTracking();

    // Force the nearby achievements provider to initialize
    // so it starts checking proximity immediately
    ref.read(nearbyAchievementsProvider);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When app returns to foreground, re-check proximity
    if (state == AppLifecycleState.resumed) {
      final geo = ref.read(geolocationProvider);
      if (geo.isLiveTracking) {
        // Trigger a recomputation of nearby achievements
        ref.read(nearbyAchievementsProvider);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'TravelBuddy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
