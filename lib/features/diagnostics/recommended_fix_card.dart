import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../../di/app_services.dart';
import '../../domain/autofix/auto_fix_service.dart';
import '../../domain/autofix/fix_provider.dart';
import '../../domain/autofix/models/fix_result.dart';
import '../../domain/autofix/models/fix_type.dart';
import '../../domain/autofix/platform_fix_executor.dart';
import 'apply_fix_confirmation_dialog.dart';
import 'auto_fix_success_dialog.dart';
import 'diagnostics_result_view_data.dart';
import 'human_message.dart';

enum _ApplyPhase { idle, loading, success, failure }

/// Trustworthy Auto Fix recommendation card.
class RecommendedFixCard extends StatefulWidget {
  const RecommendedFixCard({
    super.key,
    required this.fix,
    required this.fixProvider,
    this.autoFix,
    this.onRerunDiagnostics,
    this.onApplied,
    this.compact = false,
  });

  final RecommendedFixView fix;
  final FixProvider fixProvider;
  final AutoFixService? autoFix;
  final VoidCallback? onRerunDiagnostics;
  final VoidCallback? onApplied;
  final bool compact;

  @override
  State<RecommendedFixCard> createState() => _RecommendedFixCardState();
}

class _RecommendedFixCardState extends State<RecommendedFixCard> {
  _ApplyPhase _phase = _ApplyPhase.idle;
  String? _failureMessage;
  String? _failureTechnical;
  String _progressLabel = AutoFixPhase.applying.label;

  AutoFixService get _autoFix => widget.autoFix ?? AppServices.autoFix;

  Future<void> _handleApply() async {
    if (_phase == _ApplyPhase.loading || _autoFix.isBusy) return;

    final confirmed = await showApplyFixConfirmation(context, fix: widget.fix);
    if (confirmed != ApplyFixConfirmationResult.confirmed) return;
    if (!mounted) return;

    setState(() {
      _phase = _ApplyPhase.loading;
      _failureMessage = null;
      _failureTechnical = null;
      _progressLabel = AutoFixPhase.applying.label;
    });

    late final FixResult result;
    try {
      result = await _autoFix.apply(
        widget.fix.kind.toFixType,
        onPhase: (phase) {
          if (!mounted) return;
          setState(() => _progressLabel = phase.label);
        },
      );
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _phase = _ApplyPhase.failure;
        _failureTechnical = error.toString();
        _failureMessage = HumanMessage.fromProbeError(
          error.toString(),
          fallback: 'We couldn’t apply that change just now.',
        );
      });
      return;
    }

    if (!mounted) return;

    if (result.wasCancelled) {
      setState(() {
        _phase = _ApplyPhase.idle;
        _failureMessage = null;
        _failureTechnical = null;
      });
      return;
    }

    if (result.success) {
      setState(() {
        _phase = _ApplyPhase.success;
        _failureMessage = null;
        _failureTechnical = null;
      });
      await showAutoFixSuccessDialog(context);
      if (!mounted) return;
      widget.onApplied?.call();
      // Automatically re-run diagnostics and refresh the dashboard / results.
      widget.onRerunDiagnostics?.call();
      return;
    }

    setState(() {
      _phase = _ApplyPhase.failure;
      _failureTechnical = [
        if (result.error != null) result.error!,
        if (result.metadata['stderr'] != null) result.metadata['stderr']!,
        if (result.executedCommand != null) result.executedCommand!,
      ].where((part) => part.trim().isNotEmpty).join('\n');
      _failureMessage = HumanMessage.fromProbeError(
        result.message ?? result.error,
        fallback: 'That change didn’t go through. You can try again.',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return switch (_phase) {
      _ApplyPhase.success => _SuccessBody(
          onRerunDiagnostics: widget.onRerunDiagnostics,
        ),
      _ => _RecommendationBody(
          fix: widget.fix,
          loading: _phase == _ApplyPhase.loading,
          progressLabel: _progressLabel,
          failureMessage: _failureMessage,
          failureTechnical: _failureTechnical,
          compact: widget.compact,
          onApply: _handleApply,
        ),
    };
  }
}

class _RecommendationBody extends StatelessWidget {
  const _RecommendationBody({
    required this.fix,
    required this.loading,
    required this.progressLabel,
    required this.onApply,
    required this.compact,
    this.failureMessage,
    this.failureTechnical,
  });

  final RecommendedFixView fix;
  final bool loading;
  final String progressLabel;
  final bool compact;
  final String? failureMessage;
  final String? failureTechnical;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final text = AppTypography.textTheme;

    return GlassCard(
      padding: EdgeInsets.all(compact ? AppSpacing.sm : AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            compact ? 'Possible action' : 'Recommended Fix',
            style: text.labelMedium?.copyWith(
              color: AppColors.onSurfaceMuted,
              letterSpacing: 0.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  fix.title,
                  style: (compact ? text.titleMedium : text.titleLarge)
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              StatusBadge(
                label: fix.availabilityLabel,
                tone: fix.availabilityTone,
                showDot: false,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            fix.description,
            style: text.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          if (!compact) ...[
            const SizedBox(height: AppSpacing.sm),
            _LabeledBlock(label: 'What we saw', value: fix.why),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Confidence · ${fix.confidenceLabel}',
              style: text.labelSmall?.copyWith(
                color: AppColors.onSurfaceMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (loading) ...[
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                const SizedBox(
                  width: AppSpacing.iconRow,
                  height: AppSpacing.iconRow,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    progressLabel,
                    style: text.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (failureMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              failureMessage!,
              style: text.bodySmall?.copyWith(
                color: AppColors.error,
                height: 1.4,
              ),
            ),
            if (failureTechnical != null &&
                failureTechnical!.isNotEmpty &&
                failureTechnical != failureMessage)
              Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: Material(
                  color: Colors.transparent,
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text(
                      'View technical details',
                      style:
                          text.labelMedium?.copyWith(color: AppColors.primary),
                    ),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SelectableText(
                          failureTechnical!,
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
          const Divider(height: 1, color: AppColors.outlineSubtle),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              label: loading
                  ? progressLabel
                  : (compact ? 'Apply Fix' : 'Apply Fix'),
              icon: loading ? null : Icons.auto_fix_high_outlined,
              expanded: true,
              onPressed: (!fix.canConfirmApply || loading) ? null : onApply,
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessBody extends StatelessWidget {
  const _SuccessBody({this.onRerunDiagnostics});

  final VoidCallback? onRerunDiagnostics;

  @override
  Widget build(BuildContext context) {
    final text = AppTypography.textTheme;

    return GlassCard(
      child: Column(
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
              Text(
                'Network Updated',
                style: text.titleMedium?.copyWith(color: AppColors.success),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'The recommended fix was successfully applied.',
            style: text.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              label: 'Run Again',
              icon: Icons.refresh_rounded,
              expanded: true,
              onPressed: onRerunDiagnostics,
            ),
          ),
        ],
      ),
    );
  }
}

class _LabeledBlock extends StatelessWidget {
  const _LabeledBlock({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = AppTypography.textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: text.labelMedium?.copyWith(
            color: AppColors.onSurfaceMuted,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          value,
          style: text.bodyMedium?.copyWith(
            color: AppColors.onSurface,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
