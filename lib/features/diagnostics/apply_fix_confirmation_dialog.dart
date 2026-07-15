import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import 'diagnostics_result_view_data.dart';

/// Result of the Apply Fix confirmation dialog.
enum ApplyFixConfirmationResult {
  cancelled,
  confirmed,
}

/// Shows the Apply Fix confirmation dialog.
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
    final isPreferIpv4 = fix.title == 'Prefer IPv4' ||
        fix.id == 'disableIpv6' ||
        fix.kind.name == 'disableIpv6';
    final title = isPreferIpv4 ? 'Prefer IPv4?' : '${fix.title}?';

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
              Text(title, style: text.titleLarge),
              const SizedBox(height: AppSpacing.md),
              Text(
                'RouteFix will temporarily modify your network configuration.',
                style: text.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Administrator permission may be required.',
                style: text.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'This can be restored at any time.',
                style: text.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  height: 1.45,
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
                      label: 'Apply Fix',
                      icon: Icons.auto_fix_high_outlined,
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
