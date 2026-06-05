import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:travel_buddy_mobile/core/theme/app_theme.dart';
import 'package:travel_buddy_mobile/features/achievements/data/achievement_detail_provider.dart';
import 'package:travel_buddy_mobile/features/achievements/data/collection_helpers.dart'
    as ch;
import 'package:travel_buddy_mobile/l10n/app_localizations.dart';
import 'package:travel_buddy_mobile/l10n/registry_l10n.dart';
import 'package:travel_buddy_mobile/shared/models/achievement.dart';
import 'package:travel_buddy_mobile/shared/models/achievement_detail.dart';
import 'package:travel_buddy_mobile/shared/providers/achievements_provider.dart';
import 'package:travel_buddy_mobile/shared/widgets/achievement_unlock_popup.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shows a rich detail bottom sheet for an achievement.
/// Fetches additional data (photos, hours, website) from Supabase on demand,
/// with graceful fallback to local data only.
class AchievementDetailSheet extends ConsumerWidget {
  final Achievement achievement;

  const AchievementDetailSheet({super.key, required this.achievement});

  /// Opens the canonical achievement detail page. [outlineColor] tints the
  /// banner, X button, and status accents to match the pin-type color used
  /// by the map popup. Defaults to the tier color when omitted.
  ///
  /// Uses a fade + scale transition so the page reads as the map popup
  /// expanding into full-screen detail rather than a horizontal page push.
  static Future<void> show(
    BuildContext context,
    Achievement achievement, {
    Color? outlineColor,
  }) {
    return Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        opaque: true,
        fullscreenDialog: true,
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (_, __, ___) => _SheetContent(
          achievement: achievement,
          outlineColor: outlineColor,
        ),
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
              child: child,
            ),
          );
        },
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
  final Color? outlineColor;

  const _SheetContent({required this.achievement, this.outlineColor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);

    // Read fresh state so revisit data is up-to-date
    final achievement = ref.watch(achievementsProvider).allAchievements
        .firstWhere((a) => a.id == this.achievement.id,
            orElse: () => this.achievement);

    final detailAsync = ref.watch(achievementDetailProvider(achievement.id));

    final tierColor = switch (achievement.tier) {
      AchievementTier.bronze => AppColors.bronze,
      AchievementTier.silver => AppColors.silver,
      AchievementTier.gold => AppColors.gold,
      AchievementTier.platinum => AppColors.platinum,
    };
    final accentColor = outlineColor ?? tierColor;

    final tierLabel = switch (achievement.tier) {
      AchievementTier.bronze => l10n.tierBronzeLabel,
      AchievementTier.silver => l10n.tierSilverLabel,
      AchievementTier.gold => l10n.tierGoldLabel,
      AchievementTier.platinum => l10n.tierPlatinumLabel,
    };

    final detail = detailAsync.valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.bgCard,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
        // ── Big banner with X button overlay ──
        SizedBox(
          height: 240,
          child: Stack(
            children: [
              // Banner image or gradient fallback
              Positioned.fill(
                child: detail?.coverPhotoUrl != null
                    ? CachedNetworkImage(
                        imageUrl: detail!.coverPhotoUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: accentColor.withValues(alpha: 0.2),
                        ),
                        errorWidget: (_, __, ___) =>
                            _BannerGradient(color: accentColor),
                      )
                    : _BannerGradient(color: accentColor),
              ),
              // Dark gradient scrim at bottom for contrast
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppColors.bgCard.withValues(alpha: 0.9),
                      ],
                      stops: const [0.5, 1.0],
                    ),
                  ),
                ),
              ),
              // Close (X) button — rim tinted to match the pin-type accent
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                right: 12,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.7),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.4),
                          blurRadius: 12,
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                    child: const Icon(LucideIcons.x,
                        size: 18, color: Colors.white),
                  ),
                ),
              ),
              // Locked/unlocked status indicator
              Positioned(
                bottom: 16,
                left: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: achievement.isUnlocked
                        ? AppColors.success.withValues(alpha: 0.9)
                        : Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        achievement.isUnlocked
                            ? LucideIcons.check
                            : LucideIcons.lock,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        achievement.isUnlocked ? 'Unlocked' : 'Locked',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Content padding wrapper
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

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

        // Claim button for pending achievements
        if (achievement.isPendingClaim && !achievement.isUnlocked) ...[
          const SizedBox(height: 20),
          _ClaimButton(achievementId: achievement.id),
        ],

        // Retroactive claim button for locked achievements (even without pending/GPS).
        // One-tap unlock with today's date — user can refine details afterwards
        // by tapping "Edit visit" from the unlocked state.
        if (!achievement.isUnlocked && !achievement.isPendingClaim) ...[
          const SizedBox(height: 20),
          _RetroactiveClaimButton(achievementId: achievement.id),
        ],

        // Add photo / Add remark buttons for unlocked achievements
        if (achievement.isUnlocked) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _AddPhotoButton(achievement: achievement)),
              const SizedBox(width: 8),
              Expanded(child: _AddRemarkButton(achievement: achievement)),
            ],
          ),
        ],

        // Collection progress cascade
        _buildCollectionProgress(ref),

        // Visit history — handles first visit + revisits + retroactive adds
        if (achievement.isUnlocked) ...[
          const SizedBox(height: 16),
          _VisitHistoryCard(achievement: achievement, locale: locale),
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
            ], // close inner Column children
          ), // close Column
        ), // close Padding
      ], // close ListView children
    ), // close ListView
  ); // close Scaffold
  }

  Widget _buildCollectionProgress(WidgetRef ref) {
    final collectionId = achievement.collectionId;
    if (collectionId == null) return const SizedBox.shrink();

    final all = ref.read(achievementsProvider).allAchievements;
    final tiers = <_TierProgress>[];

    if (ch.continentCollectionIds.contains(collectionId)) {
      // ── Countries collection ──
      final continentLabel =
          ch.continentLabels[collectionId] ?? collectionId;

      // Continent tier
      final continentList =
          all.where((a) => a.collectionId == collectionId).toList();
      tiers.add(_TierProgress(
        label: 'Countries ($continentLabel)',
        unlocked: continentList.where((a) => a.isUnlocked).length,
        total: continentList.length,
        color: AppColors.gold,
        tierLabel: 'Continent',
      ));

      // Global tier
      final globalList = all
          .where(
              (a) => ch.continentCollectionIds.contains(a.collectionId))
          .toList();
      tiers.add(_TierProgress(
        label: 'Countries (Global)',
        unlocked: globalList.where((a) => a.isUnlocked).length,
        total: globalList.length,
        color: AppColors.platinum,
        tierLabel: 'Global',
      ));
    } else if (ch.themedCollectionIds.contains(collectionId)) {
      // ── Themed collection ──
      final collLabel = ch.themedLabels[collectionId] ?? collectionId;
      final allInColl =
          all.where((a) => a.collectionId == collectionId).toList();

      // Country tier (only if >1 achievement shares the country)
      final country = ch.countryOf(achievement);
      if (country != null) {
        final countryList =
            allInColl.where((a) => ch.countryOf(a) == country).toList();
        if (countryList.length > 1) {
          final cLabel = ch.countryLabels[country] ?? country;
          tiers.add(_TierProgress(
            label: '$collLabel ($cLabel)',
            unlocked: countryList.where((a) => a.isUnlocked).length,
            total: countryList.length,
            color: AppColors.silver,
            tierLabel: 'Country',
          ));
        }
      }

      // Continent tier
      final continent = ch.continentOfThemed(achievement);
      if (continent != null) {
        final contLabel = ch.continentLabels[continent] ?? continent;
        final contList = allInColl
            .where((a) => ch.continentOfThemed(a) == continent)
            .toList();
        tiers.add(_TierProgress(
          label: '$collLabel ($contLabel)',
          unlocked: contList.where((a) => a.isUnlocked).length,
          total: contList.length,
          color: AppColors.gold,
          tierLabel: 'Continent',
        ));
      }

      // Global tier
      tiers.add(_TierProgress(
        label: '$collLabel (Global)',
        unlocked: allInColl.where((a) => a.isUnlocked).length,
        total: allInColl.length,
        color: AppColors.platinum,
        tierLabel: 'Global',
      ));
    } else if (ch.localCollectionIds.contains(collectionId)) {
      // ── Local collection ──
      final label = ch.localLabels[collectionId] ?? collectionId;
      final localList =
          all.where((a) => a.collectionId == collectionId).toList();
      tiers.add(_TierProgress(
        label: label,
        unlocked: localList.where((a) => a.isUnlocked).length,
        total: localList.length,
        color: AppColors.bronze,
        tierLabel: 'Local',
      ));
    }

    if (tiers.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Container(
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
                Icon(LucideIcons.layers,
                    size: 14, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Text(
                  'Collection Progress',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < tiers.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              _buildTierRow(tiers[i]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTierRow(_TierProgress tier) {
    final pct = tier.total > 0 ? tier.unlocked / tier.total : 0.0;
    final isComplete = tier.total > 0 && tier.unlocked == tier.total;

    return Row(
      children: [
        // Tier badge
        Container(
          width: 58,
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: tier.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: tier.color.withValues(alpha: 0.3)),
          ),
          child: Text(
            tier.tierLabel,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: tier.color,
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Label + progress bar
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tier.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 4,
                  backgroundColor:
                      AppColors.bgCardLight.withValues(alpha: 0.6),
                  valueColor: AlwaysStoppedAnimation(
                    isComplete ? AppColors.success : tier.color,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        // Count
        Text(
          '${tier.unlocked}/${tier.total}',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isComplete ? AppColors.success : AppColors.textMuted,
          ),
        ),
        if (isComplete) ...[
          const SizedBox(width: 4),
          Icon(LucideIcons.check, size: 12, color: AppColors.success),
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

class _TierProgress {
  final String label;
  final int unlocked;
  final int total;
  final Color color;
  final String tierLabel;

  const _TierProgress({
    required this.label,
    required this.unlocked,
    required this.total,
    required this.color,
    required this.tierLabel,
  });
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

class _ClaimButton extends ConsumerStatefulWidget {
  final String achievementId;

  const _ClaimButton({required this.achievementId});

  @override
  ConsumerState<_ClaimButton> createState() => _ClaimButtonState();
}

class _ClaimButtonState extends ConsumerState<_ClaimButton> {
  bool _claiming = false;

  Future<void> _claim() async {
    if (_claiming) return;
    setState(() => _claiming = true);

    final navContext = Navigator.of(context, rootNavigator: true).context;
    final notifier = ref.read(achievementsProvider.notifier);
    final achievement = ref.read(achievementsProvider).allAchievements
        .firstWhere((a) => a.id == widget.achievementId);

    final success = await notifier.confirmPendingClaim(widget.achievementId);

    if (mounted) setState(() => _claiming = false);

    if (success) {
      // Close the detail sheet first, then show unlock popup
      if (mounted) Navigator.of(context).pop();
      if (navContext.mounted) {
        await AchievementUnlockPopup.show(navContext, achievement);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch fresh state — hide button if already claimed
    final fresh = ref.watch(achievementsProvider).allAchievements
        .firstWhere((a) => a.id == widget.achievementId);
    if (!fresh.isPendingClaim || fresh.isUnlocked) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: _claim,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.gold, AppColors.accent],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: _claiming
            ? const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.sparkles, size: 18, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Claim Achievement',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Instant retroactive claim — marks as unlocked with today as visit date.
/// User can refine date/photos/notes afterward via the edit button.
class _RetroactiveClaimButton extends ConsumerStatefulWidget {
  final String achievementId;

  const _RetroactiveClaimButton({required this.achievementId});

  @override
  ConsumerState<_RetroactiveClaimButton> createState() =>
      _RetroactiveClaimButtonState();
}

class _RetroactiveClaimButtonState
    extends ConsumerState<_RetroactiveClaimButton> {
  bool _claiming = false;

  Future<void> _claim() async {
    if (_claiming) return;
    setState(() => _claiming = true);

    final notifier = ref.read(achievementsProvider.notifier);
    final achievement = ref.read(achievementsProvider).allAchievements
        .firstWhere((a) => a.id == widget.achievementId);

    final success = await notifier.claimAchievement(
      widget.achievementId,
      retroactiveData: RetroactiveClaimData(visitDate: DateTime.now()),
    );

    if (!mounted) return;
    setState(() => _claiming = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Claimed "${achievement.title}" retroactively'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Claim failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _claiming ? null : _claim,
        icon: _claiming
            ? const SizedBox(
                width: 14,
                height: 14,
                child:
                    CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(LucideIcons.clock, size: 16),
        label: Text(
          _claiming ? 'Claiming...' : 'Claim Retroactively',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

/// Tier-colored gradient banner used when no cover photo is available.
class _BannerGradient extends StatelessWidget {
  final Color color;
  const _BannerGradient({required this.color});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.7),
            color.withValues(alpha: 0.3),
            AppColors.bgCard,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          LucideIcons.trophy,
          size: 80,
          color: Colors.white.withValues(alpha: 0.25),
        ),
      ),
    );
  }
}

/// Pick a date, return it. Returns null if cancelled.
Future<DateTime?> _pickVisitDate(BuildContext context, DateTime initial) {
  return showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime(2000),
    lastDate: DateTime.now(),
  );
}

/// Visit + revisit log. Shows first visit (retroactive if edited) + each
/// revisit. Each entry has an edit button. A "+ Add revisit" CTA at the
/// bottom lets the user add a past visit retroactively.
class _VisitHistoryCard extends ConsumerWidget {
  final Achievement achievement;
  final Locale locale;

  const _VisitHistoryCard({required this.achievement, required this.locale});

  DateTime? get _firstVisit => achievement.visitDate ?? achievement.unlockedAt;

  bool get _firstIsRetroactive => achievement.isRetroactive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final first = _firstVisit;
    final history = achievement.revisitHistory;
    if (first == null && history.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.footprints, size: 14, color: AppColors.info),
              const SizedBox(width: 8),
              Text(
                achievement.visitCount <= 1
                    ? 'Visit history'
                    : '${achievement.visitCount} visits',
                style: TextStyle(
                  color: AppColors.info,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // First visit
          if (first != null)
            _VisitRow(
              label: 'First visit',
              date: first,
              locale: locale,
              retroactive: _firstIsRetroactive,
              onEdit: () => _editFirstVisit(context, ref),
            ),
          // Subsequent revisits (index 0 == visit #2, etc.)
          for (var i = 0; i < history.length; i++) ...[
            const SizedBox(height: 6),
            _VisitRow(
              label: 'Visit #${i + 2}',
              date: history[i],
              locale: locale,
              retroactive: true,
              onEdit: () => _editRevisit(context, ref, i),
            ),
          ],
          const SizedBox(height: 12),
          // Add revisit CTA
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _addRevisit(context, ref),
              icon: const Icon(LucideIcons.plus, size: 14),
              label: const Text('Add revisit (retroactive)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.info,
                side: BorderSide(color: AppColors.info.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editFirstVisit(BuildContext context, WidgetRef ref) async {
    final picked = await _pickVisitDate(
        context, _firstVisit ?? DateTime.now());
    if (picked == null) return;
    await ref
        .read(achievementsProvider.notifier)
        .updateVisitDetails(achievement.id, visitDate: picked);
  }

  Future<void> _editRevisit(BuildContext context, WidgetRef ref, int index) async {
    final current = achievement.revisitHistory[index];
    final picked = await _pickVisitDate(context, current);
    if (picked == null) return;
    await ref
        .read(achievementsProvider.notifier)
        .updateRevisitEntry(achievement.id, index, picked);
  }

  Future<void> _addRevisit(BuildContext context, WidgetRef ref) async {
    final picked = await _pickVisitDate(context, DateTime.now());
    if (picked == null) return;
    await ref
        .read(achievementsProvider.notifier)
        .addRetroactiveRevisit(achievement.id, picked);
  }
}

class _VisitRow extends StatelessWidget {
  final String label;
  final DateTime date;
  final Locale locale;
  final bool retroactive;
  final VoidCallback onEdit;

  const _VisitRow({
    required this.label,
    required this.date,
    required this.locale,
    required this.retroactive,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          constraints: const BoxConstraints(minWidth: 60),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppColors.info,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            DateFormat.yMMMd(locale.languageCode).format(date),
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
        if (retroactive)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Icon(LucideIcons.history,
                size: 12, color: AppColors.warning.withValues(alpha: 0.8)),
          ),
        GestureDetector(
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(LucideIcons.pencil,
                size: 14, color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }
}

/// "Add photo" tile — opens image picker, appends to achievement.photos.
class _AddPhotoButton extends ConsumerWidget {
  final Achievement achievement;
  const _AddPhotoButton({required this.achievement});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      onPressed: () async {
        final url = await _promptAddPhoto(context);
        if (url == null || url.isEmpty) return;
        await ref
            .read(achievementsProvider.notifier)
            .addPhoto(achievement.id, url);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo added'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      },
      icon: const Icon(LucideIcons.imagePlus, size: 14),
      label: const Text('Add photo', style: TextStyle(fontSize: 12)),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// Very minimal prompt — asks for a URL. A future iteration can swap in the
  /// full photo picker / camera flow.
  Future<String?> _promptAddPhoto(BuildContext context) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text('Add photo URL',
            style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: 'https://...',
            hintStyle: TextStyle(color: AppColors.textMuted),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

/// "Add remark" tile — opens a text field, replaces the achievement.notes.
class _AddRemarkButton extends ConsumerWidget {
  final Achievement achievement;
  const _AddRemarkButton({required this.achievement});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      onPressed: () async {
        final text = await _promptEditRemark(context);
        if (text == null) return;
        await ref
            .read(achievementsProvider.notifier)
            .setNotes(achievement.id, text.isEmpty ? null : text);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Remark saved'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      },
      icon: const Icon(LucideIcons.messageSquarePlus, size: 14),
      label: Text(
        achievement.notes != null && achievement.notes!.isNotEmpty
            ? 'Edit remark'
            : 'Add remark',
        style: const TextStyle(fontSize: 12),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<String?> _promptEditRemark(BuildContext context) async {
    final ctrl = TextEditingController(text: achievement.notes ?? '');
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text('Remark',
            style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLines: 4,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Leave a note about this visit...',
            hintStyle: TextStyle(color: AppColors.textMuted),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
