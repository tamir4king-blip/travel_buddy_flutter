import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:travel_buddy/core/theme/app_theme.dart';
import 'package:travel_buddy/shared/providers/achievements_provider.dart';
import 'package:travel_buddy/shared/providers/auth_provider.dart';
import 'package:travel_buddy/shared/providers/quests_provider.dart';
import 'package:travel_buddy/shared/providers/user_profile_provider.dart';
import 'package:travel_buddy/shared/providers/persistence_provider.dart';
import 'package:travel_buddy/shared/widgets/responsive_layout.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(userProfileProvider);
    final achievements = ref.watch(achievementsProvider);
    final quests = ref.watch(questsProvider);

    return SafeArea(
      child: ResponsiveLayout(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
          children: [
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.primary.withValues(alpha: 0.2),
              child: Text(
                user.displayName[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
            const SizedBox(height: 16),
            Text(
              user.displayName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (user.username != null) ...[
              const SizedBox(height: 4),
              Text('@${user.username}', style: TextStyle(color: AppColors.textSecondary)),
            ],
            if (user.bio != null) ...[
              const SizedBox(height: 8),
              Text(user.bio!, style: TextStyle(color: AppColors.textMuted), textAlign: TextAlign.center),
            ],
            const SizedBox(height: 24),

            Row(
              children: [
                _ProfileStat(label: l10n.totalXp, value: '${user.totalXp}'),
                _ProfileStat(label: l10n.level, value: '${user.level}'),
                _ProfileStat(label: l10n.trophies, value: '${achievements.totalUnlocked}'),
                _ProfileStat(label: l10n.quests, value: '${quests.completedCount}'),
              ],
            ).animate().fadeIn(duration: 500.ms),

            const SizedBox(height: 32),

            _SettingsSection(
              title: l10n.account,
              items: [
                _SettingsTile(icon: LucideIcons.userCircle, label: l10n.editProfile, onTap: () => context.push('/profile/edit')),
                _SettingsTile(icon: LucideIcons.shield, label: l10n.privacySettings, onTap: () => context.push('/profile/privacy')),
                _SettingsTile(icon: LucideIcons.bell, label: l10n.notifications, onTap: () {}),
              ],
            ),
            const SizedBox(height: 20),
            _SettingsSection(
              title: l10n.preferences,
              items: [
                _SettingsTile(icon: LucideIcons.languages, label: l10n.language, onTap: () => context.push('/profile/settings')),
                _SettingsTile(icon: LucideIcons.palette, label: l10n.theme, onTap: () => context.push('/profile/settings')),
                _SettingsTile(icon: LucideIcons.mapPin, label: l10n.locationSettings, onTap: () => context.push('/profile/settings')),
              ],
            ),
            const SizedBox(height: 20),
            _SettingsSection(
              title: l10n.support,
              items: [
                _SettingsTile(icon: LucideIcons.helpCircle, label: l10n.helpAndFaq, onTap: () {}),
                _SettingsTile(icon: LucideIcons.messageSquare, label: l10n.feedback, onTap: () {}),
                _SettingsTile(
                  icon: LucideIcons.logOut,
                  label: l10n.logOut,
                  isDestructive: true,
                  onTap: () {
                    ref.read(persistenceServiceProvider).clearAll();
                    ref.read(authProvider.notifier).signOut();
                    context.go('/auth');
                  },
                ),
              ],
            ),
            const SizedBox(height: 100),
          ],
        ),
        ),
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<_SettingsTile> items;

  const _SettingsSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(children: items),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDestructive;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.error : AppColors.textPrimary;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return ListTile(
      leading: Icon(icon, size: 20, color: color),
      title: Text(label, style: TextStyle(color: color, fontSize: 15)),
      trailing: Icon(
        isRtl ? LucideIcons.chevronLeft : LucideIcons.chevronRight,
        size: 18,
        color: AppColors.textMuted,
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }
}
