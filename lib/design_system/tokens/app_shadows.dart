import 'package:flutter/material.dart';

/// Soft ambient elevation for dark desktop UI.
abstract final class AppShadows {
  static const List<BoxShadow> none = [];

  static const List<BoxShadow> sm = [
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 12,
      offset: Offset(0, 4),
      spreadRadius: -2,
    ),
  ];

  static const List<BoxShadow> md = [
    BoxShadow(
      color: Color(0x40000000),
      blurRadius: 28,
      offset: Offset(0, 10),
      spreadRadius: -4,
    ),
    BoxShadow(
      color: Color(0x28000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> lg = [
    BoxShadow(
      color: Color(0x4D000000),
      blurRadius: 40,
      offset: Offset(0, 16),
      spreadRadius: -6,
    ),
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  /// Quiet primary action ambient — never neon.
  static const List<BoxShadow> primaryGlow = [
    BoxShadow(
      color: Color(0x288B93FF),
      blurRadius: 18,
      offset: Offset(0, 6),
      spreadRadius: -2,
    ),
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 10,
      offset: Offset(0, 3),
    ),
  ];

  /// Stronger hover lift for primary.
  static const List<BoxShadow> primaryGlowHover = [
    BoxShadow(
      color: Color(0x3D8B93FF),
      blurRadius: 26,
      offset: Offset(0, 10),
      spreadRadius: -2,
    ),
    BoxShadow(
      color: Color(0x40000000),
      blurRadius: 14,
      offset: Offset(0, 5),
    ),
  ];
}
