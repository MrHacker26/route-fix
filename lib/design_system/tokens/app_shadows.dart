import 'package:flutter/material.dart';

/// Soft elevation shadows for dark UI. Prefer hairline borders for depth.
abstract final class AppShadows {
  static const List<BoxShadow> none = [];

  static const List<BoxShadow> sm = [
    BoxShadow(
      color: Color(0x40000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> md = [
    BoxShadow(
      color: Color(0x59000000),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> lg = [
    BoxShadow(
      color: Color(0x73000000),
      blurRadius: 40,
      offset: Offset(0, 16),
    ),
    BoxShadow(
      color: Color(0x40000000),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  /// Soft indigo glow for primary actions.
  static const List<BoxShadow> primaryGlow = [
    BoxShadow(
      color: Color(0x338B93FF),
      blurRadius: 20,
      offset: Offset(0, 4),
    ),
  ];
}
