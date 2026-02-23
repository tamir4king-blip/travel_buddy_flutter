import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:travel_buddy_mobile/core/theme/app_theme.dart';
import 'package:travel_buddy_mobile/shared/services/photo_service.dart';

class PhotoPickerWidget extends StatelessWidget {
  final List<String> photos;
  final ValueChanged<List<String>> onPhotosChanged;
  final int maxPhotos;

  const PhotoPickerWidget({
    super.key,
    required this.photos,
    required this.onPhotosChanged,
    this.maxPhotos = 5,
  });

  Future<void> _addPhoto() async {
    if (photos.length >= maxPhotos) return;
    final photoService = PhotoService();
    final path = await photoService.pickImage();
    if (path != null) {
      onPhotosChanged([...photos, path]);
    }
  }

  void _removePhoto(int index) {
    final updated = [...photos];
    updated.removeAt(index);
    onPhotosChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ...photos.asMap().entries.map((entry) {
            final index = entry.key;
            final photoPath = entry.value;
            return Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      File(photoPath),
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.bgCardLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(LucideIcons.imageOff,
                            color: AppColors.textMuted, size: 20),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: GestureDetector(
                      onTap: () => _removePhoto(index),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.x,
                            size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          if (photos.length < maxPhotos)
            GestureDetector(
              onTap: _addPhoto,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.bgCardLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.textMuted.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.plus, color: AppColors.textMuted, size: 20),
                    const SizedBox(height: 2),
                    Text(AppLocalizations.of(context)!.add,
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 11)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
