import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_card.dart';

class DiscoveryScreen extends StatelessWidget {
  const DiscoveryScreen({super.key});

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
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
                children: [
                  Row(
                    children: [
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
                            'NORTE BOUND',
                            style: textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.8,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'ILOCOS NORTE · PHILIPPINES',
                            style: textTheme.labelSmall?.copyWith(
                              color: AppColors.mutedForest,
                              fontSize: 10,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 44),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.skyBlueWash,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(999),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            CupertinoIcons.compass,
                            size: 13,
                            color: AppColors.deepForest,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '22 LGUS · ONE NORTHERN COAST',
                            style: textTheme.labelSmall?.copyWith(fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text('Find your\nnorth.', style: textTheme.displayLarge),
                  const SizedBox(height: 16),
                  Text(
                    'Verified places, thoughtful routes, and a clear sense of '
                    'direction across Ilocos Norte.',
                    style: textTheme.bodyLarge?.copyWith(
                      color: AppColors.mutedForest,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const _HeroPanel(),
                  const SizedBox(height: 18),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        const _CapabilityRow(
                          icon: CupertinoIcons.tree,
                          title: 'Discover',
                          description:
                              'Browse a verified catalog across all 22 LGUs.',
                        ),
                        const Divider(height: 0.5, thickness: 0.5),
                        const _CapabilityRow(
                          icon: CupertinoIcons.sparkles,
                          title: 'Personalize',
                          description:
                              'Turn natural-language intent into clear '
                              'trip constraints.',
                        ),
                        const Divider(height: 0.5, thickness: 0.5),
                        const _CapabilityRow(
                          icon: CupertinoIcons.location,
                          title: 'Plan',
                          description:
                              'Shape time-aware routes around real '
                              'distances and costs.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        CupertinoIcons.checkmark_shield,
                        size: 16,
                        color: AppColors.mutedForest,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Every detail is grounded in verified local data.',
                          style: textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
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

class _HeroPanel extends StatelessWidget {
  const _HeroPanel();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      color: AppColors.deepForest,
      borderColor: AppColors.deepForest,
      padding: const EdgeInsets.all(24),
      child: Stack(
        children: [
          Positioned(
            right: -36,
            top: -40,
            child: Icon(
              CupertinoIcons.map,
              size: 180,
              color: AppColors.ivorySand.withValues(alpha: 0.05),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.skyBlueWash,
                  borderRadius: const BorderRadius.all(Radius.circular(999)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      CupertinoIcons.sparkles,
                      size: 13,
                      color: AppColors.deepForest,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'CONTEXT-AWARE PLANNING',
                      style: textTheme.labelSmall?.copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Every stop earns\nits place.',
                style: textTheme.headlineLarge?.copyWith(
                  color: AppColors.ivorySand,
                  fontSize: 30,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Routes take shape around your time, budget, pace, and '
                'appetite — never around guesswork.',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.warmSand.withValues(alpha: 0.78),
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 22),
              const Wrap(
                spacing: 24,
                runSpacing: 16,
                children: [
                  _HeroStat(value: '22', label: 'LGUs'),
                  _HeroStat(value: '4', label: 'Tourism clusters'),
                  _HeroStat(value: '6', label: 'Categories'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: textTheme.headlineSmall?.copyWith(
            color: AppColors.ivorySand,
            fontFeatures: AppTypography.tabularFigures,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: AppColors.warmSand.withValues(alpha: 0.62),
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class _CapabilityRow extends StatelessWidget {
  const _CapabilityRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.skyBlueWash,
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
            child: Icon(icon, size: 20, color: AppColors.deepForest),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: textTheme.bodySmall?.copyWith(height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
