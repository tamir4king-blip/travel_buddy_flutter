import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:travel_buddy_mobile/core/theme/app_theme.dart';
import 'package:travel_buddy_mobile/shared/providers/profile_sync_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/user_profile_provider.dart';
import 'package:travel_buddy_mobile/shared/services/photo_service.dart';
import 'package:travel_buddy_mobile/features/profile/presentation/widgets/profile_avatar.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _displayNameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _bioController;
  final _formKey = GlobalKey<FormState>();
  String? _selectedAvatarPath;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(userProfileProvider);
    _displayNameController = TextEditingController(text: user.displayName);
    _usernameController = TextEditingController(text: user.username ?? '');
    _bioController = TextEditingController(text: user.bio ?? '');
    _selectedAvatarPath = user.avatarUrl;
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final photoService = PhotoService();
    final path = await photoService.pickImage();
    if (path != null) {
      setState(() => _selectedAvatarPath = path);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      String? avatarUrl = _selectedAvatarPath;

      // Upload avatar to Supabase if a new local file was picked
      final syncService = ref.read(profileSyncServiceProvider);
      final currentUser = ref.read(userProfileProvider);
      if (syncService != null &&
          _selectedAvatarPath != null &&
          _selectedAvatarPath != currentUser.avatarUrl) {
        final uploaded = await syncService.uploadAvatar(_selectedAvatarPath!);
        if (uploaded != null) avatarUrl = uploaded;
      }

      ref.read(userProfileProvider.notifier).updateProfile(
            displayName: _displayNameController.text.trim(),
            username: _usernameController.text.trim().isEmpty
                ? null
                : _usernameController.text.trim(),
            bio: _bioController.text.trim().isEmpty
                ? null
                : _bioController.text.trim(),
            avatarUrl: avatarUrl,
          );

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.profileUpdated),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.primary,
          ),
        );
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.editProfile),
        backgroundColor: AppColors.bgDark,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : Text(
                    l10n.save,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      backgroundColor: AppColors.bgDark,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 8),

              // Avatar picker
              ProfileAvatar(
                avatarUrl: _selectedAvatarPath,
                displayName: user.displayName,
                radius: 50,
                onTap: _pickAvatar,
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickAvatar,
                child: Text(
                  l10n.changePhoto,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Display Name
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  l10n.displayName,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _displayNameController,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.displayNameRequired;
                  }
                  if (value.trim().length > 30) {
                    return l10n.displayNameTooLong;
                  }
                  return null;
                },
                decoration: InputDecoration(
                  hintText: l10n.yourDisplayName,
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.bgCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
                style: const TextStyle(color: AppColors.textPrimary),
              ),

              const SizedBox(height: 20),

              // Username
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  l10n.username,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _usernameController,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null;
                  final trimmed = value.trim();
                  if (trimmed.length < 3) return l10n.usernameTooShort;
                  if (trimmed.length > 20) return l10n.usernameTooLong;
                  if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(trimmed)) {
                    return l10n.usernameInvalid;
                  }
                  return null;
                },
                decoration: InputDecoration(
                  hintText: l10n.username,
                  prefixText: '@',
                  prefixStyle: const TextStyle(color: AppColors.textMuted),
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.bgCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
                style: const TextStyle(color: AppColors.textPrimary),
              ),

              const SizedBox(height: 20),

              // Bio
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  l10n.bio,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bioController,
                maxLines: 3,
                validator: (value) {
                  if (value != null && value.trim().length > 200) {
                    return l10n.bioTooLong;
                  }
                  return null;
                },
                decoration: InputDecoration(
                  hintText: l10n.tellUsAboutYourself,
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.bgCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
                style: const TextStyle(color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
