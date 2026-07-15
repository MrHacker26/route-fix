import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';

/// Confirmation before applying Network Controls changes.
enum ApplyNetworkChangesResult {
  cancelled,
  confirmed,
}

Future<ApplyNetworkChangesResult> showApplyNetworkChangesDialog(
  BuildContext context,
) async {
  final result = await showDialog<ApplyNetworkChangesResult>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.62),
    builder: (context) => const ApplyNetworkChangesDialog(),
  );
  return result ?? ApplyNetworkChangesResult.cancelled;
}

class ApplyNetworkChangesDialog extends StatelessWidget {
  const ApplyNetworkChangesDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final text = AppTypography.textTheme;
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
              Text('Apply Network Changes?', style: text.titleLarge),
              const SizedBox(height: AppSpacing.md),
              Text(
                'RouteFix will modify your system network configuration.',
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
                'These changes can be reverted at any time.',
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
                          ApplyNetworkChangesResult.cancelled,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Apply',
                      icon: Icons.check_rounded,
                      expanded: true,
                      onPressed: () {
                        Navigator.of(context).pop(
                          ApplyNetworkChangesResult.confirmed,
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
