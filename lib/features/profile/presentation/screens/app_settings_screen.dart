import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:travel_buddy_mobile/core/theme/app_theme.dart';
import 'package:travel_buddy_mobile/shared/providers/geolocation_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/locale_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/notification_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/persistence_provider.dart';

class AppSettingsScreen extends ConsumerWidget {
  const AppSettingsScreen({super.key});

  static const _supportedLocales = [
    Locale('en'),
    Locale('he'),
  ];

  String _languageName(Locale locale) {
    return switch (locale.languageCode) {
      'en' => 'English',
      'he' => 'עברית',
      _ => locale.languageCode,
    };
  }

  void _showLanguagePicker(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.read(localeProvider);
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textMuted,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.language,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                ..._supportedLocales.map((locale) {
                  final isSelected = locale.languageCode == currentLocale.languageCode;
                  return ListTile(
                    leading: Icon(
                      isSelected ? LucideIcons.checkCircle : LucideIcons.circle,
                      color: isSelected ? AppColors.primary : AppColors.textMuted,
                      size: 20,
                    ),
                    title: Text(
                      _languageName(locale),
                      style: TextStyle(
                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    onTap: () {
                      ref.read(localeProvider.notifier).setLocale(locale);
                      Navigator.of(context).pop();
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeProvider);
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final geo = ref.watch(geolocationProvider);
    final notificationsEnabled = ref.watch(notificationsEnabledProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appSettings),
        backgroundColor: AppColors.bgDark,
      ),
      backgroundColor: AppColors.bgDark,
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(LucideIcons.languages, size: 20, color: AppColors.textPrimary),
                  title: Text(l10n.language, style: const TextStyle(color: AppColors.textPrimary)),
                  subtitle: Text(_languageName(currentLocale), style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  trailing: Icon(
                    isRtl ? LucideIcons.chevronLeft : LucideIcons.chevronRight,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                  onTap: () => _showLanguagePicker(context, ref),
                ),
                const Divider(height: 1, color: AppColors.bgCardLight),
                ListTile(
                  leading: const Icon(LucideIcons.palette, size: 20, color: AppColors.textPrimary),
                  title: Text(l10n.theme, style: const TextStyle(color: AppColors.textPrimary)),
                  subtitle: Text(l10n.comingSoon, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  trailing: Icon(
                    isRtl ? LucideIcons.chevronLeft : LucideIcons.chevronRight,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                  enabled: false,
                ),
                const Divider(height: 1, color: AppColors.bgCardLight),
                ListTile(
                  leading: const Icon(LucideIcons.mapPin, size: 20, color: AppColors.textPrimary),
                  title: Text(l10n.locationSettings, style: const TextStyle(color: AppColors.textPrimary)),
                  subtitle: Text(
                    l10n.gpsPermission,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                  trailing: Switch(
                    value: geo.hasPermission,
                    activeColor: AppColors.primary,
                    onChanged: (value) async {
                      if (value) {
                        await ref.read(geolocationProvider.notifier).requestPermission();
                      }
                    },
                  ),
                ),
                const Divider(height: 1, color: AppColors.bgCardLight),
                ListTile(
                  leading: const Icon(LucideIcons.radio, size: 20, color: AppColors.textPrimary),
                  title: Text(l10n.liveTracking, style: const TextStyle(color: AppColors.textPrimary)),
                  subtitle: Text(
                    l10n.liveTrackingDescription,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                  enabled: geo.hasPermission,
                  trailing: Switch(
                    value: geo.isLiveTracking,
                    activeColor: AppColors.success,
                    onChanged: geo.hasPermission
                        ? (value) async {
                            final persistence = ref.read(persistenceServiceProvider);
                            if (value) {
                              await ref.read(geolocationProvider.notifier).startTracking();
                              await persistence.saveLiveTracking(true);
                            } else {
                              ref.read(geolocationProvider.notifier).stopTracking();
                              await persistence.saveLiveTracking(false);
                            }
                          }
                        : null,
                  ),
                ),
                const Divider(height: 1, color: AppColors.bgCardLight),
                ListTile(
                  leading: const Icon(LucideIcons.bell, size: 20, color: AppColors.textPrimary),
                  title: Text(l10n.proximityNotifications, style: const TextStyle(color: AppColors.textPrimary)),
                  subtitle: Text(
                    l10n.nativeAlertsNearAchievements,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                  trailing: Switch(
                    value: notificationsEnabled,
                    activeColor: AppColors.success,
                    onChanged: (value) async {
                      if (value) {
                        await ref.read(notificationServiceProvider).requestPermission();
                      }
                      await ref.read(notificationsEnabledProvider.notifier).toggle();
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
