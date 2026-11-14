import 'dart:ui';

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';

class AppShellScaffold extends StatelessWidget {
  const AppShellScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _dockShape = ContinuousRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(28)),
  );

  @override
  Widget build(BuildContext context) {
    const destinations = <_DockDestination>[
      _DockDestination(
        index: 0,
        icon: CupertinoIcons.compass,
        label: 'Explore',
      ),
      _DockDestination(
        index: 1,
        icon: CupertinoIcons.search,
        label: 'Search',
      ),
      _DockDestination(
        index: 2,
        icon: CupertinoIcons.sparkles,
        label: 'AI Co-Pilot',
      ),
      _DockDestination(
        index: 3,
        icon: CupertinoIcons.person_crop_circle,
        label: 'Profile',
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.warmSand,
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.deepForest.withValues(alpha: 0.2),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipPath(
            clipper: const ShapeBorderClipper(shape: _dockShape),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                height: 72,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                decoration: ShapeDecoration(
                  color: AppColors.deepForest.withValues(alpha: 0.82),
                  shape: const ContinuousRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(28)),
                    side: BorderSide(color: Color(0x2EFAF4EC), width: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    for (final destination in destinations)
                      Expanded(
                        child: _DockItem(
                          destination: destination,
                          selected:
                              navigationShell.currentIndex == destination.index,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            navigationShell.goBranch(
                              destination.index,
                              initialLocation:
                                  navigationShell.currentIndex ==
                                  destination.index,
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DockDestination {
  const _DockDestination({
    required this.index,
    required this.icon,
    required this.label,
  });

  final int index;
  final IconData icon;
  final String label;
}

class _DockItem extends StatelessWidget {
  const _DockItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _DockDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  width: 34,
                  height: 26,
                  decoration: ShapeDecoration(
                    color: selected ? AppColors.terracotta : Colors.transparent,
                    shape: const ContinuousRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                  ),
                  child: Icon(
                    destination.icon,
                    size: 18,
                    color: selected
                        ? AppColors.deepForest
                        : AppColors.warmSand.withValues(alpha: 0.62),
                  ),
                ),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    destination.label,
                    maxLines: 1,
                    style: textTheme.labelSmall?.copyWith(
                      color: selected
                          ? AppColors.ivorySand
                          : AppColors.warmSand.withValues(alpha: 0.52),
                      fontSize: 9.5,
                      letterSpacing: 0,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
