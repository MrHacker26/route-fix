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

/// Compact, lightweight status pill — typography-led, soft fill.
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
          border: Border.all(
            color: colors.foreground.withValues(alpha: 0.14),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showDot) ...[
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: colors.foreground.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.xxs),
            ],
            Text(
              label,
              style: AppTypography.textTheme.labelSmall?.copyWith(
                color: colors.foreground,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static _Colors _colorsFor(StatusBadgeTone tone) {
    return switch (tone) {
      StatusBadgeTone.success => _Colors(
          AppColors.success.withValues(alpha: 0.92),
          AppColors.success.withValues(alpha: 0.10),
        ),
      StatusBadgeTone.warning => _Colors(
          AppColors.warning.withValues(alpha: 0.92),
          AppColors.warning.withValues(alpha: 0.10),
        ),
      StatusBadgeTone.error => _Colors(
          AppColors.error.withValues(alpha: 0.92),
          AppColors.error.withValues(alpha: 0.10),
        ),
      StatusBadgeTone.info => _Colors(
          AppColors.info.withValues(alpha: 0.92),
          AppColors.info.withValues(alpha: 0.10),
        ),
      StatusBadgeTone.neutral => _Colors(
          AppColors.onSurfaceVariant.withValues(alpha: 0.95),
          AppColors.onSurface.withValues(alpha: 0.05),
        ),
    };
  }
}

class _Colors {
  const _Colors(this.foreground, this.container);

  final Color foreground;
  final Color container;
}
