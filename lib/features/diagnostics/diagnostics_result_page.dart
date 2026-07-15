import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../application/diagnostics/diagnostics_coordinator.dart';
import '../../design_system/design_system.dart';
import '../../di/app_services.dart';
import '../../domain/autofix/fix_provider.dart';
import '../../domain/models/diagnostics/diagnostic_report.dart';
import 'diagnostics_result_view_data.dart';
import 'human_message.dart';
import 'recommended_fix_card.dart';

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
      if (i > 0) widgets.add(const SizedBox(height: AppSpacing.xl));
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
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF12121A),
              AppColors.background,
              Color(0xFF0E0E14),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 840),
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.lg,
                      AppSpacing.xl,
                      AppSpacing.xxxl,
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
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Results', style: text.headlineSmall),
                                    Text(
                                      _loading
                                          ? 'Listening to your network…'
                                          : _error != null
                                              ? 'Couldn’t complete this check'
                                              : '${data?.timestampLabel ?? ''} · RouteFix',
                                      style: text.bodySmall?.copyWith(
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              StatusBadge(
                                label: _loading
                                    ? 'Checking'
                                    : _error != null
                                        ? 'Needs retry'
                                        : _partial
                                            ? 'Partial'
                                            : 'Ready',
                                tone: _loading
                                    ? StatusBadgeTone.info
                                    : _error != null
                                        ? StatusBadgeTone.error
                                        : _partial
                                            ? StatusBadgeTone.warning
                                            : StatusBadgeTone.success,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        if (_loading) ...[
                          const _LoadingCard(
                            label: 'Checking how healthy your routes feel…',
                          ),
                          const SizedBox(height: AppSpacing.md),
                          const _LoadingCard(
                            label: 'Comparing everyday developer paths…',
                          ),
                          const SizedBox(height: AppSpacing.md),
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
                            _ProblemSection(problems: data.problems),
                            _ImpactSection(impacts: data.serviceImpacts),
                            _RecommendationSection(
                              primary: data.primaryFix,
                              secondary: data.secondaryFixes,
                              fixProvider: AppServices.fixProvider,
                              onRerunDiagnostics: _loading ? null : _load,
                            ),
                            _TechnicalDetailsSection(
                              details: data.technicalDetails,
                            ),
                          ]),
                        ],
                        const SizedBox(height: AppSpacing.xxl),
                        SizedBox(
                          width: double.infinity,
                          child: PrimaryButton(
                            label: 'Done',
                            icon: Icons.check_rounded,
                            expanded: true,
                            onPressed: _loading ? null : _handleClose,
                          ),
                        ),
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
        letterSpacing: 0.3,
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
            width: 20,
            height: 20,
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
        const _SectionEyebrow('Health'),
        const SizedBox(height: AppSpacing.sm),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 112,
                    height: 112,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: score / 100),
                      duration: const Duration(milliseconds: 960),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) {
                        return CustomPaint(
                          painter: _ScoreRingPainter(progress: value),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$score',
                                  style: text.headlineMedium?.copyWith(
                                    letterSpacing: -1.2,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                                Text(
                                  'health',
                                  style: text.labelSmall?.copyWith(
                                    color: AppColors.onSurfaceMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                data.scoreLabel,
                                style: text.titleMedium,
                              ),
                            ),
                            StatusBadge(
                              label:
                                  '${(data.confidence * 100).round()}% sure',
                              tone: data.scoreTone,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          data.scoreSummary,
                          style: text.bodyMedium?.copyWith(
                            color: AppColors.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ClipRRect(
                          borderRadius: AppRadius.pill,
                          child: LinearProgressIndicator(
                            value: score / 100,
                            minHeight: 5,
                            backgroundColor: AppColors.surfaceHighest,
                            color: barColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (data.networkMetrics.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                const Divider(height: 1, color: AppColors.outlineSubtle),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Network snapshot',
                  style: text.titleSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                for (var i = 0; i < data.networkMetrics.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.sm),
                  _MetricRow(metric: data.networkMetrics[i]),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.metric});

  final NetworkMetricView metric;

  @override
  Widget build(BuildContext context) {
    final text = AppTypography.textTheme;
    final accent = switch (metric.tone) {
      StatusBadgeTone.success => AppColors.success,
      StatusBadgeTone.warning => AppColors.warning,
      StatusBadgeTone.error => AppColors.error,
      StatusBadgeTone.info => AppColors.primary,
      StatusBadgeTone.neutral => AppColors.onSurfaceVariant,
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow.withValues(alpha: 0.55),
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.outlineSubtle),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: AppRadius.smAll,
            ),
            child: Icon(metric.icon, size: 18, color: accent),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(metric.title, style: text.titleSmall),
                Text(
                  metric.detail,
                  style: text.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Text(
            metric.value,
            style: text.titleSmall?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
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
                    problems.isEmpty ? 'Nothing standing out' : 'What we noticed',
                    style: text.titleMedium,
                  ),
                  const Spacer(),
                  StatusBadge(
                    label: problems.isEmpty ? 'Clear' : '${problems.length}',
                    tone: problems.isEmpty
                        ? StatusBadgeTone.success
                        : StatusBadgeTone.warning,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (problems.isEmpty)
                Text(
                  'This check didn’t find a clear routing problem. That usually means everyday tools should feel fine.',
                  style: text.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    height: 1.5,
                  ),
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
        Icon(problem.icon, size: 20, color: accent),
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
              const SizedBox(height: 4),
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
        Icon(impact.icon, size: 18, color: AppColors.onSurfaceVariant),
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
    this.onRerunDiagnostics,
  });

  final RecommendedFixView? primary;
  final List<RecommendedFixView> secondary;
  final FixProvider fixProvider;
  final VoidCallback? onRerunDiagnostics;

  @override
  Widget build(BuildContext context) {
    final text = AppTypography.textTheme;
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
                Text('No change needed right now', style: text.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'This check didn’t point to an automatic fix. Keep an eye on speed and try again if something still feels off.',
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
            onRerunDiagnostics: onRerunDiagnostics,
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
                onRerunDiagnostics: onRerunDiagnostics,
                compact: true,
              ),
            ],
          ],
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
                'For advanced users',
                style: AppTypography.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Raw check details stay tucked away unless you need them.',
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

class _TechnicalExpander extends StatelessWidget {
  const _TechnicalExpander({required this.details});

  final List<TechnicalDetailView> details;

  @override
  Widget build(BuildContext context) {
    final text = AppTypography.textTheme;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Material(
        color: Colors.transparent,
        child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: AppSpacing.xs),
        title: Text(
          'View technical details',
          style: text.titleSmall?.copyWith(color: AppColors.primary),
        ),
        iconColor: AppColors.primary,
        collapsedIconColor: AppColors.onSurfaceMuted,
        children: [
          if (details.isEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'No raw logs for this run.',
                style: text.bodySmall?.copyWith(
                  color: AppColors.onSurfaceMuted,
                ),
              ),
            )
          else
            for (final detail in details)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SelectableText(
                    '${detail.label}: ${detail.value}',
                    style: text.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
        ],
      ),
      ),
    );
  }
}

class _ScoreRingPainter extends CustomPainter {
  _ScoreRingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 8;
    const stroke = 9.0;

    final track = Paint()
      ..color = AppColors.surfaceHighest
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final sweep = Paint()
      ..shader = SweepGradient(
        colors: const [
          AppColors.warning,
          AppColors.primary,
          AppColors.tertiary,
        ],
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
