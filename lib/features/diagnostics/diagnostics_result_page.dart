import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../application/diagnostics/diagnostics_coordinator.dart';
import '../../design_system/design_system.dart';
import '../../di/app_services.dart';
import '../../domain/autofix/auto_fix_service.dart';
import '../../domain/autofix/fix_provider.dart';
import '../../domain/models/diagnostics/diagnostic_report.dart';
import 'diagnostics_result_view_data.dart';
import 'human_message.dart';
import 'recommended_fix_card.dart';
import 'restore_default_card.dart';

/// Diagnostics result report powered by a real [DiagnosticReport].
class DiagnosticsResultPage extends StatefulWidget {
  const DiagnosticsResultPage({
    super.key,
    this.report,
    this.coordinator,
    this.onClose,
  });

  final DiagnosticReport? report;
  final DiagnosticsCoordinator? coordinator;
  final VoidCallback? onClose;

  @override
  State<DiagnosticsResultPage> createState() => _DiagnosticsResultPageState();
}

class _DiagnosticsResultPageState extends State<DiagnosticsResultPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;

  DiagnosticsResultViewData? _data;
  var _loading = true;
  String? _error;
  String? _errorTechnical;
  var _partial = false;

  DiagnosticsCoordinator get _coordinator =>
      widget.coordinator ?? AppServices.diagnostics;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 880),
    )..forward();

    final seeded = widget.report;
    if (seeded != null) {
      _applyReport(seeded);
    } else {
      _load();
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  void _applyReport(DiagnosticReport report) {
    final data = DiagnosticsResultViewData.fromReport(
      report,
      fixProvider: AppServices.fixProvider,
    );
    setState(() {
      _data = data;
      _loading = false;
      _error = null;
      _errorTechnical = null;
      _partial = report.metadata['ipv4_success'] == 'false' ||
          report.metadata['cloudflare_success'] == 'false';
    });
    _entrance
      ..reset()
      ..forward();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _errorTechnical = null;
    });

    try {
      final report = await _coordinator.run();
      if (!mounted) return;
      _applyReport(report);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorTechnical = error.toString();
        _error = HumanMessage.fromProbeError(
          error.toString(),
          fallback:
              'We couldn’t finish this check. Give it another try in a moment.',
        );
      });
      _entrance
        ..reset()
        ..forward();
    }
  }

  void _handleClose() {
    if (widget.onClose != null) {
      widget.onClose!();
      return;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  List<Widget> _staggered(List<Widget> children) {
    final widgets = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) widgets.add(const SizedBox(height: AppSpacing.sectionGap));
      final start = (0.04 + i * 0.07).clamp(0.0, 0.7);
      final end = (start + 0.28).clamp(0.0, 1.0);
      widgets.add(
        _FadeIn(
          animation: _entrance,
          interval: Interval(start, end, curve: Curves.easeOutCubic),
          child: children[i],
        ),
      );
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final text = AppTypography.textTheme;
    final data = _data;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: PageAtmosphere(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSpacing.desktopMaxWidth,
              ),
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.md,
                      AppSpacing.xl,
                      AppSpacing.xxl,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _FadeIn(
                          animation: _entrance,
                          interval: const Interval(0.0, 0.28),
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: _handleClose,
                                tooltip: 'Back',
                                style: IconButton.styleFrom(
                                  foregroundColor: AppColors.onSurfaceVariant,
                                  backgroundColor: AppColors.surfaceHigh
                                      .withValues(alpha: 0.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: AppRadius.smAll,
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.arrow_back_rounded,
                                  size: AppSpacing.iconRow,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Results',
                                      style: text.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      _loading
                                          ? 'Listening to your network…'
                                          : _error != null
                                              ? 'Couldn’t complete this check'
                                              : '${data?.timestampLabel ?? ''} · RouteFix',
                                      style: text.labelSmall?.copyWith(
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              StatusBadge(
                                label: _loading
                                    ? 'Investigating'
                                    : _error != null
                                        ? 'Needs Attention'
                                        : _partial
                                            ? 'Needs Attention'
                                            : 'Healthy',
                                tone: _loading
                                    ? StatusBadgeTone.info
                                    : _error != null
                                        ? StatusBadgeTone.error
                                        : _partial
                                            ? StatusBadgeTone.warning
                                            : StatusBadgeTone.success,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              SecondaryButton(
                                label: 'Done',
                                icon: Icons.check_rounded,
                                onPressed: _loading ? null : _handleClose,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (_loading) ...[
                          const _LoadingCard(
                            label: 'Checking how healthy your routes feel…',
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          const _LoadingCard(
                            label: 'Comparing everyday developer paths…',
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          const _LoadingCard(
                            label: 'Preparing a calm recommendation…',
                          ),
                        ] else if (_error != null) ...[
                          _ErrorCard(
                            message: _error!,
                            technical: _errorTechnical,
                            onRetry: _load,
                          ),
                        ] else if (data != null) ...[
                          ..._staggered([
                            _HealthSection(data: data),
                            if (data.networkMetrics.isNotEmpty)
                              _NetworkSnapshotSection(
                                metrics: data.networkMetrics,
                              ),
                            _ProblemSection(problems: data.problems),
                            _ImpactSection(impacts: data.serviceImpacts),
                            _RecommendationSection(
                              primary: data.primaryFix,
                              secondary: data.secondaryFixes,
                              fixProvider: AppServices.fixProvider,
                              autoFix: AppServices.autoFix,
                              onRerunDiagnostics: _loading ? null : _load,
                              onApplied: () {
                                if (mounted) setState(() {});
                              },
                            ),
                            _TechnicalDetailsSection(
                              details: data.technicalDetails,
                            ),
                          ]),
                        ],
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FadeIn extends StatelessWidget {
  const _FadeIn({
    required this.animation,
    required this.interval,
    required this.child,
  });

  final Animation<double> animation;
  final Interval interval;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: animation, curve: interval);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.028),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: curved, curve: Curves.easeOutCubic)),
        child: child,
      ),
    );
  }
}

class _SectionEyebrow extends StatelessWidget {
  const _SectionEyebrow(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTypography.textTheme.labelMedium?.copyWith(
        color: AppColors.onSurfaceMuted,
        letterSpacing: 0.2,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Row(
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
              label,
              style: AppTypography.textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.message,
    required this.onRetry,
    this.technical,
  });

  final String message;
  final String? technical;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final text = AppTypography.textTheme;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Something got in the way', style: text.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            style: text.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          if (technical != null && technical!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _TechnicalExpander(details: [
              TechnicalDetailView(label: 'raw_error', value: technical!),
            ]),
          ],
          const SizedBox(height: AppSpacing.lg),
          SecondaryButton(
            label: 'Try again',
            icon: Icons.refresh_rounded,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

class _HealthSection extends StatelessWidget {
  const _HealthSection({required this.data});

  final DiagnosticsResultViewData data;

  @override
  Widget build(BuildContext context) {
    final text = AppTypography.textTheme;
    final score = data.overallScore;
    final barColor = switch (data.scoreTone) {
      StatusBadgeTone.success => AppColors.success,
      StatusBadgeTone.warning => AppColors.warning,
      StatusBadgeTone.error => AppColors.error,
      _ => AppColors.primary,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionEyebrow('Health Summary'),
        const SizedBox(height: AppSpacing.xs),
        GlassCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    label: 'Health score $score of 100',
                    child: SizedBox(
                      width: 72,
                      height: 72,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: score / 100),
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) {
                          return CustomPaint(
                            painter: _ScoreRingPainter(progress: value),
                            child: Center(
                              child: Text(
                                '$score',
                                style: text.titleLarge?.copyWith(
                                  letterSpacing: -1,
                                  fontWeight: FontWeight.w600,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ResultMetaRow(
                          label: 'Health Score',
                          value: '$score',
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        _ResultMetaRow(
                          label: 'Overall Status',
                          value: data.scoreLabel,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        _ResultMetaRow(
                          label: 'Confidence',
                          value: HumanMessage.confidenceBadge(data.confidence),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        _ResultMetaRow(
                          label: 'Last Scan',
                          value: data.timestampLabel,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          data.scoreSummary,
                          style: text.bodySmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ClipRRect(
                          borderRadius: AppRadius.pill,
                          child: LinearProgressIndicator(
                            value: score / 100,
                            minHeight: AppSpacing.healthBar,
                            backgroundColor: AppColors.surfaceHighest,
                            color: barColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResultMetaRow extends StatelessWidget {
  const _ResultMetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = AppTypography.textTheme;
    return Row(
      children: [
        SizedBox(
          width: 108,
          child: Text(
            label,
            style: text.labelSmall?.copyWith(
              color: AppColors.onSurfaceMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: text.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}

class _NetworkSnapshotSection extends StatelessWidget {
  const _NetworkSnapshotSection({required this.metrics});

  final List<NetworkMetricView> metrics;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionEyebrow('Network Snapshot'),
        const SizedBox(height: AppSpacing.xs),
        GlassCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              for (var i = 0; i < metrics.length; i++) ...[
                if (i > 0)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.xxs),
                    child: Divider(height: 1, color: AppColors.outlineSubtle),
                  ),
                _MetricRow(metric: metrics[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricRow extends StatefulWidget {
  const _MetricRow({required this.metric});

  final NetworkMetricView metric;

  @override
  State<_MetricRow> createState() => _MetricRowState();
}

class _MetricRowState extends State<_MetricRow> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    final text = AppTypography.textTheme;
    final metric = widget.metric;
    final accent = switch (metric.tone) {
      StatusBadgeTone.success => AppColors.success,
      StatusBadgeTone.warning => AppColors.warning,
      StatusBadgeTone.error => AppColors.error,
      StatusBadgeTone.info => AppColors.primary,
      StatusBadgeTone.neutral => AppColors.onSurfaceVariant,
    };

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm,
          horizontal: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: _hovered
              ? AppColors.surfaceHigh.withValues(alpha: 0.35)
              : Colors.transparent,
          borderRadius: AppRadius.xsAll,
        ),
        child: Row(
          children: [
            Icon(metric.icon, size: AppSpacing.iconInline, color: accent),
            const SizedBox(width: AppSpacing.md),
            SizedBox(
              width: 56,
              child: Text(
                metric.title,
                style: text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.15,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                metric.value,
                overflow: TextOverflow.ellipsis,
                style: text.bodySmall?.copyWith(
                  fontFamily: 'Menlo',
                  fontFamilyFallback: const ['Consolas', 'monospace'],
                  fontFeatures: const [FontFeature.tabularFigures()],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Flexible(
              child: Text(
                metric.detail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: text.labelSmall?.copyWith(
                  color: AppColors.onSurfaceMuted,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProblemSection extends StatelessWidget {
  const _ProblemSection({required this.problems});

  final List<ProblemView> problems;

  @override
  Widget build(BuildContext context) {
    final text = AppTypography.textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionEyebrow('Problem'),
        const SizedBox(height: AppSpacing.sm),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    problems.isEmpty
                        ? 'Everything looks healthy'
                        : 'What we noticed',
                    style: text.titleMedium,
                  ),
                  const Spacer(),
                  StatusBadge(
                    label: problems.isEmpty ? 'Healthy' : '${problems.length}',
                    tone: problems.isEmpty
                        ? StatusBadgeTone.success
                        : StatusBadgeTone.warning,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (problems.isEmpty)
                Column(
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 36,
                      color: AppColors.success.withValues(alpha: 0.9),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'We couldn’t find any routing issues during this scan.',
                      textAlign: TextAlign.center,
                      style: text.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ],
                )
              else
                for (var i = 0; i < problems.length; i++) ...[
                  if (i > 0) ...[
                    const SizedBox(height: AppSpacing.sm),
                    const Divider(height: 1, color: AppColors.outlineSubtle),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  _ProblemRow(problem: problems[i]),
                ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ProblemRow extends StatelessWidget {
  const _ProblemRow({required this.problem});

  final ProblemView problem;

  @override
  Widget build(BuildContext context) {
    final text = AppTypography.textTheme;
    final accent = switch (problem.tone) {
      StatusBadgeTone.success => AppColors.success,
      StatusBadgeTone.warning => AppColors.warning,
      StatusBadgeTone.error => AppColors.error,
      StatusBadgeTone.info => AppColors.primary,
      StatusBadgeTone.neutral => AppColors.onSurfaceVariant,
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(problem.icon, size: AppSpacing.iconRow, color: accent),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(problem.title, style: text.titleSmall),
                  ),
                  StatusBadge(
                    label: problem.severity,
                    tone: problem.tone,
                    showDot: false,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                problem.detail,
                style: text.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ImpactSection extends StatelessWidget {
  const _ImpactSection({required this.impacts});

  final List<ServiceImpactView> impacts;

  @override
  Widget build(BuildContext context) {
    final text = AppTypography.textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionEyebrow('Impact'),
        const SizedBox(height: AppSpacing.sm),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Where you might feel it', style: text.titleMedium),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                'A calm estimate for common developer workflows.',
                style: text.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              for (var i = 0; i < impacts.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.sm),
                _ImpactRow(impact: impacts[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ImpactRow extends StatelessWidget {
  const _ImpactRow({required this.impact});

  final ServiceImpactView impact;

  @override
  Widget build(BuildContext context) {
    final text = AppTypography.textTheme;
    final tone = switch (impact.level.toLowerCase()) {
      'high' => StatusBadgeTone.error,
      'medium' => StatusBadgeTone.warning,
      'low' => StatusBadgeTone.info,
      _ => StatusBadgeTone.success,
    };

    return Row(
      children: [
        Icon(
          impact.icon,
          size: AppSpacing.iconInline,
          color: AppColors.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(impact.name, style: text.titleSmall)),
        StatusBadge(label: impact.label, tone: tone, showDot: false),
      ],
    );
  }
}

class _RecommendationSection extends StatelessWidget {
  const _RecommendationSection({
    required this.primary,
    required this.secondary,
    required this.fixProvider,
    required this.autoFix,
    this.onRerunDiagnostics,
    this.onApplied,
  });

  final RecommendedFixView? primary;
  final List<RecommendedFixView> secondary;
  final FixProvider fixProvider;
  final AutoFixService autoFix;
  final VoidCallback? onRerunDiagnostics;
  final VoidCallback? onApplied;

  @override
  Widget build(BuildContext context) {
    final text = AppTypography.textTheme;
    final showRestore = autoFix.appliedFixes.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionEyebrow('Recommendation'),
        const SizedBox(height: AppSpacing.sm),
        if (primary == null)
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('No recommendation available.', style: text.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'No action required. We’ll only recommend a fix when we have strong evidence.',
                  style: text.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          )
        else ...[
          RecommendedFixCard(
            fix: primary!,
            fixProvider: fixProvider,
            autoFix: autoFix,
            onRerunDiagnostics: onRerunDiagnostics,
            onApplied: onApplied,
          ),
          if (secondary.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text('Other possible actions', style: text.titleSmall),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'Optional ideas that may help in related cases.',
              style: text.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (var i = 0; i < secondary.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.sm),
              RecommendedFixCard(
                fix: secondary[i],
                fixProvider: fixProvider,
                autoFix: autoFix,
                onRerunDiagnostics: onRerunDiagnostics,
                onApplied: onApplied,
                compact: true,
              ),
            ],
          ],
        ],
        if (showRestore) ...[
          const SizedBox(height: AppSpacing.md),
          RestoreDefaultCard(
            autoFix: autoFix,
            onRestored: () {
              onApplied?.call();
              onRerunDiagnostics?.call();
            },
          ),
        ],
      ],
    );
  }
}

class _TechnicalDetailsSection extends StatelessWidget {
  const _TechnicalDetailsSection({required this.details});

  final List<TechnicalDetailView> details;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionEyebrow('Technical details'),
        const SizedBox(height: AppSpacing.sm),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Verified',
                style: AppTypography.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Grouped by DNS · TCP · TLS · HTTP · Rules.',
                style: AppTypography.textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _TechnicalExpander(details: details),
            ],
          ),
        ),
      ],
    );
  }
}

class _TechnicalExpander extends StatefulWidget {
  const _TechnicalExpander({required this.details});

  final List<TechnicalDetailView> details;

  @override
  State<_TechnicalExpander> createState() => _TechnicalExpanderState();
}

class _TechnicalExpanderState extends State<_TechnicalExpander>
    with SingleTickerProviderStateMixin {
  var _expanded = false;
  late final AnimationController _chevron;

  @override
  void initState() {
    super.initState();
    _chevron = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
  }

  @override
  void dispose() {
    _chevron.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _chevron.forward();
    } else {
      _chevron.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = AppTypography.textTheme;
    final mono = text.bodySmall?.copyWith(
      fontFamily: 'Menlo',
      fontFamilyFallback: const ['Consolas', 'monospace'],
      color: AppColors.onSurfaceVariant,
      height: 1.45,
    );
    final details = widget.details;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: _toggle,
          borderRadius: AppRadius.xsAll,
          hoverColor: AppColors.surfaceHigh.withValues(alpha: 0.4),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'View technical details',
                    style: text.titleSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                RotationTransition(
                  turns: Tween<double>(begin: 0, end: 0.5).animate(
                    CurvedAnimation(
                      parent: _chevron,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                  child: Icon(
                    Icons.expand_more_rounded,
                    size: AppSpacing.iconRow,
                    color: _expanded
                        ? AppColors.primary
                        : AppColors.onSurfaceMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (details.isEmpty)
                  Text(
                    'No details for this run.',
                    style: text.bodySmall?.copyWith(
                      color: AppColors.onSurfaceMuted,
                    ),
                  )
                else
                  for (final detail in details)
                    if (detail.label.startsWith('—'))
                      Padding(
                        padding: const EdgeInsets.only(
                          top: AppSpacing.sm,
                          bottom: AppSpacing.xs,
                        ),
                        child: Text(
                          detail.label.replaceAll('—', '').trim(),
                          style: text.labelMedium?.copyWith(
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: SelectableText(
                          detail.value.isEmpty
                              ? detail.label
                              : '${detail.label}: ${detail.value}',
                          style: mono,
                        ),
                      ),
              ],
            ),
          ),
          crossFadeState: _expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 180),
          sizeCurve: Curves.easeOutCubic,
        ),
      ],
    );
  }
}

class _ScoreRingPainter extends CustomPainter {
  _ScoreRingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - AppSpacing.healthRingStroke;
    const stroke = AppSpacing.healthRingStroke;

    final track = Paint()
      ..color = AppColors.surfaceHighest
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final sweep = Paint()
      ..shader = SweepGradient(
        colors: const [
          AppColors.success,
          AppColors.tertiary,
          AppColors.primary,
        ],
        stops: const [0.0, 0.55, 1.0],
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      sweep,
    );
  }

  @override
  bool shouldRepaint(covariant _ScoreRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
