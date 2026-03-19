import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:travel_buddy_mobile/core/theme/app_theme.dart';
import 'package:travel_buddy_mobile/features/achievements/data/achievement_detail_provider.dart';
import 'package:travel_buddy_mobile/l10n/app_localizations.dart';
import 'package:travel_buddy_mobile/l10n/registry_l10n.dart';
import 'package:travel_buddy_mobile/shared/models/achievement.dart';
import 'package:travel_buddy_mobile/shared/models/achievement_detail.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shows a rich detail bottom sheet for an achievement.
/// Fetches additional data (photos, hours, website) from Supabase on demand,
/// with graceful fallback to local data only.
class AchievementDetailSheet extends ConsumerWidget {
  final Achievement achievement;

  const AchievementDetailSheet({super.key, required this.achievement});

  static Future<void> show(BuildContext context, Achievement achievement) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, scrollController) => _SheetContent(
          achievement: achievement,
          scrollController: scrollController,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const SizedBox.shrink();
  }
}

class _SheetContent extends ConsumerWidget {
  final Achievement achievement;
  final ScrollController scrollController;

  const _SheetContent({
    required this.achievement,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final detailAsync = ref.watch(achievementDetailProvider(achievement.id));

    final tierColor = switch (achievement.tier) {
      AchievementTier.bronze => AppColors.bronze,
      AchievementTier.silver => AppColors.silver,
      AchievementTier.gold => AppColors.gold,
      AchievementTier.platinum => AppColors.platinum,
    };

    final tierLabel = switch (achievement.tier) {
      AchievementTier.bronze => l10n.tierBronzeLabel,
      AchievementTier.silver => l10n.tierSilverLabel,
      AchievementTier.gold => l10n.tierGoldLabel,
      AchievementTier.platinum => l10n.tierPlatinumLabel,
    };

    final detail = detailAsync.valueOrNull;

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      children: [
        // Drag handle
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textMuted.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Cover photo
        if (detail?.coverPhotoUrl != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CachedNetworkImage(
              imageUrl: detail!.coverPhotoUrl!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                height: 200,
                color: AppColors.bgCardLight,
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Status icon
        Center(
          child: achievement.isUnlocked
              ? Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.bgCard, width: 2),
                  ),
                  child: const Icon(LucideIcons.check, size: 20, color: Colors.white),
                )
              : Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: AppColors.bgCardLight,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.textMuted.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    LucideIcons.mapPin,
                    size: 20,
                    color: AppColors.textMuted.withValues(alpha: 0.6),
                  ),
                ),
        ),
        const SizedBox(height: 16),

        // Title
        Text(
          RegistryL10n.achievementTitle(locale, achievement.id, achievement.title),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),

        // Description (prefer Supabase detail if available)
        Text(
          detail?.description ??
              RegistryL10n.achievementDescription(
                locale, achievement.id, achievement.description,
              ),
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.4),
        ),
        const SizedBox(height: 20),

        // Tier + XP badges
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: tierColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: tierColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                tierLabel,
                style: TextStyle(
                  color: tierColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.xpGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.xpGreen.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.zap, size: 12, color: AppColors.xpGreen),
                  const SizedBox(width: 4),
                  Text(
                    '+${achievement.xpReward} XP',
                    style: TextStyle(
                      color: AppColors.xpGreen,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Unlock date
        if (achievement.isUnlocked && achievement.unlockedAt != null) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.calendarCheck, size: 14, color: AppColors.success.withValues(alpha: 0.7)),
              const SizedBox(width: 6),
              Text(
                l10n.unlockedOn(
                  DateFormat.yMMMd(locale.languageCode).format(achievement.unlockedAt!),
                ),
                style: TextStyle(
                  color: AppColors.success.withValues(alpha: 0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],

        // User notes
        if (achievement.notes != null && achievement.notes!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.bgCardLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              achievement.notes!,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],

        // ── Rich data from Supabase ──
        if (detail != null) ...[
          // Location info (city, country)
          if (detail.city != null || detail.country != null) ...[
            const SizedBox(height: 20),
            _InfoRow(
              icon: LucideIcons.mapPin,
              text: [detail.city, detail.country].whereType<String>().join(', '),
            ),
          ],

          // Opening hours
          if (detail.openingHours.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildOpeningHours(context, detail),
          ],

          // Website
          if (detail.website != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _launchUrl(detail.website!),
              child: _InfoRow(
                icon: LucideIcons.globe,
                text: detail.website!,
                isLink: true,
              ),
            ),
          ],

          // Phone
          if (detail.phone != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _launchUrl('tel:${detail.phone}'),
              child: _InfoRow(
                icon: LucideIcons.phone,
                text: detail.phone!,
                isLink: true,
              ),
            ),
          ],

          // Photo gallery
          if (detail.photoUrls.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildPhotoGallery(detail),
          ],
        ],

        // Loading indicator for rich data
        if (detailAsync.isLoading) ...[
          const SizedBox(height: 20),
          const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOpeningHours(BuildContext context, AchievementDetail detail) {
    final dayOrder = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
    final dayLabels = {
      'mon': 'Mon', 'tue': 'Tue', 'wed': 'Wed', 'thu': 'Thu',
      'fri': 'Fri', 'sat': 'Sat', 'sun': 'Sun',
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCardLight.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.clock, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 8),
              Text(
                'Opening Hours',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...dayOrder
              .where((d) => detail.openingHours.containsKey(d))
              .map((day) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 40,
                          child: Text(
                            dayLabels[day] ?? day,
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          detail.openingHours[day]!,
                          style: TextStyle(
                            color: detail.openingHours[day] == 'closed'
                                ? AppColors.error.withValues(alpha: 0.7)
                                : AppColors.textPrimary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )),
        ],
      ),
    );
  }

  Widget _buildPhotoGallery(AchievementDetail detail) {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: detail.photoUrls.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) => ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: detail.photoUrls[index],
            width: 160,
            height: 120,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              width: 160,
              height: 120,
              color: AppColors.bgCardLight,
            ),
            errorWidget: (_, __, ___) => Container(
              width: 160,
              height: 120,
              color: AppColors.bgCardLight,
              child: Icon(LucideIcons.imageOff, color: AppColors.textMuted),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isLink;

  const _InfoRow({
    required this.icon,
    required this.text,
    this.isLink = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: isLink ? AppColors.primaryLight : AppColors.textSecondary,
              fontSize: 13,
              decoration: isLink ? TextDecoration.underline : null,
            ),
          ),
        ),
      ],
    );
  }
}
