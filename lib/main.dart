import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:travel_buddy/core/config/supabase_config.dart';
import 'package:travel_buddy/core/theme/app_theme.dart';
import 'package:travel_buddy/core/router/app_router.dart';
import 'package:travel_buddy/shared/services/persistence_service.dart';
import 'package:travel_buddy/shared/providers/persistence_provider.dart';
import 'package:travel_buddy/shared/providers/locale_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase (only if credentials are configured)
  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
  }

  final prefs = await SharedPreferences.getInstance();
  final persistenceService = PersistenceService(prefs);

  runApp(
    ProviderScope(
      overrides: [
        persistenceServiceProvider.overrideWithValue(persistenceService),
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
