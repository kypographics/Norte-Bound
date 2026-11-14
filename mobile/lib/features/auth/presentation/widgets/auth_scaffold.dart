import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_card.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.footer,
    this.backLocation,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? footer;
  final String? backLocation;

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
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                children: [
                  _BrandLockup(backLocation: backLocation),
                  const SizedBox(height: 40),
                  Text(title, style: textTheme.displaySmall),
                  const SizedBox(height: 12),
                  Text(
                    subtitle,
                    style: textTheme.bodyLarge?.copyWith(
                      color: AppColors.mutedForest,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 28),
                  AppCard(padding: const EdgeInsets.all(22), child: child),
                  if (footer != null) ...[const SizedBox(height: 22), footer!],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        CupertinoIcons.checkmark_shield,
                        size: 14,
                        color: AppColors.mutedForest,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Secure access to verified northern journeys.',
                        style: textTheme.labelSmall?.copyWith(
                          color: AppColors.mutedForest,
                          letterSpacing: 0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: ShapeDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        shape: ContinuousRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          side: BorderSide(
            color: AppColors.danger.withValues(alpha: 0.28),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_circle,
            size: 18,
            color: AppColors.danger,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.danger,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthSwitchPrompt extends StatelessWidget {
  const AuthSwitchPrompt({
    super.key,
    required this.prompt,
    required this.actionLabel,
    required this.onPressed,
  });

  final String prompt;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      children: [
        Text(
          prompt,
          style: textTheme.bodySmall?.copyWith(
            color: AppColors.mutedForest,
            fontWeight: FontWeight.w500,
          ),
        ),
        TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: const Size(0, 36),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(actionLabel),
        ),
      ],
    );
  }
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup({this.backLocation});

  final String? backLocation;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final location = backLocation;

    return Row(
      children: [
        if (location != null) ...[
          IconButton(
            onPressed: () => context.go(location),
            tooltip: 'Back',
            icon: const Icon(CupertinoIcons.chevron_left, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.ivorySand,
              side: const BorderSide(color: AppColors.hairline, width: 0.5),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: AppColors.deepForest,
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          child: const Icon(
            CupertinoIcons.compass,
            color: AppColors.ivorySand,
            size: 26,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppConfig.appName,
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
