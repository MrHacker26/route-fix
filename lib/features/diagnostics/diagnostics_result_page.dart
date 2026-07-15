import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../application/diagnostics/diagnostics_coordinator.dart';
import '../../design_system/design_system.dart';
import '../../di/app_services.dart';
import '../../domain/models/diagnostics/diagnostic_report.dart';
import 'diagnostics_result_view_data.dart';
import 'recommended_fix_card.dart';

/// Diagnostics result report powered by a real [DiagnosticReport].
class DiagnosticsResultPage extends StatefulWidget {
  const DiagnosticsResultPage({
    super.key,
    this.report,
    this.coordinator,
    this.onClose,
  });

  /// When provided, skips loading and renders immediately.
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
  var _partial = false;

  DiagnosticsCoordinator get _coordinator =>
      widget.coordinator ?? AppServices.diagnostics;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
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
      _partial = report.metadata['ipv4_success'] == 'false' ||
          report.metadata['cloudflare_success'] == 'false' ||
          (report.issues.isNotEmpty && report.recommendations.isEmpty);
    });
    _entrance
      ..reset()
      ..forward();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final report = await _coordinator.run();
      if (!mounted) return;
      _applyReport(report);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _friendlyError(error);
      });
      _entrance
        ..reset()
        ..forward();
    }
  }

  String _friendlyError(Object error) {
    final message = error.toString();
    if (message.contains('SocketException') ||
        message.contains('Failed host lookup') ||
        message.contains('Network is unreachable')) {
      return 'Couldn’t reach the network to build results. Check connectivity and retry.';
    }
    if (message.contains('TimeoutException') || message.contains('timed out')) {
      return 'The diagnostic run timed out before results were ready.';
    }
    return 'Unable to load diagnostic results. Please try again.';
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
              constraints: const BoxConstraints(maxWidth: 920),
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
                          interval: const Interval(0.0, 0.3),
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
                                    Text(
                                      'Scan results',
                                      style: text.headlineSmall,
                                    ),
                                    Text(
                                      _loading
                                          ? 'Gathering diagnostic report…'
                                          : _error != null
                                              ? 'Results unavailable'
                                              : '${data?.timestampLabel ?? ''} · live report',
                                      style: text.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              StatusBadge(
                                label: _loading
                                    ? 'Loading'
                                    : _error != null
                                        ? 'Error'
                                        : _partial
                                            ? 'Partial'
                                            : 'Live',
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
                          const _LoadingCard(label: 'Building overall score…'),
                          const SizedBox(height: AppSpacing.lg),
                          const _LoadingCard(label: 'Preparing network metrics…'),
                          const SizedBox(height: AppSpacing.lg),
                          const _LoadingCard(label: 'Summarizing findings…'),
                        ] else if (_error != null) ...[
                          _FadeIn(
                            animation: _entrance,
                            interval: const Interval(0.08, 0.55),
                            child: _ErrorCard(
                              message: _error!,
                              onRetry: _load,
                            ),
                          ),
                        ] else if (data != null) ...[
                          _FadeIn(
                            animation: _entrance,
                            interval: const Interval(0.05, 0.4),
                            child: _OverallScoreSection(data: data),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _FadeIn(
                            animation: _entrance,
                            interval: const Interval(0.12, 0.5),
                            child: _ChartsSection(data: data),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _FadeIn(
                            animation: _entrance,
                            interval: const Interval(0.2, 0.58),
                            child: _HealthCardsSection(cards: data.metricCards),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _FadeIn(
                            animation: _entrance,
                            interval: const Interval(0.28, 0.66),
                            child: _IssuesSection(issues: data.issues),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _FadeIn(
                            animation: _entrance,
                            interval: const Interval(0.36, 0.75),
                            child: _RecommendationsSection(
                              recommendations: data.recommendations,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _FadeIn(
                            animation: _entrance,
                            interval: const Interval(0.42, 0.82),
                            child: _RecommendedFixesSection(
                              fixes: data.recommendedFixes,
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.xxl),
                        _FadeIn(
                          animation: _entrance,
                          interval: const Interval(0.45, 0.85),
                          child: SizedBox(
                            width: double.infinity,
                            child: PrimaryButton(
                              label: 'Done',
                              icon: Icons.check_rounded,
                              expanded: true,
                              onPressed: _loading ? null : _handleClose,
                            ),
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
          begin: const Offset(0, 0.035),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: curved, curve: Curves.easeOutCubic)),
        child: child,
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
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: AppTypography.textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
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
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Unable to load results', style: AppTypography.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            style: AppTypography.textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SecondaryButton(
            label: 'Retry',
            icon: Icons.refresh_rounded,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

class _OverallScoreSection extends StatelessWidget {
  const _OverallScoreSection({required this.data});

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

    return GlassCard(
      child: Row(
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: score / 100),
              duration: const Duration(milliseconds: 1200),
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
                          style: text.displaySmall?.copyWith(
                            letterSpacing: -1.4,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        Text('overall', style: text.labelSmall),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: AppSpacing.xl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Overall score', style: text.titleMedium),
                    const Spacer(),
                    StatusBadge(
                      label: data.scoreLabel,
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
                    minHeight: 6,
                    backgroundColor: AppColors.surfaceHighest,
                    color: barColor,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Confidence ${(data.confidence * 100).round()}% · ${data.timestampLabel}',
                  style: text.labelSmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartsSection extends StatelessWidget {
  const _ChartsSection({required this.data});

  final DiagnosticsResultViewData data;

  @override
  Widget build(BuildContext context) {
    final text = AppTypography.textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 700;

        final latencyChart = GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Latency by target', style: text.titleMedium),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                data.latencyBars.isEmpty
                    ? 'No latency samples in this report'
                    : 'Round-trip snapshot from this run',
                style: text.labelSmall,
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                height: 168,
                width: double.infinity,
                child: data.latencyBars.isEmpty
                    ? Center(
                        child: Text(
                          'Metrics unavailable',
                          style: text.bodySmall,
                        ),
                      )
                    : TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 1100),
                        curve: Curves.easeOutCubic,
                        builder: (context, t, _) {
                          return CustomPaint(
                            painter: _LatencyBarsPainter(
                              bars: data.latencyBars,
                              progress: t,
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );

        final trendChart = GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Stability trend', style: text.titleMedium),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                'Composite signal from collected metrics',
                style: text.labelSmall,
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                height: 168,
                width: double.infinity,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutCubic,
                  builder: (context, t, _) {
                    return CustomPaint(
                      painter: _SparklinePainter(
                        values: data.stabilityTrend,
                        progress: t,
                        fill: true,
                        color: AppColors.primary,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );

        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: latencyChart),
              const SizedBox(width: AppSpacing.lg),
              Expanded(child: trendChart),
            ],
          );
        }

        return Column(
          children: [
            latencyChart,
            const SizedBox(height: AppSpacing.lg),
            trendChart,
          ],
        );
      },
    );
  }
}

class _HealthCardsSection extends StatelessWidget {
  const _HealthCardsSection({required this.cards});

  final List<MetricCardView> cards;

  @override
  Widget build(BuildContext context) {
    final text = AppTypography.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Health cards', style: text.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        if (cards.isEmpty)
          GlassCard(
            child: Text(
              'No network metrics were captured for this run.',
              style: text.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final crossAxisCount = width >= 820
                  ? 3
                  : width >= 540
                      ? 2
                      : 1;
              final itemWidth =
                  (width - (AppSpacing.sm * (crossAxisCount - 1))) /
                      crossAxisCount;

              return Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final card in cards)
                    SizedBox(
                      width: itemWidth,
                      child: _HealthCard(card: card),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }
}

class _HealthCard extends StatelessWidget {
  const _HealthCard({required this.card});

  final MetricCardView card;

  @override
  Widget build(BuildContext context) {
    final text = AppTypography.textTheme;
    final accent = switch (card.tone) {
      StatusBadgeTone.success => AppColors.success,
      StatusBadgeTone.warning => AppColors.warning,
      StatusBadgeTone.error => AppColors.error,
      StatusBadgeTone.info => AppColors.primary,
      StatusBadgeTone.neutral => AppColors.onSurfaceVariant,
    };

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: AppRadius.smAll,
                ),
                child: Icon(card.icon, size: 18, color: accent),
              ),
              const Spacer(),
              StatusBadge(label: card.title, tone: card.tone, showDot: false),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            card.value,
            style: text.headlineSmall?.copyWith(letterSpacing: -0.8),
          ),
          Text(card.detail, style: text.bodySmall),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 36,
            width: double.infinity,
            child: CustomPaint(
              painter: _SparklinePainter(
                values: card.spark,
                progress: 1,
                fill: false,
                color: accent,
                strokeWidth: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IssuesSection extends StatelessWidget {
  const _IssuesSection({required this.issues});

  final List<IssueView> issues;

  @override
  Widget build(BuildContext context) {
    final text = AppTypography.textTheme;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Detected issues', style: text.titleMedium),
              const Spacer(),
              StatusBadge(
                label: issues.isEmpty ? 'None' : '${issues.length} found',
                tone: issues.isEmpty
                    ? StatusBadgeTone.success
                    : StatusBadgeTone.warning,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (issues.isEmpty)
            Text(
              'No issues detected. This diagnostic run looks clear.',
              style: text.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
                height: 1.45,
              ),
            )
          else
            for (var i = 0; i < issues.length; i++) ...[
              if (i > 0) ...[
                const SizedBox(height: AppSpacing.sm),
                const Divider(height: 1),
                const SizedBox(height: AppSpacing.sm),
              ],
              _IssueRow(issue: issues[i]),
            ],
        ],
      ),
    );
  }
}

class _IssueRow extends StatelessWidget {
  const _IssueRow({required this.issue});

  final IssueView issue;

  @override
  Widget build(BuildContext context) {
    final text = AppTypography.textTheme;
    final accent = switch (issue.tone) {
      StatusBadgeTone.warning => AppColors.warning,
      StatusBadgeTone.error => AppColors.error,
      _ => AppColors.primary,
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: AppRadius.smAll,
          ),
          child: Icon(issue.icon, color: accent, size: 20),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(issue.title, style: text.titleSmall),
                  ),
                  StatusBadge(
                    label: issue.severity,
                    tone: issue.tone,
                    showDot: false,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                issue.detail,
                style: text.bodySmall?.copyWith(height: 1.45),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecommendationsSection extends StatelessWidget {
  const _RecommendationsSection({required this.recommendations});

  final List<RecommendationView> recommendations;

  @override
  Widget build(BuildContext context) {
    final text = AppTypography.textTheme;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recommendations', style: text.titleMedium),
          const SizedBox(height: AppSpacing.md),
          if (recommendations.isEmpty)
            Text(
              'No recommendations right now. Keep an eye on confidence and latency.',
              style: text.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
                height: 1.45,
              ),
            )
          else
            for (var i = 0; i < recommendations.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.sm),
              _RecommendationTile(
                item: recommendations[i],
                index: i + 1,
              ),
            ],
        ],
      ),
    );
  }
}

class _RecommendationTile extends StatelessWidget {
  const _RecommendationTile({
    required this.item,
    required this.index,
  });

  final RecommendationView item;
  final int index;

  @override
  Widget build(BuildContext context) {
    final text = AppTypography.textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow.withValues(alpha: 0.65),
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.outlineSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: AppRadius.smAll,
            ),
            child: Text(
              '$index',
              style: text.labelMedium?.copyWith(color: AppColors.primary),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(item.icon, size: 16, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(item.title, style: text.titleSmall),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.detail,
                  style: text.bodySmall?.copyWith(height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendedFixesSection extends StatelessWidget {
  const _RecommendedFixesSection({required this.fixes});

  final List<RecommendedFixView> fixes;

  @override
  Widget build(BuildContext context) {
    final text = AppTypography.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recommended fixes', style: text.titleMedium),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          'Suggested Auto Fix actions for issues found in this scan.',
          style: text.bodySmall?.copyWith(
            color: AppColors.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (fixes.isEmpty)
          GlassCard(
            child: Text(
              'No Auto Fix suggestions for this report yet.',
              style: text.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          )
        else
          for (var i = 0; i < fixes.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            RecommendedFixCard(fix: fixes[i]),
          ],
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
    final radius = size.shortestSide / 2 - 10;
    const stroke = 10.0;

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

class _LatencyBarsPainter extends CustomPainter {
  _LatencyBarsPainter({
    required this.bars,
    required this.progress,
  });

  final List<LatencyBarView> bars;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (bars.isEmpty) return;

    final maxMs = bars.map((b) => b.ms).reduce(math.max).clamp(1, 9999);
    const labelH = 18.0;
    const topPad = 8.0;
    final chartH = size.height - labelH - topPad;
    final slot = size.width / bars.length;
    final barW = slot * 0.52;

    for (var i = 0; i < bars.length; i++) {
      final bar = bars[i];
      final h = chartH * (bar.ms / maxMs) * progress;
      final x = slot * i + (slot - barW) / 2;
      final y = topPad + chartH - h;
      final color = switch (bar.tone) {
        StatusBadgeTone.success => AppColors.success,
        StatusBadgeTone.warning => AppColors.warning,
        StatusBadgeTone.error => AppColors.error,
        _ => AppColors.primary,
      };

      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barW, math.max(h, 2)),
        const Radius.circular(8),
      );

      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            color.withValues(alpha: 0.35),
            color,
          ],
        ).createShader(rrect.outerRect);

      canvas.drawRRect(rrect, paint);

      final tp = TextPainter(
        text: TextSpan(
          text: bar.label,
          style: AppTypography.textTheme.labelSmall?.copyWith(
            color: AppColors.onSurfaceMuted,
            fontSize: 10,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: slot);

      tp.paint(
        canvas,
        Offset(
          slot * i + (slot - tp.width) / 2,
          size.height - tp.height,
        ),
      );

      if (progress > 0.85) {
        final value = TextPainter(
          text: TextSpan(
            text: '${bar.ms.round()}',
            style: AppTypography.textTheme.labelMedium?.copyWith(
              color: AppColors.onSurface,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        value.paint(
          canvas,
          Offset(x + (barW - value.width) / 2, y - value.height - 4),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LatencyBarsPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.values,
    required this.progress,
    required this.color,
    this.fill = false,
    this.strokeWidth = 2.5,
  });

  final List<double> values;
  final double progress;
  final Color color;
  final bool fill;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final minV = values.reduce(math.min);
    final maxV = values.reduce(math.max);
    final range = (maxV - minV).abs() < 0.001 ? 1.0 : (maxV - minV);
    final count = values.length;
    final visible = math.max(2, (count * progress).ceil());

    Offset pointFor(int i) {
      final x = size.width * (i / (count - 1));
      final norm = (values[i] - minV) / range;
      final y = size.height - (norm * (size.height - 8)) - 4;
      return Offset(x, y);
    }

    final path = Path()..moveTo(pointFor(0).dx, pointFor(0).dy);
    for (var i = 1; i < visible; i++) {
      final p0 = pointFor(i - 1);
      final p1 = pointFor(i);
      final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
      path.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
    }
    final last = pointFor(visible - 1);
    path.lineTo(last.dx, last.dy);

    if (fill) {
      final fillPath = Path.from(path)
        ..lineTo(last.dx, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(
        fillPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: 0.28),
              color.withValues(alpha: 0.0),
            ],
          ).createShader(Offset.zero & size),
      );
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    if (fill && progress > 0.9) {
      canvas.drawCircle(
        last,
        4,
        Paint()..color = color,
      );
      canvas.drawCircle(
        last,
        7,
        Paint()
          ..color = color.withValues(alpha: 0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
