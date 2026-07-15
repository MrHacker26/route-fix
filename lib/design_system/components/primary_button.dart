import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_shadows.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

/// Filled primary action button with light hover feedback.
class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.expanded = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final child = Row(
      mainAxisSize: widget.expanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, size: AppSpacing.iconInline),
          const SizedBox(width: AppSpacing.xs),
        ],
        Text(widget.label),
      ],
    );

    return MouseRegion(
      onEnter: enabled ? (_) => setState(() => _hovered = true) : null,
      onExit: enabled ? (_) => setState(() => _hovered = false) : null,
      child: AnimatedScale(
        scale: enabled && _hovered ? 1.015 : 1,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: AppRadius.mdAll,
            boxShadow: enabled
                ? (_hovered ? AppShadows.primaryGlow : AppShadows.sm)
                : AppShadows.none,
          ),
          child: FilledButton(
            onPressed: widget.onPressed,
            style: FilledButton.styleFrom(
              elevation: 0,
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              disabledBackgroundColor: AppColors.surfaceHighest,
              disabledForegroundColor: AppColors.onSurfaceMuted,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.buttonPaddingH,
                vertical: AppSpacing.buttonPaddingV,
              ),
              minimumSize: const Size(64, 36),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
              textStyle: AppTypography.textTheme.labelLarge,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
