import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'app_card.dart';

class FeaturePlaceholderScreen extends StatelessWidget {
  const FeaturePlaceholderScreen({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.icon,
    required this.nextLabel,
  });

  final String eyebrow;
  final String title;
  final String description;
  final IconData icon;
  final String nextLabel;

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
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
                children: [
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
                        eyebrow,
                        style: textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 34),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const ShapeDecoration(
                      color: AppColors.deepForest,
                      shape: ContinuousRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(24)),
                      ),
                    ),
                    child: Icon(icon, color: AppColors.terracotta, size: 30),
                  ),
                  const SizedBox(height: 24),
                  Text(title, style: textTheme.displaySmall),
                  const SizedBox(height: 14),
                  Text(
                    description,
                    style: textTheme.bodyLarge?.copyWith(
                      color: AppColors.mutedForest,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 30),
                  AppCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          CupertinoIcons.clock,
                          size: 18,
                          color: AppColors.terracotta,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('In progress', style: textTheme.titleMedium),
                              const SizedBox(height: 5),
                              Text(
                                nextLabel,
                                style: textTheme.bodySmall?.copyWith(
                                  height: 1.55,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
