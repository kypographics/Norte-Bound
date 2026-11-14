import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../domain/models/travel_preferences.dart';
import '../domain/models/user.dart';
import 'auth_providers.dart';
import 'auth_validators.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/auth_text_field.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).value;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return _ProfileView(user: user);
  }
}

class _ProfileView extends ConsumerStatefulWidget {
  const _ProfileView({required this.user});

  final User user;

  @override
  ConsumerState<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends ConsumerState<_ProfileView> {
  late TransportMode _transportMode;
  late BudgetScope _budgetScope;
  late TravelPacing _pacing;
  late int _groupSize;
  late List<String> _favoriteTags;

  bool _isSavingDefaults = false;
  bool _isSavingName = false;

  @override
  void initState() {
    super.initState();
    _hydratePreferences();
  }

  void _hydratePreferences() {
    final preferences =
        widget.user.travelPreferences ?? TravelPreferences.defaults;

    _transportMode = preferences.defaultTransportMode;
    _budgetScope = preferences.defaultBudgetScope;
    _pacing = preferences.defaultPacing;
    _groupSize = preferences.defaultGroupSize;
    _favoriteTags = List<String>.of(preferences.favoriteTags);
  }

  Future<void> _editName() async {
    final name = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      builder: (context) => _EditNameSheet(initialName: widget.user.fullName),
    );

    if (!mounted || name == null || name == widget.user.fullName) {
      return;
    }

    setState(() => _isSavingName = true);

    try {
      await ref
          .read(authNotifierProvider.notifier)
          .updateProfile(fullName: name);

      if (mounted) {
        _showFeedback('Your name has been updated.');
      }
    } on ApiException catch (error) {
      if (mounted) {
        _showFeedback(error.message, isError: true);
      }
    } catch (_) {
      if (mounted) {
        _showFeedback(
          'Unable to update your name. Please try again.',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingName = false);
      }
    }
  }

  Future<void> _saveDefaults() async {
    if (_isSavingDefaults) {
      return;
    }

    setState(() => _isSavingDefaults = true);

    try {
      await ref
          .read(authNotifierProvider.notifier)
          .updateProfile(
            travelPreferences: TravelPreferences(
              defaultTransportMode: _transportMode,
              defaultBudgetScope: _budgetScope,
              defaultGroupSize: _groupSize,
              defaultPacing: _pacing,
              favoriteTags: List.unmodifiable(_favoriteTags),
            ),
          );

      if (mounted) {
        _showFeedback('Travel defaults saved.');
      }
    } on ApiException catch (error) {
      if (mounted) {
        _showFeedback(error.message, isError: true);
      }
    } catch (_) {
      if (mounted) {
        _showFeedback(
          'Unable to save your travel defaults. Please try again.',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingDefaults = false);
      }
    }
  }

  Future<void> _openPasswordSheet() async {
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      builder: (context) => const _ChangePasswordSheet(),
    );

    if (updated == true && mounted) {
      _showFeedback('Your password has been updated.');
    }
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.ivorySand,
          shape: const ContinuousRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(24)),
            side: BorderSide(color: AppColors.hairline, width: 0.5),
          ),
          title: const Text('Sign out?'),
          content: const Text(
            'You will need to sign in again to plan and save journeys on this '
            'device.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    HapticFeedback.mediumImpact();
    await ref.read(authNotifierProvider.notifier).logout();
  }

  void _showFeedback(String message, {bool isError = false}) {
    if (!mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          content: Text(message),
          backgroundColor: isError ? AppColors.danger : AppColors.deepForest,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.warmSand, Color(0xFFF0DFC9)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: ListView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
                children: [
                  const _BrandHeader(),
                  const SizedBox(height: 36),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: const ShapeDecoration(
                        color: AppColors.skyBlueWash,
                        shape: StadiumBorder(),
                      ),
                      child: Text(
                        'YOUR ACCOUNT',
                        style: textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text('Your profile.', style: textTheme.displaySmall),
                  const SizedBox(height: 12),
                  Text(
                    'Keep your identity and travel defaults current so every '
                    'recommendation starts closer to you.',
                    style: textTheme.bodyLarge?.copyWith(
                      color: AppColors.mutedForest,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _buildIdentityCard(context),
                  const SizedBox(height: 18),
                  _buildTravelDefaults(context),
                  const SizedBox(height: 18),
                  _buildSecurityCard(context),
                  const SizedBox(height: 18),
                  _buildSignOutCard(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIdentityCard(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final role = widget.user.role;
    final isAdmin = role == UserRole.admin;

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const ShapeDecoration(
                  color: AppColors.deepForest,
                  shape: ContinuousRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(22)),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  _initials(widget.user.fullName),
                  style: textTheme.headlineSmall?.copyWith(
                    color: AppColors.terracotta,
                    fontSize: 22,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.user.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.user.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.mutedForest,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: ShapeDecoration(
                        color: isAdmin
                            ? AppColors.terracotta
                            : AppColors.skyBlueWash,
                        shape: const StadiumBorder(),
                      ),
                      child: Text(
                        isAdmin ? 'CURATOR ADMIN' : 'TOURIST',
                        style: textTheme.labelSmall?.copyWith(
                          fontSize: 9.5,
                          letterSpacing: 0.8,
                          color: AppColors.deepForest,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _isSavingName ? null : _editName,
                tooltip: 'Edit name',
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.warmSand.withValues(alpha: 0.6),
                  side: const BorderSide(color: AppColors.hairline, width: 0.5),
                ),
                icon: _isSavingName
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(CupertinoIcons.pencil, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, thickness: 0.5),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                CupertinoIcons.checkmark_shield,
                size: 15,
                color: AppColors.mutedForest,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  _memberSince(widget.user.createdAt),
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.mutedForest,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTravelDefaults(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const ShapeDecoration(
                  color: AppColors.skyBlueWash,
                  shape: ContinuousRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(15)),
                  ),
                ),
                child: const Icon(
                  CupertinoIcons.map,
                  size: 19,
                  color: AppColors.deepForest,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Travel baseline', style: textTheme.titleLarge),
                    const SizedBox(height: 2),
                    Text(
                      'Defaults used when you start a new plan.',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.mutedForest,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _PreferenceBlock(
            label: 'Transport',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final mode in TransportMode.values)
                  _OptionPill(
                    label: mode.label,
                    selected: _transportMode == mode,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _transportMode = mode);
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _PreferenceBlock(
            label: 'Budget scope',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final scope in BudgetScope.values)
                  _OptionPill(
                    label: scope.label,
                    selected: _budgetScope == scope,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _budgetScope = scope);
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _PreferenceBlock(
            label: 'Travel pace',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final pace in TravelPacing.values)
                  _OptionPill(
                    label: pace.label,
                    selected: _pacing == pace,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _pacing = pace);
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Group size', style: textTheme.labelMedium),
                    const SizedBox(height: 3),
                    Text(
                      'Default number of travelers.',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.mutedForest,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              _GroupSizeStepper(
                value: _groupSize,
                onChanged: (value) {
                  if (value == _groupSize) {
                    return;
                  }

                  HapticFeedback.selectionClick();
                  setState(() => _groupSize = value);
                },
              ),
            ],
          ),
          const SizedBox(height: 22),
          PrimaryButton(
            label: 'Save Travel Defaults',
            icon: CupertinoIcons.checkmark,
            expanded: true,
            isLoading: _isSavingDefaults,
            onPressed: _saveDefaults,
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityCard(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      onTap: _openPasswordSheet,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const ShapeDecoration(
              color: AppColors.skyBlueWash,
              shape: ContinuousRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(15)),
              ),
            ),
            child: const Icon(
              CupertinoIcons.lock_shield,
              size: 19,
              color: AppColors.deepForest,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Change password', style: textTheme.titleMedium),
                const SizedBox(height: 3),
                Text(
                  'Keep your account protected.',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedForest,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            CupertinoIcons.chevron_right,
            size: 17,
            color: AppColors.mutedForest,
          ),
        ],
      ),
    );
  }

  Widget _buildSignOutCard(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      onTap: _confirmSignOut,
      color: AppColors.danger.withValues(alpha: 0.04),
      borderColor: AppColors.danger.withValues(alpha: 0.18),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: ShapeDecoration(
              color: AppColors.danger.withValues(alpha: 0.08),
              shape: const ContinuousRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(15)),
              ),
            ),
            child: const Icon(
              CupertinoIcons.square_arrow_right,
              size: 19,
              color: AppColors.danger,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sign Out',
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.danger,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'End this session on this device.',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedForest,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            CupertinoIcons.chevron_right,
            size: 17,
            color: AppColors.danger,
          ),
        ],
      ),
    );
  }

  String _initials(String fullName) {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return 'NB';
    }

    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }

  String _memberSince(DateTime? createdAt) {
    if (createdAt == null) {
      return 'NORTE BOUND MEMBER';
    }

    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    final local = createdAt.toLocal();

    return 'MEMBER SINCE ${months[local.month - 1]} ${local.year}';
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: const ShapeDecoration(
            color: AppColors.deepForest,
            shape: ContinuousRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(15)),
            ),
          ),
          child: const Icon(
            CupertinoIcons.compass,
            color: AppColors.ivorySand,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'NORTE BOUND',
              style: textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 1.8,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'ILOCOS NORTE \u00B7 PHILIPPINES',
              style: textTheme.labelSmall?.copyWith(
                color: AppColors.mutedForest,
                fontSize: 10,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PreferenceBlock extends StatelessWidget {
  const _PreferenceBlock({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: textTheme.labelMedium),
        const SizedBox(height: 9),
        child,
      ],
    );
  }
}

class _OptionPill extends StatelessWidget {
  const _OptionPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: selected
          ? AppColors.deepForest
          : AppColors.warmSand.withValues(alpha: 0.58),
      shape: ContinuousRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        side: BorderSide(
          color: selected ? AppColors.deepForest : AppColors.hairline,
          width: 0.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const ContinuousRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            label,
            style: textTheme.labelMedium?.copyWith(
              color: selected ? AppColors.ivorySand : AppColors.deepForest,
            ),
          ),
        ),
      ),
    );
  }
}

class _GroupSizeStepper extends StatelessWidget {
  const _GroupSizeStepper({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: const ShapeDecoration(
        color: AppColors.warmSand,
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: AppColors.hairline, width: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(
            icon: CupertinoIcons.minus,
            tooltip: 'Decrease group size',
            onPressed: value > 1 ? () => onChanged(value - 1) : null,
          ),
          SizedBox(
            width: 38,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                fontFeatures: AppTypography.tabularFigures,
              ),
            ),
          ),
          _StepperButton(
            icon: CupertinoIcons.plus,
            tooltip: 'Increase group size',
            onPressed: value < 50 ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon, size: 17),
      style: IconButton.styleFrom(
        minimumSize: const Size.square(34),
        maximumSize: const Size.square(34),
        padding: EdgeInsets.zero,
        backgroundColor: AppColors.ivorySand,
        disabledBackgroundColor: AppColors.ivorySand.withValues(alpha: 0.45),
        foregroundColor: AppColors.deepForest,
        disabledForegroundColor: AppColors.mutedForest.withValues(alpha: 0.4),
        side: const BorderSide(color: AppColors.hairline, width: 0.5),
        shape: const ContinuousRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    );
  }
}

class _EditNameSheet extends StatefulWidget {
  const _EditNameSheet({required this.initialName});

  final String initialName;

  @override
  State<_EditNameSheet> createState() => _EditNameSheetState();
}

class _EditNameSheetState extends State<_EditNameSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    FocusScope.of(context).unfocus();
    Navigator.of(context).pop(_nameController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        4,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Edit name', style: textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text(
              'Use the name you want other travelers and curators to see.',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.mutedForest,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 22),
            Form(
              key: _formKey,
              child: AuthTextField(
                controller: _nameController,
                label: 'Full name',
                hintText: 'Juan Dela Cruz',
                icon: CupertinoIcons.person,
                keyboardType: TextInputType.name,
                textInputAction: TextInputAction.done,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.name],
                validator: AuthValidators.profileFullName,
                onFieldSubmitted: (_) => _submit(),
              ),
            ),
            const SizedBox(height: 22),
            PrimaryButton(
              label: 'Save Changes',
              icon: CupertinoIcons.checkmark,
              expanded: true,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChangePasswordSheet extends ConsumerStatefulWidget {
  const _ChangePasswordSheet();

  @override
  ConsumerState<_ChangePasswordSheet> createState() =>
      _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends ConsumerState<_ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }
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
          .changePassword(
            currentPassword: _currentController.text,
            newPassword: _newController.text,
          );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _errorMessage = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _errorMessage =
              'Unable to update your password. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        4,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: AutofillGroup(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Change password', style: textTheme.headlineSmall),
                const SizedBox(height: 6),
                Text(
                  'Confirm your current password, then choose a new one.',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedForest,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 22),
                AuthTextField(
                  controller: _currentController,
                  label: 'Current password',
                  hintText: 'Enter your current password',
                  icon: CupertinoIcons.lock,
                  obscureText: _obscureCurrent,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.password],
                  validator: AuthValidators.password,
                  onChanged: (_) => _clearError(),
                  suffixIcon: _VisibilityToggle(
                    obscured: _obscureCurrent,
                    onPressed: () {
                      setState(() => _obscureCurrent = !_obscureCurrent);
                    },
                  ),
                ),
                const SizedBox(height: 18),
                AuthTextField(
                  controller: _newController,
                  label: 'New password',
                  hintText: 'At least 8 characters',
                  icon: CupertinoIcons.lock_shield,
                  obscureText: _obscureNew,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  helperText: 'Use 8 to 72 characters.',
                  validator: AuthValidators.newPassword,
                  onChanged: (_) => _clearError(),
                  suffixIcon: _VisibilityToggle(
                    obscured: _obscureNew,
                    onPressed: () {
                      setState(() => _obscureNew = !_obscureNew);
                    },
                  ),
                ),
                const SizedBox(height: 18),
                AuthTextField(
                  controller: _confirmController,
                  label: 'Confirm new password',
                  hintText: 'Re-enter your new password',
                  icon: CupertinoIcons.lock_shield,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: (value) {
                    final error = AuthValidators.newPassword(value);

                    if (error != null) {
                      return error;
                    }

                    if (value != _newController.text) {
                      return 'Passwords do not match.';
                    }

                    return null;
                  },
                  onChanged: (_) => _clearError(),
                  onFieldSubmitted: (_) => _submit(),
                  suffixIcon: _VisibilityToggle(
                    obscured: _obscureConfirm,
                    onPressed: () {
                      setState(() => _obscureConfirm = !_obscureConfirm);
                    },
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 18),
                  AuthErrorBanner(message: _errorMessage!),
                ],
                const SizedBox(height: 22),
                PrimaryButton(
                  label: 'Update Password',
                  icon: CupertinoIcons.checkmark,
                  expanded: true,
                  isLoading: _isSubmitting,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VisibilityToggle extends StatelessWidget {
  const _VisibilityToggle({required this.obscured, required this.onPressed});

  final bool obscured;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: obscured ? 'Show password' : 'Hide password',
      icon: Icon(
        obscured ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
        size: 20,
      ),
    );
  }
}
