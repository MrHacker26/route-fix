import 'package:flutter/material.dart';

/// RouteFix color tokens — Material 3 dark, Linear / Raycast / Arc inspired.
abstract final class AppColors {
  // Surfaces
  static const Color background = Color(0xFF0B0B0D);
  static const Color surface = Color(0xFF111113);
  static const Color surfaceLow = Color(0xFF141416);
  static const Color surfaceContainer = Color(0xFF17171A);
  static const Color surfaceHigh = Color(0xFF1C1C20);
  static const Color surfaceHighest = Color(0xFF232328);

  /// Soft layered card fills (use with [LinearGradient], not flat opaque).
  static const Color cardGradientTop = Color(0xFF1A1A1F);
  static const Color cardGradientBottom = Color(0xFF131316);

  // Borders — hairline, low contrast
  static const Color outline = Color(0xFF2A2A32);
  static const Color outlineSubtle = Color(0xFF1F1F26);
  static const Color borderSoft = Color(0x14FFFFFF);

  // Deprecated aliases kept for compatibility (no glass UI).
  static const Color glassFill = Color(0xFF16161A);
  static const Color glassBorder = borderSoft;

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
  static const Color onSurfaceMuted = Color(0xFF8B8B96);

  /// Soft atmosphere accent used in page background gradients.
  static const Color atmosphere = Color(0xFF101018);

  /// Almost invisible radial glow (keep alpha very low).
  static const Color ambience = Color(0xFF8B93FF);

  // Semantic
  static const Color success = Color(0xFF4ADE80);
  static const Color successContainer = Color(0xFF10281C);
  static const Color onSuccess = Color(0xFF052E16);

  static const Color warning = Color(0xFFFBBF24);
  static const Color warningContainer = Color(0xFF2A220C);
  static const Color onWarning = Color(0xFF1C1403);

  static const Color error = Color(0xFFFF6B7A);
  static const Color errorContainer = Color(0xFF3A1218);
  static const Color onError = Color(0xFF2A050A);

  static const Color info = Color(0xFF8B93FF);
  static const Color infoContainer = Color(0xFF1C2038);
  static const Color onInfo = Color(0xFF0B0C1A);
}
