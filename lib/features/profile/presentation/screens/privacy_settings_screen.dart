import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_buddy_mobile/l10n/app_localizations.dart';
import 'package:travel_buddy_mobile/core/theme/app_theme.dart';
import 'package:travel_buddy_mobile/shared/providers/user_profile_provider.dart';

class PrivacySettingsScreen extends ConsumerWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.privacySettings),
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
                SwitchListTile(
                  title: Text(l10n.publicProfile, style: const TextStyle(color: AppColors.textPrimary)),
                  subtitle: Text(
                    l10n.allowOthersToSeeProfile,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                  value: user.isPublic,
                  activeColor: AppColors.primary,
                  onChanged: (value) {
                    ref.read(userProfileProvider.notifier).updateProfile(isPublic: value);
                  },
                ),
                const Divider(height: 1, color: AppColors.bgCardLight),
                SwitchListTile(
                  title: Text(l10n.showOnLeaderboard, style: const TextStyle(color: AppColors.textPrimary)),
                  subtitle: Text(
                    l10n.appearInPublicRankings,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                  value: user.isPublic,
                  activeColor: AppColors.primary,
                  onChanged: (value) {
                    ref.read(userProfileProvider.notifier).updateProfile(isPublic: value);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
