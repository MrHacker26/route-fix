import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_shadows.dart';
import '../tokens/app_spacing.dart';

/// Layered surface card — depth without glassmorphism or blur.
class GlassCard extends StatefulWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    @Deprecated('Glass blur removed — value is ignored.') this.blurSigma = 0,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  /// Retained for API compatibility; blur is intentionally unused.
  final double blurSigma;

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? AppRadius.mdAll;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _hovered ? -2 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: _hovered ? AppShadows.md : AppShadows.sm,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _hovered
                ? const [
                    Color(0xFF1D1D23),
                    Color(0xFF151518),
                  ]
                : const [
                    AppColors.cardGradientTop,
                    AppColors.cardGradientBottom,
                  ],
          ),
          border: Border.all(
            color: _hovered ? AppColors.outline : AppColors.borderSoft,
          ),
        ),
        child: Padding(
          padding:
              widget.padding ?? const EdgeInsets.all(AppSpacing.cardPadding),
          child: widget.child,
        ),
      ),
    );
  }
}
