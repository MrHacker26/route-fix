import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

enum StatusBadgeTone {
  success,
  warning,
  error,
  info,
  neutral,
}

/// Compact status pill for diagnostic states.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    this.tone = StatusBadgeTone.neutral,
    this.showDot = true,
  });

  final String label;
  final StatusBadgeTone tone;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    final colors = _colorsFor(tone);

    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.badgePaddingH,
          vertical: AppSpacing.badgePaddingV,
        ),
        decoration: BoxDecoration(
          color: colors.container,
          borderRadius: AppRadius.pill,
          border: Border.all(color: colors.foreground.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showDot) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: colors.foreground,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.xxs),
            ],
            Text(
              label,
              style: AppTypography.textTheme.labelMedium?.copyWith(
                color: colors.foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static _Colors _colorsFor(StatusBadgeTone tone) {
    return switch (tone) {
      StatusBadgeTone.success => const _Colors(
          AppColors.success,
          AppColors.successContainer,
        ),
      StatusBadgeTone.warning => const _Colors(
          AppColors.warning,
          AppColors.warningContainer,
        ),
      StatusBadgeTone.error => const _Colors(
          AppColors.error,
          AppColors.errorContainer,
        ),
      StatusBadgeTone.info => const _Colors(
          AppColors.info,
          AppColors.infoContainer,
        ),
      StatusBadgeTone.neutral => const _Colors(
          AppColors.onSurfaceVariant,
          AppColors.surfaceHigh,
        ),
    };
  }
}

class _Colors {
  const _Colors(this.foreground, this.container);

  final Color foreground;
  final Color container;
}
