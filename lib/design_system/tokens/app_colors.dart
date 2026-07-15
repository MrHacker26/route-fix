import 'package:flutter/material.dart';

/// RouteFix color tokens — Material 3 dark, Linear / Raycast / Arc inspired.
abstract final class AppColors {
  // Surfaces
  static const Color background = Color(0xFF0C0C0E);
  static const Color surface = Color(0xFF111113);
  static const Color surfaceLow = Color(0xFF151517);
  static const Color surfaceContainer = Color(0xFF18181B);
  static const Color surfaceHigh = Color(0xFF1E1E22);
  static const Color surfaceHighest = Color(0xFF25252A);

  // Glass
  static const Color glassFill = Color(0x14FFFFFF);
  static const Color glassBorder = Color(0x1FFFFFFF);

  // Borders
  static const Color outline = Color(0xFF2E2E35);
  static const Color outlineSubtle = Color(0xFF222228);

  // Brand
  static const Color primary = Color(0xFF8B93FF);
  static const Color onPrimary = Color(0xFF0B0C1A);
  static const Color primaryContainer = Color(0xFF2A2F5C);
  static const Color onPrimaryContainer = Color(0xFFD4D7FF);
  static const Color primaryMuted = Color(0xFF5E6AD2);

  static const Color secondary = Color(0xFFFF7EB6);
  static const Color onSecondary = Color(0xFF1A0712);
  static const Color secondaryContainer = Color(0xFF4A1F35);

  static const Color tertiary = Color(0xFF6EE7F9);
  static const Color onTertiary = Color(0xFF002A33);
  static const Color tertiaryContainer = Color(0xFF0A3D47);

  // Text
  static const Color onSurface = Color(0xFFF4F4F5);
  static const Color onSurfaceVariant = Color(0xFFA1A1AA);
  static const Color onSurfaceMuted = Color(0xFF71717A);

  // Semantic
  static const Color success = Color(0xFF4ADE80);
  static const Color successContainer = Color(0xFF143525);
  static const Color onSuccess = Color(0xFF052E16);

  static const Color warning = Color(0xFFFBBF24);
  static const Color warningContainer = Color(0xFF3D2E0A);
  static const Color onWarning = Color(0xFF1C1403);

  static const Color error = Color(0xFFFF6B7A);
  static const Color errorContainer = Color(0xFF5C1520);
  static const Color onError = Color(0xFF2A050A);

  static const Color info = Color(0xFF8B93FF);
  static const Color infoContainer = Color(0xFF2A2F5C);
  static const Color onInfo = Color(0xFF0B0C1A);
}
