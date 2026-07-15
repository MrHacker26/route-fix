import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import 'apply_fix_confirmation_dialog.dart';
import 'diagnostics_result_view_data.dart';

/// Auto Fix suggestion card with confirmation-only Apply Fix flow.
class RecommendedFixCard extends StatelessWidget {
  const RecommendedFixCard({
    super.key,
    required this.fix,
    this.onConfirmed,
  });

  final RecommendedFixView fix;

  /// Called after the user confirms in the dialog.
  ///
  /// Confirmation does not execute a fix. Callers must not apply Auto Fix here
  /// until execution is explicitly implemented.
  final ValueChanged<RecommendedFixView>? onConfirmed;

  Future<void> _handleApply(BuildContext context) async {
    final result = await showApplyFixConfirmation(context, fix: fix);
    if (result != ApplyFixConfirmationResult.confirmed) return;
    onConfirmed?.call(fix);
  }

  @override
  Widget build(BuildContext context) {
    final text = AppTypography.textTheme;

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: SecondaryButton(
              label: 'Apply Fix',
              icon: Icons.auto_fix_high_outlined,
              onPressed: fix.canConfirmApply ? () => _handleApply(context) : null,
            ),
          ),
        ],
      ),
    );
  }
}
