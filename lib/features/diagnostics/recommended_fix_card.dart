import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../../domain/autofix/fix_provider.dart';
import '../../domain/autofix/models/fix_result.dart';
import 'apply_fix_confirmation_dialog.dart';
import 'diagnostics_result_view_data.dart';

enum _ApplyPhase { idle, loading, success, failure }

/// Trustworthy Auto Fix recommendation card.
class RecommendedFixCard extends StatefulWidget {
  const RecommendedFixCard({
    super.key,
    required this.fix,
    required this.fixProvider,
    this.onRerunDiagnostics,
  });

  final RecommendedFixView fix;
  final FixProvider fixProvider;
  final VoidCallback? onRerunDiagnostics;

  @override
  State<RecommendedFixCard> createState() => _RecommendedFixCardState();
}

class _RecommendedFixCardState extends State<RecommendedFixCard> {
  _ApplyPhase _phase = _ApplyPhase.idle;
  String? _failureMessage;

  Future<void> _handleApply() async {
    if (_phase == _ApplyPhase.loading) return;

    final confirmed = await showApplyFixConfirmation(context, fix: widget.fix);
    if (confirmed != ApplyFixConfirmationResult.confirmed) return;
    if (!mounted) return;

    setState(() {
      _phase = _ApplyPhase.loading;
      _failureMessage = null;
    });

    late final FixResult result;
    try {
      result = await widget.fixProvider.apply(widget.fix.kind);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _phase = _ApplyPhase.failure;
        _failureMessage = error.toString();
      });
      return;
    }

    if (!mounted) return;

    setState(() {
      if (result.success) {
        _phase = _ApplyPhase.success;
        _failureMessage = null;
      } else {
        _phase = _ApplyPhase.failure;
        _failureMessage =
            result.error ?? result.message ?? 'Fix failed to apply.';
      }
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
          failureMessage: _failureMessage,
          onApply: _handleApply,
        ),
    };
  }
}

class _RecommendationBody extends StatelessWidget {
  const _RecommendationBody({
    required this.fix,
    required this.loading,
    required this.onApply,
    this.failureMessage,
  });

  final RecommendedFixView fix;
  final bool loading;
  final String? failureMessage;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final text = AppTypography.textTheme;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recommended Action',
            style: text.labelMedium?.copyWith(
              color: AppColors.onSurfaceMuted,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(fix.title, style: text.titleLarge),
          const SizedBox(height: AppSpacing.lg),
          _LabeledBlock(
            label: 'Why?',
            value: fix.why,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _LabeledBlock(
                  label: 'Confidence',
                  value: fix.confidenceLabel,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _LabeledBlock(
                  label: 'Estimated Improvement',
                  value: fix.estimatedImprovement,
                ),
              ),
            ],
          ),
          if (failureMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              failureMessage!,
              style: text.bodySmall?.copyWith(
                color: AppColors.error,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          const Divider(height: 1, color: AppColors.outlineSubtle),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              label: loading ? 'Applying…' : 'Apply Recommended Fix',
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
                size: 22,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Fix Applied',
                style: text.titleMedium?.copyWith(color: AppColors.success),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Please run diagnostics again\nto verify the improvement.',
            style: text.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              label: 'Re-run Diagnostics',
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
        const SizedBox(height: 4),
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
