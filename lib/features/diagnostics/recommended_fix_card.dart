import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import 'diagnostics_result_view_data.dart';

/// Display-only Auto Fix suggestion card (no apply action).
class RecommendedFixCard extends StatelessWidget {
  const RecommendedFixCard({
    super.key,
    required this.fix,
  });

  final RecommendedFixView fix;

  @override
  Widget build(BuildContext context) {
    final text = AppTypography.textTheme;

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: AppRadius.mdAll,
              border: Border.all(color: AppColors.outlineSubtle),
            ),
            child: Icon(fix.icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(fix.title, style: text.titleSmall),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    StatusBadge(
                      label: fix.availabilityLabel,
                      tone: fix.availabilityTone,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  fix.description,
                  style: text.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
