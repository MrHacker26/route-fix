import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../diagnostics/diagnostics_page.dart';
import 'dashboard_mock_data.dart';

/// Premium network health report — mock data only.
class DashboardPage extends StatefulWidget {
  const DashboardPage({
    super.key,
    this.onStartDiagnosis,
  });

  final VoidCallback? onStartDiagnosis;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = AppTypography.textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF101018),
              AppColors.background,
              AppColors.background,
            ],
            stops: [0.0, 0.35, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 880),
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.xl,
                      AppSpacing.xl,
                      AppSpacing.xxxl,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _FadeSlide(
                          animation: _entrance,
                          interval: const Interval(0.0, 0.35),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'RouteFix',
                                      style: text.labelLarge?.copyWith(
                                        color: AppColors.primary,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.xxs),
                                    Text(
                                      'Health report',
                                      style: text.headlineMedium,
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      'A calm snapshot of how your routes feel right now.',
                                      style: text.bodyMedium?.copyWith(
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const StatusBadge(
                                label: 'Mock data',
                                tone: StatusBadgeTone.neutral,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        _FadeSlide(
                          animation: _entrance,
                          interval: const Interval(0.08, 0.5),
                          child: const _HealthScoreSection(),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _FadeSlide(
                          animation: _entrance,
                          interval: const Interval(0.16, 0.58),
                          child: const _ConnectionStatusSection(),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _FadeSlide(
                          animation: _entrance,
                          interval: const Interval(0.24, 0.66),
                          child: const _QuickSummarySection(),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _FadeSlide(
                          animation: _entrance,
                          interval: const Interval(0.32, 0.74),
                          child: const _RecentScanSection(),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        _FadeSlide(
                          animation: _entrance,
                          interval: const Interval(0.4, 0.85),
                          child: SizedBox(
                            width: double.infinity,
                            child: PrimaryButton(
                              label: 'Start Diagnosis',
                              icon: Icons.radar_rounded,
                              expanded: true,
                              onPressed: widget.onStartDiagnosis ??
                                  () {
                                    Navigator.of(context).push(
                                      PageRouteBuilder<void>(
                                        transitionDuration: const Duration(
                                          milliseconds: 420,
                                        ),
                                        reverseTransitionDuration:
                                            const Duration(milliseconds: 320),
                                        pageBuilder: (_, animation, secondary) {
                                          return FadeTransition(
                                            opacity: CurvedAnimation(
                                              parent: animation,
                                              curve: Curves.easeOutCubic,
                                            ),
                                            child: const DiagnosticsPage(),
                                          );
                                        },
                                      ),
                                    );
                                  },
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

class _FadeSlide extends StatelessWidget {
  const _FadeSlide({
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
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: curved, curve: Curves.easeOutCubic)),
        child: child,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.trailing,
  });

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: AppTypography.textTheme.titleMedium),
        const Spacer(),
        ?trailing,
      ],
    );
  }
}

class _HealthScoreSection extends StatelessWidget {
  const _HealthScoreSection();

  @override
  Widget build(BuildContext context) {
    final text = AppTypography.textTheme;
    const score = DashboardMockData.healthScore;
    final progress = score / 100;

    return GlassCard(
      child: Row(
        children: [
          _HealthRing(
            progress: progress,
            label: '$score',
          ),
          const SizedBox(width: AppSpacing.xl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionHeader(
                  title: 'Overall health',
                  trailing: StatusBadge(
                    label: DashboardMockData.healthLabel,
                    tone: StatusBadgeTone.success,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  DashboardMockData.healthDetail,
                  style: text.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ClipRRect(
                  borderRadius: AppRadius.pill,
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: AppColors.surfaceHighest,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Score out of 100 · based on last scan',
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

class _HealthRing extends StatelessWidget {
  const _HealthRing({
    required this.progress,
    required this.label,
  });

  final double progress;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 128,
      height: 128,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: progress),
        duration: const Duration(milliseconds: 1100),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) {
          return CustomPaint(
            painter: _RingPainter(progress: value),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: AppTypography.textTheme.headlineLarge?.copyWith(
                      letterSpacing: -1.2,
                    ),
                  ),
                  Text(
                    'score',
                    style: AppTypography.textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - 8;
    const stroke = 8.0;

    final track = Paint()
      ..color = AppColors.surfaceHighest
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final sweep = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
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
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _ConnectionStatusSection extends StatelessWidget {
  const _ConnectionStatusSection();

  @override
  Widget build(BuildContext context) {
    final data = DashboardMockData.connection;
    final text = AppTypography.textTheme;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Connection status',
            trailing: StatusBadge(
              label: data.badgeLabel,
              tone: data.tone,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.successContainer,
                  borderRadius: AppRadius.mdAll,
                ),
                child: const Icon(
                  Icons.wifi_rounded,
                  color: AppColors.success,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data.title, style: text.titleSmall),
                    Text(
                      data.subtitle,
                      style: text.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceLow.withValues(alpha: 0.7),
              borderRadius: AppRadius.mdAll,
              border: Border.all(color: AppColors.outlineSubtle),
            ),
            child: Row(
              children: [
                for (var i = 0; i < data.details.length; i++) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.details[i].label,
                          style: text.labelSmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          data.details[i].value,
                          style: text.titleSmall?.copyWith(
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickSummarySection extends StatelessWidget {
  const _QuickSummarySection();

  @override
  Widget build(BuildContext context) {
    final items = DashboardMockData.summary;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(title: 'Quick summary'),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) ...[
              const SizedBox(height: AppSpacing.sm),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.sm),
            ],
            _SummaryRow(item: items[i]),
          ],
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.item});

  final SummaryItemMock item;

  @override
  Widget build(BuildContext context) {
    final text = AppTypography.textTheme;

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surfaceHigh,
            borderRadius: AppRadius.smAll,
            border: Border.all(color: AppColors.outlineSubtle),
          ),
          child: Icon(item.icon, size: 20, color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.title, style: text.titleSmall),
              Text(item.detail, style: text.bodySmall),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        StatusBadge(label: item.badge, tone: item.tone),
      ],
    );
  }
}

class _RecentScanSection extends StatelessWidget {
  const _RecentScanSection();

  @override
  Widget build(BuildContext context) {
    final scan = DashboardMockData.recentScan;
    final text = AppTypography.textTheme;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Recent scan',
            trailing: StatusBadge(
              label: 'Needs review',
              tone: scan.tone,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(scan.title, style: text.titleLarge),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            scan.timestamp,
            style: text.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              _ScanStat(
                label: 'Duration',
                value: scan.duration,
              ),
              const SizedBox(width: AppSpacing.sm),
              _ScanStat(
                label: 'Targets',
                value: '${scan.targets}',
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ScanStat(
                  label: 'Top finding',
                  value: scan.finding,
                  compact: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScanStat extends StatelessWidget {
  const _ScanStat({
    required this.label,
    required this.value,
    this.compact = true,
  });

  final String label;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final text = AppTypography.textTheme;

    return Container(
      width: compact ? 108 : null,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow.withValues(alpha: 0.7),
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.outlineSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: text.labelSmall),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: text.titleSmall?.copyWith(
              height: 1.25,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
