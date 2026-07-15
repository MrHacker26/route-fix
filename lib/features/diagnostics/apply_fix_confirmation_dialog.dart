import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import 'diagnostics_result_view_data.dart';

/// Result of the Apply Fix confirmation dialog.
enum ApplyFixConfirmationResult {
  cancelled,
  confirmed,
}

/// Shows the Apply Fix confirmation dialog.
///
/// Returns [ApplyFixConfirmationResult.confirmed] when the user confirms.
/// The caller is responsible for applying the fix via the platform provider.
Future<ApplyFixConfirmationResult> showApplyFixConfirmation(
  BuildContext context, {
  required RecommendedFixView fix,
}) async {
  final result = await showDialog<ApplyFixConfirmationResult>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.62),
    builder: (context) => ApplyFixConfirmationDialog(fix: fix),
  );
  return result ?? ApplyFixConfirmationResult.cancelled;
}

/// Confirmation dialog for applying a recommended Auto Fix.
class ApplyFixConfirmationDialog extends StatelessWidget {
  const ApplyFixConfirmationDialog({
    super.key,
    required this.fix,
  });

  final RecommendedFixView fix;

  @override
  Widget build(BuildContext context) {
    final text = AppTypography.textTheme;
    final needsAdmin = fix.requiresElevation;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xxl,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: AppRadius.mdAll,
                      border: Border.all(color: AppColors.outlineSubtle),
                    ),
                    child: Icon(fix.icon, size: 22, color: AppColors.primary),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Apply Fix?', style: text.titleLarge),
                        const SizedBox(height: 2),
                        Text(
                          'Confirm before changing network settings.',
                          style: text.bodySmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLow.withValues(alpha: 0.7),
                  borderRadius: AppRadius.mdAll,
                  border: Border.all(color: AppColors.outlineSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(fix.title, style: text.titleSmall),
                        ),
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
              if (needsAdmin) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.warningContainer.withValues(alpha: 0.55),
                    borderRadius: AppRadius.smAll,
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.admin_panel_settings_outlined,
                        size: 18,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          'This change typically requires administrator privileges on your device.',
                          style: text.bodySmall?.copyWith(
                            color: AppColors.onSurface,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Text(
                        'Confirming will ask RouteFix to apply this change on your device.',
                style: text.bodySmall?.copyWith(
                  color: AppColors.onSurfaceMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: 'Cancel',
                      expanded: true,
                      onPressed: () {
                        Navigator.of(context).pop(
                          ApplyFixConfirmationResult.cancelled,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Confirm',
                      icon: Icons.check_rounded,
                      expanded: true,
                      onPressed: () {
                        Navigator.of(context).pop(
                          ApplyFixConfirmationResult.confirmed,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
