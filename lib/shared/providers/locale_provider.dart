import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_buddy_mobile/shared/services/persistence_service.dart';
import 'package:travel_buddy_mobile/shared/providers/persistence_provider.dart';

class LocaleNotifier extends StateNotifier<Locale> {
  final PersistenceService _persistence;

  LocaleNotifier(this._persistence) : super(const Locale('en')) {
    final saved = _persistence.loadLocale();
    if (saved != null) {
      state = Locale(saved);
    }
  }

  void setLocale(Locale locale) {
    state = locale;
    _persistence.saveLocale(locale.languageCode);
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  final persistence = ref.watch(persistenceServiceProvider);
  return LocaleNotifier(persistence);
});
