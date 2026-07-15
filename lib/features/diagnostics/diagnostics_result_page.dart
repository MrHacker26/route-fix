import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import 'diagnostics_result_mock.dart';

/// Diagnostics result report — mock data and presentation only.
class DiagnosticsResultPage extends StatefulWidget {
  const DiagnosticsResultPage({
    super.key,
    this.onClose,
  });

  final VoidCallback? onClose;

  @override
  State<DiagnosticsResultPage> createState() => _DiagnosticsResultPageState();
}

class _DiagnosticsResultPageState extends State<DiagnosticsResultPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
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
                                      'Mock report · beautiful summary of this run',
                                      style: text.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              const StatusBadge(
                                label: 'Mock',
                                tone: StatusBadgeTone.neutral,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        _FadeIn(
                          animation: _entrance,
                          interval: const Interval(0.05, 0.4),
                          child: const _OverallScoreSection(),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _FadeIn(
                          animation: _entrance,
                          interval: const Interval(0.12, 0.5),
                          child: const _ChartsSection(),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _FadeIn(
                          animation: _entrance,
                          interval: const Interval(0.2, 0.58),
                          child: const _HealthCardsSection(),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _FadeIn(
                          animation: _entrance,
                          interval: const Interval(0.28, 0.66),
                          child: const _IssuesSection(),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _FadeIn(
                          animation: _entrance,
                          interval: const Interval(0.36, 0.75),
                          child: const _RecommendationsSection(),
                        ),
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
                              onPressed: _handleClose,
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

class _OverallScoreSection extends StatelessWidget {
  const _OverallScoreSection();

  @override
  Widget build(BuildContext context) {
    final text = AppTypography.textTheme;
    const score = DiagnosticsResultMock.overallScore;

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
                    const StatusBadge(
                      label: DiagnosticsResultMock.scoreLabel,
                      tone: StatusBadgeTone.warning,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  DiagnosticsResultMock.scoreSummary,
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
                    color: AppColors.warning,
                  ),
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
  const _ChartsSection();

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
                'Round-trip snapshot (mock ms)',
                style: text.labelSmall,
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                height: 168,
                width: double.infinity,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 1100),
                  curve: Curves.easeOutCubic,
                  builder: (context, t, _) {
                    return CustomPaint(
                      painter: _LatencyBarsPainter(
                        bars: DiagnosticsResultMock.latencyBars,
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
                'Composite latency over this session',
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
                        values: DiagnosticsResultMock.latencyTrend,
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
  const _HealthCardsSection();

  @override
  Widget build(BuildContext context) {
    final cards = DiagnosticsResultMock.healthCards;
    final text = AppTypography.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Health cards', style: text.titleMedium),
        const SizedBox(height: AppSpacing.sm),
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

  final HealthCardMock card;

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
  const _IssuesSection();

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
                label: '${DiagnosticsResultMock.issues.length} found',
                tone: StatusBadgeTone.warning,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < DiagnosticsResultMock.issues.length; i++) ...[
            if (i > 0) ...[
              const SizedBox(height: AppSpacing.sm),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.sm),
            ],
            _IssueRow(issue: DiagnosticsResultMock.issues[i]),
          ],
        ],
      ),
    );
  }
}

class _IssueRow extends StatelessWidget {
  const _IssueRow({required this.issue});

  final IssueMock issue;

  @override
  Widget build(BuildContext context) {
    final text = AppTypography.textTheme;
    final accent = issue.tone == StatusBadgeTone.warning
        ? AppColors.warning
        : AppColors.primary;

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
  const _RecommendationsSection();

  @override
  Widget build(BuildContext context) {
    final text = AppTypography.textTheme;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recommendations', style: text.titleMedium),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0;
              i < DiagnosticsResultMock.recommendations.length;
              i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            _RecommendationTile(
              item: DiagnosticsResultMock.recommendations[i],
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

  final RecommendationMock item;
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

  final List<LatencyBarMock> bars;
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
