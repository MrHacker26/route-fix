import 'package:flutter/material.dart';

import 'app_colors.dart';

/// RouteFix type scale — tight tracking, clear hierarchy.
abstract final class AppTypography {
  static const String _fontFamily = 'SF Pro Display';
  static const List<String> _fallbacks = [
    'SF Pro Text',
    'Segoe UI',
    'Roboto',
    'Helvetica Neue',
    'Arial',
  ];

  static const TextStyle _base = TextStyle(
    fontFamily: _fontFamily,
    fontFamilyFallback: _fallbacks,
    color: AppColors.onSurface,
    letterSpacing: -0.2,
    height: 1.35,
  );

  static TextTheme get textTheme => TextTheme(
        displayLarge: _base.copyWith(
          fontSize: 56,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.4,
          height: 1.1,
        ),
        displayMedium: _base.copyWith(
          fontSize: 44,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.1,
          height: 1.12,
        ),
        displaySmall: _base.copyWith(
          fontSize: 36,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.9,
          height: 1.15,
        ),
        headlineLarge: _base.copyWith(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.7,
        ),
        headlineMedium: _base.copyWith(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
        headlineSmall: _base.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
        ),
        titleLarge: _base.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        titleMedium: _base.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.15,
        ),
        titleSmall: _base.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
        ),
        bodyLarge: _base.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.1,
          height: 1.5,
        ),
        bodyMedium: _base.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.05,
          height: 1.5,
        ),
        bodySmall: _base.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
          height: 1.45,
          color: AppColors.onSurfaceVariant,
        ),
        labelSmall: _base.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.08,
          color: AppColors.onSurfaceMuted,
        ),
        labelMedium: _base.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.12,
          color: AppColors.onSurfaceMuted,
        ),
        labelLarge: _base.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.05,
        ),
      );
}
