import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:travel_buddy_mobile/l10n/app_localizations.dart';
import 'package:travel_buddy_mobile/core/theme/app_theme.dart';
import 'package:travel_buddy_mobile/l10n/registry_l10n.dart';
import 'package:travel_buddy_mobile/shared/models/achievement.dart';
import 'package:travel_buddy_mobile/shared/providers/achievements_provider.dart';
import 'package:travel_buddy_mobile/shared/widgets/photo_picker_widget.dart';

class RetroactiveClaimModal extends StatefulWidget {
  final Achievement achievement;
  final Function(RetroactiveClaimData) onClaim;

  const RetroactiveClaimModal({
    super.key,
    required this.achievement,
    required this.onClaim,
  });

  @override
  State<RetroactiveClaimModal> createState() => _RetroactiveClaimModalState();

  static Future<RetroactiveClaimData?> show(
    BuildContext context,
    Achievement achievement,
  ) async {
    return showModalBottomSheet<RetroactiveClaimData>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RetroactiveClaimModal(
        achievement: achievement,
        onClaim: (data) => Navigator.of(context).pop(data),
      ),
    );
  }
}

class _RetroactiveClaimModalState extends State<RetroactiveClaimModal> {
  DateTime _selectedDate = DateTime.now();
  final _notesController = TextEditingController();
  final List<String> _photos = [];
  bool _isRetroactive = false;

  Color get _tierColor => switch (widget.achievement.tier) {
        AchievementTier.bronze => AppColors.bronze,
        AchievementTier.silver => AppColors.silver,
        AchievementTier.gold => AppColors.gold,
        AchievementTier.platinum => AppColors.platinum,
      };

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: _tierColor,
              surface: AppColors.bgCard,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _isRetroactive = true;
      });
    }
  }

  void _handleClaim() {
    final data = RetroactiveClaimData(
      visitDate: _selectedDate,
      photos: _photos,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
    );
    widget.onClaim(data);
  }

  void _handleQuickClaim() {
    Navigator.of(context).pop(null); // null means claim without retroactive data
  }

  String _formatDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context);
    return DateFormat.yMMMd(locale.languageCode).format(date);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Material(
      color: AppColors.bgCard,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Container(
      margin: EdgeInsets.only(bottom: bottomPadding),
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
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
              const SizedBox(height: 20),

              // Achievement header
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _tierColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      LucideIcons.trophy,
                      color: _tierColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          RegistryL10n.achievementTitle(Localizations.localeOf(context), widget.achievement.id, widget.achievement.title),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          RegistryL10n.achievementDescription(Localizations.localeOf(context), widget.achievement.id, widget.achievement.description),
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1),

              const SizedBox(height: 24),

              // Quick claim button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _handleQuickClaim,
                  icon: const Icon(LucideIcons.zap, size: 18),
                  label: Text(l10n.claimNowXp(widget.achievement.xpReward)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _tierColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ).animate(delay: 100.ms).fadeIn(duration: 300.ms).slideY(begin: 0.1),

              const SizedBox(height: 16),

              // Divider with "or"
              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.bgCardLight)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      l10n.orClaimRetroactively,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: AppColors.bgCardLight)),
                ],
              ).animate(delay: 150.ms).fadeIn(duration: 300.ms),

              const SizedBox(height: 16),

              // Date picker
              Text(
                l10n.whenDidYouAccomplish,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.bgCardLight,
                    borderRadius: BorderRadius.circular(12),
                    border: _isRetroactive
                        ? Border.all(color: _tierColor.withValues(alpha: 0.5))
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.calendar,
                        color: _isRetroactive ? _tierColor : AppColors.textMuted,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _formatDate(context, _selectedDate),
                        style: TextStyle(
                          color: _isRetroactive
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontWeight: _isRetroactive ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        LucideIcons.chevronDown,
                        color: AppColors.textMuted,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ).animate(delay: 200.ms).fadeIn(duration: 300.ms).slideY(begin: 0.1),

              const SizedBox(height: 16),

              // Notes field
              Text(
                l10n.notesOptional,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: l10n.addDetailsAboutExperience,
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.bgCardLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
                style: const TextStyle(color: AppColors.textPrimary),
              ).animate(delay: 250.ms).fadeIn(duration: 300.ms).slideY(begin: 0.1),

              const SizedBox(height: 16),

              // Photos
              Text(
                l10n.photosOptional,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              PhotoPickerWidget(
                photos: _photos,
                onPhotosChanged: (updated) {
                  setState(() {
                    _photos.clear();
                    _photos.addAll(updated);
                  });
                },
                maxPhotos: 5,
              ).animate(delay: 300.ms).fadeIn(duration: 300.ms).slideY(begin: 0.1),

              const SizedBox(height: 20),

              // XP notice for retroactive
              if (_isRetroactive)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.info,
                        color: AppColors.warning,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l10n.retroactiveXpNotice((widget.achievement.xpReward * 0.8).round()),
                          style: TextStyle(
                            color: AppColors.warning,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 200.ms),

              if (_isRetroactive) const SizedBox(height: 16),

              // Retroactive claim button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isRetroactive ? _handleClaim : null,
                  icon: const Icon(LucideIcons.clock, size: 18),
                  label: Text(l10n.claimRetroactively),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _tierColor,
                    side: BorderSide(
                      color: _isRetroactive
                          ? _tierColor
                          : AppColors.textMuted.withValues(alpha: 0.3),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ).animate(delay: 350.ms).fadeIn(duration: 300.ms).slideY(begin: 0.1),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    ),
    );
  }
}
