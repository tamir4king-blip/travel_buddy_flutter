import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:travel_buddy_mobile/core/theme/app_theme.dart';

class ProfileAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String displayName;
  final double radius;
  final VoidCallback? onTap;

  const ProfileAvatar({
    super.key,
    this.avatarUrl,
    required this.displayName,
    this.radius = 50,
    this.onTap,
  });

  bool get _isNetworkUrl =>
      avatarUrl != null &&
      (avatarUrl!.startsWith('http://') || avatarUrl!.startsWith('https://'));

  bool get _isLocalFile =>
      avatarUrl != null && !_isNetworkUrl && avatarUrl!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          CircleAvatar(
            radius: radius,
            backgroundColor: AppColors.primary.withValues(alpha: 0.2),
            backgroundImage: _buildImage(),
            child: _buildImage() == null
                ? Text(
                    displayName.isNotEmpty
                        ? displayName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: radius * 0.72,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  )
                : null,
          ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
          if (onTap != null)
            PositionedDirectional(
              bottom: 0,
              end: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.bgDark, width: 2),
                ),
                child: Icon(
                  LucideIcons.camera,
                  size: radius * 0.28,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  ImageProvider? _buildImage() {
    if (_isNetworkUrl) {
      return CachedNetworkImageProvider(avatarUrl!);
    }
    if (_isLocalFile) {
      final file = File(avatarUrl!);
      if (file.existsSync()) {
        return FileImage(file);
      }
    }
    return null;
  }
}
