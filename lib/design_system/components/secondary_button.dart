import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

/// Outlined secondary action button.
class SecondaryButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18),
          const SizedBox(width: AppSpacing.xs),
        ],
        Text(label),
      ],
    );

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        elevation: 0,
        foregroundColor: AppColors.onSurface,
        disabledForegroundColor: AppColors.onSurfaceMuted,
        backgroundColor: AppColors.surfaceHigh.withValues(alpha: 0.4),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.buttonPaddingH,
          vertical: AppSpacing.buttonPaddingV,
        ),
        minimumSize: const Size(64, 44),
        side: BorderSide(
          color: onPressed != null
              ? AppColors.outline
              : AppColors.outlineSubtle,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        textStyle: AppTypography.textTheme.labelLarge,
      ),
      child: child,
    );
  }
}
