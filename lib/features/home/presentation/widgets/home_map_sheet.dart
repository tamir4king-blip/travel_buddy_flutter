import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:travel_buddy_mobile/core/theme/app_theme.dart';
import 'package:travel_buddy_mobile/features/home/presentation/screens/home_screen.dart';
import 'package:travel_buddy_mobile/shared/providers/quests_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/user_profile_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/zone_provider.dart';

/// The Home tab as a living canvas: the persistent map shows through behind
/// a draggable dashboard sheet, with floating status chips on the exposed
/// map area. Bump/Zenly model — Home is a layer over the world, not a page.
class HomeMapSheet extends StatefulWidget {
  const HomeMapSheet({super.key});

  @override
  State<HomeMapSheet> createState() => _HomeMapSheetState();
}

class _HomeMapSheetState extends State<HomeMapSheet> {
  /// Sheet anchor points: collapsed shows just the handle strip (map almost
  /// fully exposed), peek is the resting dashboard, full covers the canvas.
  static const _collapsed = 0.16;
  static const _peek = 0.46;
  static const _full = 0.94;

  double _lastSettled = _peek;

  bool _onSheetNotification(DraggableScrollableNotification notification) {
    // Tick when the sheet settles on a new anchor — makes the snap physical.
    for (final anchor in const [_collapsed, _peek, _full]) {
      if ((notification.extent - anchor).abs() < 0.006 &&
          (_lastSettled - anchor).abs() > 0.02) {
        _lastSettled = anchor;
        HapticFeedback.selectionClick();
        break;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Floating status chips on the exposed canvas.
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: _CanvasChips(),
            ),
          ),
        ),

        // The dashboard sheet.
        NotificationListener<DraggableScrollableNotification>(
          onNotification: _onSheetNotification,
          child: DraggableScrollableSheet(
            initialChildSize: _peek,
            minChildSize: _collapsed,
            maxChildSize: _full,
            snap: true,
            snapSizes: const [_peek],
            builder: (context, scrollController) {
              return DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.bgDark,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.sheet),
                  ),
                  border: Border(
                    top: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      blurRadius: 24,
                      offset: const Offset(0, -8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.sheet),
                  ),
                  child: Column(
                    children: [
                      const _GrabHandle(),
                      Expanded(
                        child: HomeScreen(
                          sheetScrollController: scrollController,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _GrabHandle extends StatelessWidget {
  const _GrabHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.md,
        bottom: AppSpacing.xs,
      ),
      child: Container(
        width: 44,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.textMuted.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

/// Level / location / streak pills floating on the map canvas. Values only —
/// icons carry the meaning, so no new localized strings are needed.
class _CanvasChips extends ConsumerWidget {
  const _CanvasChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProfileProvider);
    final zone = ref.watch(zoneProvider);
    final streak = ref.watch(questsProvider.select((q) => q.currentStreak));

    final location = zone.city ?? zone.country;

    return Row(
      children: [
        _CanvasChip(
          icon: LucideIcons.zap,
          label: '${user.level}',
          iconColor: AppColors.xpGreen,
          onTap: () => context.go('/profile'),
        ),
        const SizedBox(width: AppSpacing.sm),
        if (location != null)
          Flexible(
            child: _CanvasChip(
              icon: LucideIcons.mapPin,
              label: location,
              iconColor: AppColors.primaryLight,
              onTap: () => context.go('/map'),
            ),
          ),
        const Spacer(),
        if (streak > 0)
          _CanvasChip(
            icon: LucideIcons.flame,
            label: '$streak',
            iconColor: AppColors.accent,
            onTap: () => context.go('/quests'),
          ),
      ],
    ).animate().fadeIn(duration: AppMotion.emphasized).slideY(
          begin: -0.3,
          end: 0,
          duration: AppMotion.emphasized,
          curve: AppMotion.enter,
        );
  }
}

class _CanvasChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final VoidCallback onTap;

  const _CanvasChip({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: AppColors.bgCard.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(AppRadius.chip + 6),
          border: Border.all(
            color: AppColors.bgCardLight.withValues(alpha: 0.9),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
