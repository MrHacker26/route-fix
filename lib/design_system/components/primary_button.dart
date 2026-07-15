import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_shadows.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

/// Filled primary action button.
class PrimaryButton extends StatelessWidget {
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

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadius.mdAll,
        boxShadow: onPressed != null ? AppShadows.primaryGlow : AppShadows.none,
      ),
      child: FilledButton(
        onPressed: onPressed,
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
          minimumSize: const Size(64, 44),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          textStyle: AppTypography.textTheme.labelLarge,
        ),
        child: child,
      ),
    );
  }
}
