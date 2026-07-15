import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_shadows.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

/// Filled primary action with premium hover lift and ambient shadow.
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(
          0,
          enabled && _hovered ? -1.5 : 0,
          0,
        ),
        decoration: BoxDecoration(
          borderRadius: AppRadius.mdAll,
          boxShadow: enabled
              ? (_hovered ? AppShadows.primaryGlowHover : AppShadows.primaryGlow)
              : AppShadows.none,
        ),
        child: FilledButton(
          onPressed: widget.onPressed,
          style: FilledButton.styleFrom(
            elevation: 0,
            backgroundColor: enabled && _hovered
                ? const Color(0xFF959CFF)
                : AppColors.primary,
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
    );
  }
}
