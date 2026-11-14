import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../../../core/constants/app_config.dart';
import '../../../core/theme/app_colors.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: const BoxDecoration(
                    color: AppColors.deepForest,
                    borderRadius: BorderRadius.all(Radius.circular(24)),
                  ),
                  child: const Icon(
                    CupertinoIcons.compass,
                    color: AppColors.ivorySand,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  AppConfig.appName,
                  style: textTheme.labelLarge?.copyWith(letterSpacing: 3),
                ),
                const SizedBox(height: 8),
                Text(
                  AppConfig.appTagline,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.mutedForest,
                  ),
                ),
                const SizedBox(height: 36),
                const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
