import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class DestinationArtworkStyle {
  const DestinationArtworkStyle({
    required this.icon,
    required this.startColor,
    required this.endColor,
  });

  final IconData icon;
  final Color startColor;
  final Color endColor;

  LinearGradient get gradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [startColor, endColor],
  );
}

DestinationArtworkStyle destinationStyleFor(String categoryCode) {
  return switch (categoryCode) {
    'natural_attraction' => const DestinationArtworkStyle(
      icon: CupertinoIcons.tree,
      startColor: Color(0xFF153425),
      endColor: Color(0xFF4E7C5E),
    ),
    'heritage_cultural' => const DestinationArtworkStyle(
      icon: CupertinoIcons.building_2_fill,
      startColor: Color(0xFF3B2A20),
      endColor: Color(0xFFA4694D),
    ),
    'food_culinary' => const DestinationArtworkStyle(
      icon: Icons.restaurant,
      startColor: Color(0xFF8C3B23),
      endColor: AppColors.terracotta,
    ),
    'agro_eco_tourism' => const DestinationArtworkStyle(
      icon: CupertinoIcons.sun_max,
      startColor: Color(0xFF314A2F),
      endColor: Color(0xFF8AA36F),
    ),
    'artisan_craft_experience' => const DestinationArtworkStyle(
      icon: CupertinoIcons.sparkles,
      startColor: Color(0xFF4A382A),
      endColor: Color(0xFFB48A66),
    ),
    'recreation_adventure' => const DestinationArtworkStyle(
      icon: CupertinoIcons.car,
      startColor: Color(0xFF1E3B48),
      endColor: Color(0xFF5D8DA0),
    ),
    _ => const DestinationArtworkStyle(
      icon: CupertinoIcons.compass,
      startColor: AppColors.deepForest,
      endColor: Color(0xFF335A3F),
    ),
  };
}

class DestinationArtwork extends StatelessWidget {
  const DestinationArtwork({
    super.key,
    required this.categoryCode,
    this.borderRadius = 18,
    this.iconSize = 42,
  });

  final String categoryCode;
  final double borderRadius;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final style = destinationStyleFor(categoryCode);
    final shape = ContinuousRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
    );

    return ClipPath(
      clipper: ShapeBorderClipper(shape: shape),
      child: DecoratedBox(
        decoration: BoxDecoration(gradient: style.gradient),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              right: -18,
              top: -22,
              child: Icon(
                style.icon,
                size: iconSize * 2.4,
                color: AppColors.ivorySand.withValues(alpha: 0.1),
              ),
            ),
            Positioned(
              left: -12,
              bottom: -20,
              child: Container(
                width: iconSize * 1.9,
                height: iconSize * 1.9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.warmSand.withValues(alpha: 0.08),
                ),
              ),
            ),
            Center(
              child: Container(
                width: iconSize * 1.35,
                height: iconSize * 1.35,
                decoration: ShapeDecoration(
                  color: AppColors.ivorySand.withValues(alpha: 0.14),
                  shape: ContinuousRectangleBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(iconSize * 0.42),
                    ),
                    side: BorderSide(
                      color: AppColors.ivorySand.withValues(alpha: 0.18),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Icon(
                  style.icon,
                  size: iconSize,
                  color: AppColors.ivorySand,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
