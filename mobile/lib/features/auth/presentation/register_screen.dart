import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/primary_button.dart';
import '../domain/models/user.dart';
import 'auth_providers.dart';
import 'auth_validators.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/auth_text_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _inviteCodeController = TextEditingController();

  UserRole _role = UserRole.tourist;
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (_isSubmitting || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(authNotifierProvider.notifier)
          .register(
            fullName: _fullNameController.text.trim(),
            email: _emailController.text.trim().toLowerCase(),
            password: _passwordController.text,
            role: _role,
            adminInviteCode: _role == UserRole.admin
                ? _inviteCodeController.text.trim()
                : null,
          );

      TextInput.finishAutofillContext();
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _errorMessage = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _errorMessage =
              'Unable to create your account. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _clearError() {
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }
  }

  void _selectRole(UserRole role) {
    if (_role == role) {
      return;
    }

    HapticFeedback.selectionClick();
    setState(() => _role = role);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AuthScaffold(
      backLocation: AppRoutes.login,
      title: 'Create your account.',
      subtitle:
          'Join NORTE BOUND to discover verified places and shape journeys '
          'around your time, budget, and pace.',
      footer: AuthSwitchPrompt(
        prompt: 'Already have an account?',
        actionLabel: 'Sign in',
        onPressed: () => context.go(AppRoutes.login),
      ),
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Your northern profile', style: textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(
                'Choose how you will travel with us.',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.mutedForest,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              AuthTextField(
                controller: _fullNameController,
                label: 'Full name',
                hintText: 'Juan Dela Cruz',
                icon: CupertinoIcons.person,
                keyboardType: TextInputType.name,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.name],
                validator: AuthValidators.fullName,
                onChanged: (_) => _clearError(),
              ),
              const SizedBox(height: 18),
              AuthTextField(
                controller: _emailController,
                label: 'Email address',
                hintText: 'you@example.com',
                icon: CupertinoIcons.mail,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: AuthValidators.email,
                onChanged: (_) => _clearError(),
              ),
              const SizedBox(height: 18),
              AuthTextField(
                controller: _passwordController,
                label: 'Password',
                hintText: 'At least 8 characters',
                icon: CupertinoIcons.lock,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                helperText: 'Use 8 to 72 characters.',
                validator: AuthValidators.newPassword,
                onChanged: (_) => _clearError(),
                onFieldSubmitted: (_) => _submit(),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                  tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                  icon: Icon(
                    _obscurePassword
                        ? CupertinoIcons.eye
                        : CupertinoIcons.eye_slash,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text('I am joining as', style: textTheme.labelMedium),
              const SizedBox(height: 8),
              _RoleSelector(selected: _role, onSelected: _selectRole),
              if (_role == UserRole.admin) ...[
                const SizedBox(height: 18),
                AuthTextField(
                  controller: _inviteCodeController,
                  label: 'Curator invite code',
                  hintText: 'Enter curator invite code',
                  icon: CupertinoIcons.lock_shield,
                  textInputAction: TextInputAction.done,
                  helperText: 'Required for curator accounts.',
                  validator: AuthValidators.inviteCode,
                  onChanged: (_) => _clearError(),
                  onFieldSubmitted: (_) => _submit(),
                ),
              ],
              if (_errorMessage != null) ...[
                const SizedBox(height: 18),
                AuthErrorBanner(message: _errorMessage!),
              ],
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Create Account',
                icon: CupertinoIcons.person_badge_plus,
                expanded: true,
                isLoading: _isSubmitting,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleSelector extends StatelessWidget {
  const _RoleSelector({required this.selected, required this.onSelected});

  final UserRole selected;
  final ValueChanged<UserRole> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: ShapeDecoration(
        color: AppColors.warmSand.withValues(alpha: 0.58),
        shape: const ContinuousRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          side: BorderSide(color: AppColors.hairline, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _RoleOption(
              icon: CupertinoIcons.person,
              title: UserRole.tourist.displayName,
              description: 'Discover and plan',
              selected: selected == UserRole.tourist,
              onTap: () => onSelected(UserRole.tourist),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _RoleOption(
              icon: CupertinoIcons.briefcase,
              title: UserRole.admin.displayName,
              description: 'Curate destinations',
              selected: selected == UserRole.admin,
              onTap: () => onSelected(UserRole.admin),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleOption extends StatelessWidget {
  const _RoleOption({
    required this.icon,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: selected ? AppColors.deepForest : Colors.transparent,
      shape: const ContinuousRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const ContinuousRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                size: 19,
                color: selected ? AppColors.terracotta : AppColors.mutedForest,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: textTheme.labelLarge?.copyWith(
                        color: selected
                            ? AppColors.ivorySand
                            : AppColors.deepForest,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelSmall?.copyWith(
                        color: selected
                            ? AppColors.warmSand.withValues(alpha: 0.7)
                            : AppColors.mutedForest,
                        letterSpacing: 0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
