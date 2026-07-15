import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../../di/app_services.dart';
import '../../domain/autofix/auto_fix_service.dart';
import '../../domain/autofix/models/fix_result.dart';
import '../../domain/autofix/models/fix_type.dart';
import '../../domain/autofix/platform_fix_executor.dart';
import 'human_message.dart';

/// Offers Restore when RouteFix has applied a temporary network change.
class RestoreDefaultCard extends StatefulWidget {
  const RestoreDefaultCard({
    super.key,
    this.autoFix,
    this.onRestored,
    this.compact = false,
  });

  final AutoFixService? autoFix;
  final VoidCallback? onRestored;
  final bool compact;

  @override
  State<RestoreDefaultCard> createState() => _RestoreDefaultCardState();
}

class _RestoreDefaultCardState extends State<RestoreDefaultCard> {
  var _loading = false;
  String? _failureMessage;
  String? _failureTechnical;
  String _progressLabel = AutoFixPhase.restoring.label;

  AutoFixService get _autoFix => widget.autoFix ?? AppServices.autoFix;

  Future<void> _handleRestore() async {
    if (_loading || _autoFix.isBusy) return;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.62),
      builder: (context) => const _RestoreConfirmationDialog(),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _loading = true;
      _failureMessage = null;
      _failureTechnical = null;
      _progressLabel = AutoFixPhase.restoring.label;
    });

    late final FixResult result;
    try {
      result = await _autoFix.restoreDefault(
        onPhase: (phase) {
          if (!mounted) return;
          setState(() => _progressLabel = phase.label);
        },
      );
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failureTechnical = error.toString();
        _failureMessage = HumanMessage.fromProbeError(
          error.toString(),
          fallback: 'Couldn’t restore defaults.',
        );
      });
      return;
    }

    if (!mounted) return;

    if (result.wasCancelled) {
      setState(() {
        _loading = false;
        _failureMessage = null;
        _failureTechnical = null;
      });
      return;
    }

    if (result.success) {
      setState(() {
        _loading = false;
        _failureMessage = null;
        _failureTechnical = null;
      });
      widget.onRestored?.call();
      return;
    }

    setState(() {
      _loading = false;
      _failureTechnical = [
        if (result.error != null) result.error!,
        if (result.metadata['stderr'] != null) result.metadata['stderr']!,
      ].where((part) => part.trim().isNotEmpty).join('\n');
      _failureMessage = HumanMessage.fromProbeError(
        result.message ?? result.error,
        fallback: 'Restore didn’t finish. Try again.',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = AppTypography.textTheme;
    final title = FixType.restoreDefault.displayTitle;

    return GlassCard(
      padding: EdgeInsets.all(
        widget.compact ? AppSpacing.md : AppSpacing.cardPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Restore',
            style: text.labelMedium?.copyWith(
              color: AppColors.onSurfaceMuted,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(title, style: text.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Undo temporary changes and return to normal settings.',
            style: text.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          if (_loading) ...[
            const SizedBox(height: AppSpacing.md),
            InlineProgress(label: _progressLabel),
          ],
          if (_failureMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              _failureMessage!,
              style: text.bodySmall?.copyWith(
                color: AppColors.error,
                height: 1.4,
              ),
            ),
            if (_failureTechnical != null &&
                _failureTechnical!.isNotEmpty &&
                _failureTechnical != _failureMessage)
              Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: Material(
                  color: Colors.transparent,
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text(
                      'Technical details',
                      style:
                          text.labelMedium?.copyWith(color: AppColors.primary),
                    ),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SelectableText(
                          _failureTechnical!,
                          style: text.bodySmall?.copyWith(
                            fontFamily: 'Menlo',
                            fontFamilyFallback: const ['Consolas', 'monospace'],
                            color: AppColors.onSurfaceMuted,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: SecondaryButton(
              label: _loading ? _progressLabel : 'Restore',
              icon: _loading ? null : Icons.undo_rounded,
              expanded: true,
              onPressed: _loading ? null : _handleRestore,
            ),
          ),
        ],
      ),
    );
  }
}

class _RestoreConfirmationDialog extends StatelessWidget {
  const _RestoreConfirmationDialog();

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
              Text('Restore defaults?', style: text.titleLarge),
              const SizedBox(height: AppSpacing.md),
              Text(
                'This undoes temporary network changes.',
                style: text.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'You may be asked for your password.',
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
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Restore',
                      icon: Icons.undo_rounded,
                      expanded: true,
                      onPressed: () => Navigator.of(context).pop(true),
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
