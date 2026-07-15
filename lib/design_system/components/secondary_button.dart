import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

/// Outlined secondary action button with light hover feedback.
class SecondaryButton extends StatefulWidget {
  const SecondaryButton({
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
  State<SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<SecondaryButton> {
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
        scale: enabled && _hovered ? 1.012 : 1,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        child: OutlinedButton(
          onPressed: widget.onPressed,
          style: OutlinedButton.styleFrom(
            elevation: 0,
            foregroundColor: AppColors.onSurface,
            disabledForegroundColor: AppColors.onSurfaceMuted,
            backgroundColor: _hovered && enabled
                ? AppColors.surfaceHighest.withValues(alpha: 0.55)
                : AppColors.surfaceHigh.withValues(alpha: 0.4),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.buttonPaddingH,
              vertical: AppSpacing.buttonPaddingV,
            ),
            minimumSize: const Size(64, 36),
            side: BorderSide(
              color: enabled
                  ? (_hovered ? AppColors.outline : AppColors.outlineSubtle)
                  : AppColors.outlineSubtle,
            ),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
            textStyle: AppTypography.textTheme.labelLarge,
          ),
          child: child,
        ),
      ),
    );
  }
}
