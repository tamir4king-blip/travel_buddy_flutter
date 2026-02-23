import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:travel_buddy_mobile/core/theme/app_theme.dart';
import 'package:travel_buddy_mobile/l10n/registry_l10n.dart';
import 'package:travel_buddy_mobile/shared/data/collection_registry.dart';

class CollectionCompleteDialog extends StatefulWidget {
  final String collectionId;

  const CollectionCompleteDialog({super.key, required this.collectionId});

  static Future<void> show(BuildContext context, String collectionId) {
    return showDialog(
      context: context,
      builder: (_) => CollectionCompleteDialog(collectionId: collectionId),
    );
  }

  @override
  State<CollectionCompleteDialog> createState() =>
      _CollectionCompleteDialogState();
}

class _CollectionCompleteDialogState extends State<CollectionCompleteDialog> {
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final info = getCollectionInfo(widget.collectionId);
    final name = RegistryL10n.collectionName(locale, widget.collectionId, info?.name ?? widget.collectionId);
    final icon = info?.icon ?? '🏆';
    final bonusXp = info?.bonusXp ?? 50;

    return Stack(
      children: [
        Dialog(
          backgroundColor: AppColors.bgCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(icon, style: const TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                Text(
                  l10n.collectionComplete,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.xpGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.sparkles,
                          color: AppColors.xpGreen, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        l10n.bonusXpAmount(bonusXp),
                        style: const TextStyle(
                          color: AppColors.xpGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(l10n.awesome),
                  ),
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            particleDrag: 0.05,
            emissionFrequency: 0.05,
            numberOfParticles: 25,
            gravity: 0.1,
            shouldLoop: false,
            colors: const [
              AppColors.primary,
              AppColors.xpGreen,
              AppColors.gold,
              AppColors.warning,
              Colors.white,
            ],
          ),
        ),
      ],
    );
  }
}
