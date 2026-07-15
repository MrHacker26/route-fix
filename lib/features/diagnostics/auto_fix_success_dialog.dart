import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';

/// Result of the post-apply success dialog.
enum AutoFixSuccessDialogResult {
  done,
  runDiagnosticsAgain,
}

/// Shows the success dialog after a fix is applied.
Future<AutoFixSuccessDialogResult> showAutoFixSuccessDialog(
  BuildContext context,
) async {
  final result = await showDialog<AutoFixSuccessDialogResult>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.62),
    builder: (context) => const AutoFixSuccessDialog(),
  );
  return result ?? AutoFixSuccessDialogResult.done;
}

class AutoFixSuccessDialog extends StatelessWidget {
  const AutoFixSuccessDialog({super.key});

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
        constraints: const BoxConstraints(maxWidth: 420),
        child: GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                    size: AppSpacing.iconLead,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text('Done', style: text.titleLarge),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Your network settings were updated.',
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
                      label: 'Close',
                      expanded: true,
                      onPressed: () {
                        Navigator.of(context).pop(
                          AutoFixSuccessDialogResult.done,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Scan',
                      icon: Icons.refresh_rounded,
                      expanded: true,
                      onPressed: () {
                        Navigator.of(context).pop(
                          AutoFixSuccessDialogResult.runDiagnosticsAgain,
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
