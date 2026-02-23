import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_buddy_mobile/shared/providers/persistence_provider.dart';
import 'package:travel_buddy_mobile/shared/services/notification_service.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  throw UnimplementedError(
    'notificationServiceProvider must be overridden in ProviderScope',
  );
});

class NotificationsEnabledNotifier extends StateNotifier<bool> {
  NotificationsEnabledNotifier(this._ref)
      : super(_ref.read(persistenceServiceProvider).loadNotificationsEnabled());

  final Ref _ref;

  Future<void> toggle() async {
    state = !state;
    await _ref
        .read(persistenceServiceProvider)
        .saveNotificationsEnabled(state);
  }
}

final notificationsEnabledProvider =
    StateNotifierProvider<NotificationsEnabledNotifier, bool>(
  (ref) => NotificationsEnabledNotifier(ref),
);
