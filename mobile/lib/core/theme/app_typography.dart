import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract final class AppTypography {
  static const tabularFigures = <FontFeature>[FontFeature.tabularFigures()];

  static final TextTheme textTheme = TextTheme(
    displayLarge: GoogleFonts.inter(
      fontSize: 52,
      fontWeight: FontWeight.w700,
      height: 1.04,
      letterSpacing: -0.8,
      color: AppColors.deepForest,
    ),
    displayMedium: GoogleFonts.inter(
      fontSize: 42,
      fontWeight: FontWeight.w700,
      height: 1.06,
      letterSpacing: -0.8,
      color: AppColors.deepForest,
    ),
    displaySmall: GoogleFonts.inter(
      fontSize: 34,
      fontWeight: FontWeight.w700,
      height: 1.1,
      letterSpacing: -0.6,
      color: AppColors.deepForest,
    ),
    headlineLarge: GoogleFonts.inter(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      height: 1.15,
      letterSpacing: -0.6,
      color: AppColors.deepForest,
    ),
    headlineMedium: GoogleFonts.inter(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      height: 1.2,
      letterSpacing: -0.4,
      color: AppColors.deepForest,
    ),
    headlineSmall: GoogleFonts.inter(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      height: 1.25,
      letterSpacing: -0.2,
      color: AppColors.deepForest,
    ),
    titleLarge: GoogleFonts.inter(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      height: 1.3,
      letterSpacing: -0.2,
      color: AppColors.deepForest,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.35,
      letterSpacing: -0.1,
      color: AppColors.deepForest,
    ),
    titleSmall: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.4,
      color: AppColors.deepForest,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.55,
      color: AppColors.deepForest,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: AppColors.deepForest,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.45,
      color: AppColors.mutedForest,
    ),
    labelLarge: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.25,
      letterSpacing: 0.1,
      color: AppColors.deepForest,
    ),
    labelMedium: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      height: 1.25,
      letterSpacing: 0.2,
      color: AppColors.deepForest,
    ),
    labelSmall: GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      height: 1.25,
      letterSpacing: 0.8,
      color: AppColors.deepForest,
    ),
  );
}
