import 'dart:ui';

import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_shadows.dart';
import '../tokens/app_spacing.dart';

/// Frosted glass surface — Arc / Raycast style panel with subtle hover lift.
class GlassCard extends StatefulWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.blurSigma = 24,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final double blurSigma;

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? AppRadius.lgAll;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _hovered ? -1.5 : 0, 0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: _hovered ? AppShadows.md : AppShadows.sm,
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: widget.blurSigma,
                sigmaY: widget.blurSigma,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.glassFill,
                  borderRadius: radius,
                  border: Border.all(
                    color: _hovered
                        ? AppColors.outline
                        : AppColors.glassBorder,
                  ),
                ),
                child: Padding(
                  padding:
                      widget.padding ?? const EdgeInsets.all(AppSpacing.cardPadding),
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
