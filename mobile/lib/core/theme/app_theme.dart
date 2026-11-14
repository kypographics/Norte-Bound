import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData get light {
    final textTheme = AppTypography.textTheme;

    final colorScheme = ColorScheme.light(
      primary: AppColors.deepForest,
      onPrimary: AppColors.ivorySand,
      secondary: AppColors.terracotta,
      onSecondary: AppColors.deepForest,
      surface: AppColors.ivorySand,
      onSurface: AppColors.deepForest,
      surfaceContainerHighest: AppColors.warmSand,
      onSurfaceVariant: AppColors.mutedForest,
      outline: AppColors.hairline,
      outlineVariant: AppColors.hairline,
      error: AppColors.danger,
      onError: AppColors.white,
      shadow: AppColors.deepForest.withValues(alpha: 0.08),
      scrim: AppColors.deepForest.withValues(alpha: 0.5),
      inverseSurface: AppColors.deepForest,
      onInverseSurface: AppColors.ivorySand,
      inversePrimary: AppColors.skyBlue,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.warmSand,
      canvasColor: AppColors.warmSand,
      textTheme: textTheme,
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.warmSand.withValues(alpha: 0.82),
        foregroundColor: AppColors.deepForest,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: AppColors.warmSand,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.ivorySand,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: const ContinuousRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
          side: BorderSide(color: AppColors.hairline, width: 0.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          backgroundColor: AppColors.terracotta,
          foregroundColor: AppColors.deepForest,
          disabledBackgroundColor: AppColors.terracottaWash,
          disabledForegroundColor: AppColors.mutedForest,
          textStyle: textTheme.labelLarge,
          shape: const StadiumBorder(),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.deepForest,
          textStyle: textTheme.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: AppColors.deepForest),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.ivorySand,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.mutedForest.withValues(alpha: 0.8),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.mutedForest,
        ),
        floatingLabelStyle: textTheme.labelMedium?.copyWith(
          color: AppColors.deepForest,
        ),
        errorStyle: textTheme.bodySmall?.copyWith(color: AppColors.danger),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          borderSide: BorderSide(color: AppColors.hairline, width: 0.5),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          borderSide: BorderSide(color: AppColors.hairline, width: 0.5),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          borderSide: BorderSide(color: AppColors.terracotta, width: 1.2),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          borderSide: BorderSide(color: AppColors.danger, width: 1),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          borderSide: BorderSide(color: AppColors.danger, width: 1.2),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.hairline,
        thickness: 0.5,
        space: 24,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.ivorySand,
        modalBackgroundColor: AppColors.ivorySand,
        modalBarrierColor: AppColors.deepForest.withValues(alpha: 0.4),
        elevation: 0,
        modalElevation: 0,
        showDragHandle: true,
        dragHandleColor: AppColors.deepForest.withValues(alpha: 0.16),
        shape: const ContinuousRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.deepForest,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.ivorySand,
        ),
        elevation: 0,
        insetPadding: const EdgeInsets.all(20),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: AppColors.ivorySand,
        indicatorColor: AppColors.skyBlueWash,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelMedium?.copyWith(
            color: selected ? AppColors.deepForest : AppColors.mutedForest,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData?>((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.deepForest : AppColors.mutedForest,
            size: 24,
          );
        }),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.terracotta,
        selectionColor: AppColors.skyBlueWash,
        selectionHandleColor: AppColors.terracotta,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.terracotta,
      ),
    );
  }
}
