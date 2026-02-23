import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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

const _mapboxToken = String.fromEnvironment('MAPBOX_TOKEN');

void main() async {
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
      // Supabase init failed — app will still work with local-only mode
    }
  }

  final prefs = await SharedPreferences.getInstance();
  final persistenceService = PersistenceService(prefs);

  final notificationService = NotificationService();
  await notificationService.init();

  runApp(
    ProviderScope(
      overrides: [
        persistenceServiceProvider.overrideWithValue(persistenceService),
        notificationServiceProvider.overrideWithValue(notificationService),
      ],
      child: const TravelBuddyApp(),
    ),
  );
}

class TravelBuddyApp extends ConsumerWidget {
  const TravelBuddyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
