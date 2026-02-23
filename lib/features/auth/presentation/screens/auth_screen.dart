import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:travel_buddy_mobile/core/theme/app_theme.dart';
import 'package:travel_buddy_mobile/shared/providers/auth_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isLogin = true;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(authProvider.notifier);
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (_isLogin) {
      notifier.signIn(email, password);
    } else {
      final name = _nameController.text.trim();
      notifier.signUp(email, password, name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authProvider);

    // Navigate home when authenticated
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.isAuthenticated) {
        context.go('/');
      }
    });

    // Show error snackbar
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.errorMessage != null && next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(authProvider.notifier).clearError();
      }
    });

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                Icon(
                  LucideIcons.compass,
                  size: 64,
                  color: AppColors.primary,
                ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                const SizedBox(height: 24),
                Text(
                  l10n.travelBuddy,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ).animate().fadeIn(duration: 500.ms),
                const SizedBox(height: 8),
                Text(
                  l10n.gamifiedTravelCompanion,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ).animate().fadeIn(duration: 600.ms),
                const SizedBox(height: 48),

                // Toggle
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _TabButton(
                        label: l10n.login,
                        isActive: _isLogin,
                        onTap: () => setState(() => _isLogin = true),
                      ),
                      _TabButton(
                        label: l10n.signUp,
                        isActive: !_isLogin,
                        onTap: () => setState(() => _isLogin = false),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Name field (sign up only)
                if (!_isLogin) ...[
                  _InputField(
                    controller: _nameController,
                    label: l10n.displayName,
                    icon: LucideIcons.user,
                    validator: (value) {
                      if (!_isLogin && (value == null || value.trim().isEmpty)) {
                        return l10n.pleaseEnterName;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                _InputField(
                  controller: _emailController,
                  label: l10n.email,
                  icon: LucideIcons.mail,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.pleaseEnterEmail;
                    }
                    if (!value.contains('@')) {
                      return l10n.pleaseEnterValidEmail;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _InputField(
                  controller: _passwordController,
                  label: l10n.password,
                  icon: LucideIcons.lock,
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.pleaseEnterPassword;
                    }
                    if (value.length < 6) {
                      return l10n.passwordMinLength;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: authState.isLoading ? null : _submit,
                  child: authState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_isLogin ? l10n.login : l10n.createAccount),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _InputField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _InputField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
  });

  @override
  State<_InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<_InputField> {
  late bool _hidden;

  @override
  void initState() {
    super.initState();
    _hidden = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _hidden,
      keyboardType: widget.keyboardType,
      validator: widget.validator,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: Icon(widget.icon, size: 20),
        suffixIcon: widget.obscureText
            ? IconButton(
                icon: Icon(
                  _hidden ? LucideIcons.eyeOff : LucideIcons.eye,
                  size: 20,
                ),
                onPressed: () => setState(() => _hidden = !_hidden),
              )
            : null,
        filled: true,
        fillColor: AppColors.bgCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}
