import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../application/diagnostics/diagnostics_coordinator.dart';
import '../../design_system/design_system.dart';
import '../../di/app_services.dart';
import '../diagnostics/diagnostics_page.dart';
import '../diagnostics/diagnostics_result_page.dart';
import '../network_controls/network_controls_page.dart';
import '../settings/settings_page.dart';
import 'dashboard_view_data.dart';

/// Desktop command center — powered by [DiagnosticsCoordinator].
class DashboardPage extends StatefulWidget {
  const DashboardPage({
    super.key,
    this.coordinator,
    this.onStartDiagnosis,
  });

  final DiagnosticsCoordinator? coordinator;
  final VoidCallback? onStartDiagnosis;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;

  DashboardViewData? _data;
  var _loading = true;
  String? _error;

  DiagnosticsCoordinator get _coordinator =>
      widget.coordinator ?? AppServices.diagnostics;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _load();
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final report = await _coordinator.run();
      if (!mounted) return;
      setState(() {
        _data = DashboardViewData.fromReport(report);
        _loading = false;
      });
      _entrance
        ..reset()
        ..forward();
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
      return 'Couldn’t reach the network. Check your connection and try again.';
    }
    if (message.contains('TimeoutException') || message.contains('timed out')) {
      return 'This scan took too long. Try again.';
    }
    return 'Something went wrong. Try again.';
  }

  void _openScan() {
    if (widget.onStartDiagnosis != null) {
      widget.onStartDiagnosis!();
      return;
    }
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, animation, secondary) {
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
  }

  void _openResults({bool focusRecommendation = false}) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, animation, secondary) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: DiagnosticsResultPage(
              focusRecommendation: focusRecommendation,
            ),
          );
        },
      ),
    );
  }

  void _openNetworkControls() {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, animation, secondary) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: const NetworkControlsPage(),
          );
        },
      ),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, animation, secondary) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: SettingsPage(controller: AppServices.settings),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 980;
    final data = _data;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyR, meta: true): _load,
        const SingleActivator(LogicalKeyboardKey.keyR, control: true): _load,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: PageAtmosphere(
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppSpacing.desktopMaxWidth,
                  ),
                  child: Column(
                    children: [
                      _DesktopToolbar(
                        loading: _loading,
                        error: _error != null,
                        healthLabel: data?.healthLabel,
                        healthTone: data?.healthTone,
                        scannedAt: data?.scannedAtLabel,
                        onRunScan: _loading ? null : _openScan,
                        onRefresh: _loading ? null : _load,
                        onNetworkControls: _openNetworkControls,
                        onSettings: _openSettings,
                      ),
                      Expanded(
                        child: CustomScrollView(
                          physics: const BouncingScrollPhysics(),
                          slivers: [
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.xl,
                                AppSpacing.sm,
                                AppSpacing.xl,
                                AppSpacing.xl,
                              ),
                              sliver: SliverList(
                                delegate: SliverChildListDelegate([
                                  if (_loading)
                                    _CommandCenterLoading(wide: wide)
                                  else if (_error != null)
                                    _ErrorBanner(
                                      message: _error!,
                                      onRetry: _load,
                                    )
                                  else if (data != null) ...[
                                    _FadeIn(
                                      animation: _entrance,
                                      interval: const Interval(0.0, 0.45),
                                      child: wide
                                          ? IntrinsicHeight(
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.stretch,
                                                children: [
                                                  Expanded(
                                                    flex: 4,
                                                    child: _HealthSummaryCard(
                                                      data: data,
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                    width: AppSpacing.sm,
                                                  ),
                                                  Expanded(
                                                    flex: 6,
                                                    child: _NetworkSnapshotCard(
                                                      rows: data.networkRows,
                                                      onOpenResults:
                                                          _openResults,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          : Column(
                                              children: [
                                                _HealthSummaryCard(data: data),
                                                const SizedBox(
                                                  height: AppSpacing.sm,
                                                ),
                                                _NetworkSnapshotCard(
                                                  rows: data.networkRows,
                                                  onOpenResults: _openResults,
                                                ),
                                              ],
                                            ),
                                    ),
                                    const SizedBox(height: AppSpacing.sectionGap),
                                    _FadeIn(
                                      animation: _entrance,
                                      interval: const Interval(0.12, 0.55),
                                      child: wide
                                          ? IntrinsicHeight(
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.stretch,
                                                children: [
                                                  Expanded(
                                                    flex: 6,
                                                    child:
                                                        _RecommendationCard(
                                                      title: data
                                                          .recommendationTitle,
                                                      detail: data
                                                          .recommendationDetail,
                                                      tone: data
                                                          .recommendationTone,
                                                      action: data
                                                          .recommendationAction,
                                                      lastVerified:
                                                          data.scannedAtLabel,
                                                      onTap: data
                                                                  .recommendationAction !=
                                                              null
                                                          ? () => _openResults(
                                                                focusRecommendation:
                                                                    true,
                                                              )
                                                          : null,
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                    width: AppSpacing.sm,
                                                  ),
                                                  Expanded(
                                                    flex: 4,
                                                    child: _RecentScanCard(
                                                      scan: data.recentScan,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          : Column(
                                              children: [
                                                _RecommendationCard(
                                                  title: data
                                                      .recommendationTitle,
                                                  detail: data
                                                      .recommendationDetail,
                                                  tone: data
                                                      .recommendationTone,
                                                  action: data
                                                      .recommendationAction,
                                                  lastVerified:
                                                      data.scannedAtLabel,
                                                  onTap: data
                                                              .recommendationAction !=
                                                          null
                                                      ? () => _openResults(
                                                            focusRecommendation:
                                                                true,
                                                          )
                                                      : null,
                                                ),
                                                const SizedBox(
                                                  height: AppSpacing.sm,
                                                ),
                                                _RecentScanCard(
                                                  scan: data.recentScan,
                                                ),
                                              ],
                                            ),
                                    ),
                                    const SizedBox(height: AppSpacing.sectionGap),
                                    _FadeIn(
                                      animation: _entrance,
                                      interval: const Interval(0.22, 0.65),
                                      child: _DeveloperServicesCard(
                                        services: data.services,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.sectionGap),
                                    _FadeIn(
                                      animation: _entrance,
                                      interval: const Interval(0.32, 0.75),
                                      child: _TechnicalDetailsCard(
                                        groups: data.technicalGroups,
                                        initiallyExpanded: AppServices
                                            .settings
                                            .settings
                                            .showTechnicalDetailsByDefault,
                                      ),
                                    ),
                                  ],
                                ]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
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
          begin: const Offset(0, 0.02),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: curved, curve: Curves.easeOutCubic)),
        child: child,
      ),
    );
  }
}

class _DesktopToolbar extends StatelessWidget {
  const _DesktopToolbar({
    required this.loading,
    required this.error,
    required this.onRunScan,
    required this.onRefresh,
    required this.onNetworkControls,
    required this.onSettings,
    this.healthLabel,
    this.healthTone,
    this.scannedAt,
  });

  final bool loading;
  final bool error;
  final String? healthLabel;
  final StatusBadgeTone? healthTone;
  final String? scannedAt;
  final VoidCallback? onRunScan;
  final VoidCallback? onRefresh;
  final VoidCallback onNetworkControls;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final text = AppTypography.textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final showTimestamp =
            scannedAt != null && !loading && constraints.maxWidth >= 860;

        return Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.outlineSubtle),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: AppRadius.xsAll,
                child: Image.asset(
                  AppAssets.appIcon,
                  width: 24,
                  height: 24,
                  filterQuality: FilterQuality.medium,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'RouteFix',
                style: text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              StatusBadge(
                label: loading
                    ? 'Scanning'
                    : error
                        ? 'Attention'
                        : (healthLabel ?? 'Ready'),
                tone: loading
                    ? StatusBadgeTone.info
                    : error
                        ? StatusBadgeTone.error
                        : (healthTone ?? StatusBadgeTone.neutral),
              ),
              const Spacer(),
              if (showTimestamp)
                Text(
                  'Last scan $scannedAt',
                  overflow: TextOverflow.ellipsis,
                  style: text.labelSmall?.copyWith(
                    color: AppColors.onSurfaceMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              if (showTimestamp) const SizedBox(width: AppSpacing.sm),
              IconButton(
                tooltip: 'Network Controls',
                onPressed: onNetworkControls,
                icon: const Icon(
                  Icons.tune_rounded,
                  size: AppSpacing.iconInline,
                ),
                style: IconButton.styleFrom(
                  foregroundColor: AppColors.onSurfaceVariant,
                  hoverColor: AppColors.surfaceHigh,
                  minimumSize: const Size(32, 32),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.xsAll,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xxs),
              IconButton(
                tooltip: 'Settings',
                onPressed: onSettings,
                icon: const Icon(
                  Icons.settings_outlined,
                  size: AppSpacing.iconInline,
                ),
                style: IconButton.styleFrom(
                  foregroundColor: AppColors.onSurfaceVariant,
                  hoverColor: AppColors.surfaceHigh,
                  minimumSize: const Size(32, 32),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.xsAll,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xxs),
              IconButton(
                tooltip: 'Refresh',
                onPressed: onRefresh,
                icon: const Icon(
                  Icons.refresh_rounded,
                  size: AppSpacing.iconInline,
                ),
                style: IconButton.styleFrom(
                  foregroundColor: AppColors.onSurfaceVariant,
                  hoverColor: AppColors.surfaceHigh,
                  minimumSize: const Size(32, 32),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.xsAll,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              SecondaryButton(
                label: loading ? 'Scanning…' : 'Scan',
                icon: loading ? null : Icons.radar_rounded,
                onPressed: onRunScan,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CommandCenterLoading extends StatelessWidget {
  const _CommandCenterLoading({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    return FeedbackState.loading(
      title: 'Scanning your network',
      body: wide
          ? 'Checking health, paths, and developer services.'
          : 'Checking health and paths.',
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return FeedbackState.error(
      title: 'Couldn’t load health report',
      body: message,
      onAction: onRetry,
    );
  }
}

class _HealthSummaryCard extends StatelessWidget {
  const _HealthSummaryCard({required this.data});

  final DashboardViewData data;

  @override
  Widget build(BuildContext context) {
    final text = AppTypography.textTheme;
    final score = data.healthScore;
    final barColor = switch (data.healthTone) {
      StatusBadgeTone.success => AppColors.success,
      StatusBadgeTone.warning => AppColors.warning,
      StatusBadgeTone.error => AppColors.error,
      _ => AppColors.primary,
    };

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Health',
                style: text.labelMedium?.copyWith(
                  color: AppColors.onSurfaceMuted,
                  letterSpacing: 0.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              StatusBadge(label: data.healthLabel, tone: data.healthTone),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
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
                        painter: _RingPainter(progress: value),
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
                    _HealthMetaRow(label: 'Score', value: '$score'),
                    const SizedBox(height: AppSpacing.xxs),
                    _HealthMetaRow(
                      label: 'Status',
                      value: data.healthLabel,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    _HealthMetaRow(
                      label: 'Confidence',
                      value: data.confidenceLabel,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    _HealthMetaRow(
                      label: 'Last scan',
                      value: data.scannedAtLabel,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      data.canStartWorking,
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
    );
  }
}

class _HealthMetaRow extends StatelessWidget {
  const _HealthMetaRow({required this.label, required this.value});

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

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - AppSpacing.healthRingStroke;
    const stroke = AppSpacing.healthRingStroke;

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

class _NetworkSnapshotCard extends StatelessWidget {
  const _NetworkSnapshotCard({
    required this.rows,
    required this.onOpenResults,
  });

  final List<NetworkSnapshotRow> rows;
  final VoidCallback onOpenResults;

  @override
  Widget build(BuildContext context) {
    final text = AppTypography.textTheme;

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Network',
                style: text.labelMedium?.copyWith(
                  color: AppColors.onSurfaceMuted,
                  letterSpacing: 0.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: onOpenResults,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  textStyle: text.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: AppSpacing.xxs,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Full results'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xxs),
                child: Divider(height: 1, color: AppColors.outlineSubtle),
              ),
            _SnapshotRow(row: rows[i]),
          ],
        ],
      ),
    );
  }
}

class _SnapshotRow extends StatefulWidget {
  const _SnapshotRow({required this.row});

  final NetworkSnapshotRow row;

  @override
  State<_SnapshotRow> createState() => _SnapshotRowState();
}

class _SnapshotRowState extends State<_SnapshotRow> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    final text = AppTypography.textTheme;
    final row = widget.row;
    final accent = switch (row.tone) {
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
            Icon(row.icon, size: AppSpacing.iconInline, color: accent),
            const SizedBox(width: AppSpacing.md),
            SizedBox(
              width: 56,
              child: Text(
                row.title,
                style: text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.15,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                row.summary,
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
                row.explanation,
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

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({
    required this.title,
    required this.detail,
    required this.tone,
    required this.lastVerified,
    this.action,
    this.onTap,
  });

  final String title;
  final String detail;
  final StatusBadgeTone tone;
  final String lastVerified;
  final String? action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = AppTypography.textTheme;
    final badgeLabel = switch (tone) {
      StatusBadgeTone.success => 'Healthy',
      StatusBadgeTone.neutral => 'OK',
      StatusBadgeTone.info => 'OK',
      StatusBadgeTone.warning => 'Attention',
      StatusBadgeTone.error => 'Attention',
    };
    final tappable = onTap != null;

    final card = GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Recommendation',
                style: text.labelMedium?.copyWith(
                  color: AppColors.onSurfaceMuted,
                  letterSpacing: 0.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              StatusBadge(label: badgeLabel, tone: tone),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            detail,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: text.bodySmall?.copyWith(
              color: AppColors.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Last verified · $lastVerified',
            style: text.labelSmall?.copyWith(
              color: AppColors.onSurfaceMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(
                  Icons.auto_fix_high_outlined,
                  size: AppSpacing.iconInline,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.xxs),
                Expanded(
                  child: Text(
                    tappable ? 'Tap to review fix' : 'Next · $action',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.labelSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (tappable)
                  Icon(
                    Icons.chevron_right_rounded,
                    size: AppSpacing.iconInline,
                    color: AppColors.primary,
                  ),
              ],
            ),
          ],
        ],
      ),
    );

    if (!tappable) return card;

    return Semantics(
      button: true,
      label: 'Recommendation: $title. Tap to review fix.',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: card,
        ),
      ),
    );
  }
}

class _RecentScanCard extends StatelessWidget {
  const _RecentScanCard({required this.scan});

  final RecentScanView scan;

  @override
  Widget build(BuildContext context) {
    final text = AppTypography.textTheme;
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent scan',
            style: text.labelMedium?.copyWith(
              color: AppColors.onSurfaceMuted,
              letterSpacing: 0.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _CompactStat(label: 'Duration', value: scan.duration),
          const SizedBox(height: AppSpacing.xs),
          _CompactStat(label: 'Issues', value: '${scan.issuesFound}'),
          const SizedBox(height: AppSpacing.xs),
          _CompactStat(label: 'Confidence', value: scan.confidenceLabel),
          const SizedBox(height: AppSpacing.xs),
          _CompactStat(label: 'Last scanned', value: scan.scannedAt),
        ],
      ),
    );
  }
}

class _CompactStat extends StatelessWidget {
  const _CompactStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = AppTypography.textTheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: text.labelSmall?.copyWith(
              color: AppColors.onSurfaceMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
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

class _DeveloperServicesCard extends StatelessWidget {
  const _DeveloperServicesCard({required this.services});

  final List<DeveloperServiceRow> services;

  @override
  Widget build(BuildContext context) {
    final text = AppTypography.textTheme;
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Developer services',
            style: text.labelMedium?.copyWith(
              color: AppColors.onSurfaceMuted,
              letterSpacing: 0.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 900
                  ? 5
                  : constraints.maxWidth >= 560
                      ? 3
                      : 2;
              return Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final service in services)
                    SizedBox(
                      width: (constraints.maxWidth -
                              (AppSpacing.sm * (columns - 1))) /
                          columns,
                      child: _ServiceTile(service: service),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ServiceTile extends StatefulWidget {
  const _ServiceTile({required this.service});

  final DeveloperServiceRow service;

  @override
  State<_ServiceTile> createState() => _ServiceTileState();
}

class _ServiceTileState extends State<_ServiceTile> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    final text = AppTypography.textTheme;
    final service = widget.service;
    final subtitle = service.detail ??
        (service.lastChecked != null
            ? 'Checked · ${service.lastChecked}'
            : 'Not checked');

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: _hovered
              ? AppColors.surfaceHigh.withValues(alpha: 0.55)
              : AppColors.surfaceLow.withValues(alpha: 0.45),
          borderRadius: AppRadius.smAll,
          border: Border.all(
            color: _hovered ? AppColors.outline : AppColors.borderSoft,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  service.icon,
                  size: AppSpacing.iconInline,
                  color: AppColors.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    service.name,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                StatusBadge(
                  label: service.badgeLabel,
                  tone: service.tone,
                  showDot: false,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.labelSmall?.copyWith(
                color: AppColors.onSurfaceMuted,
                fontFamily: service.detail != null ? 'Menlo' : null,
                fontFamilyFallback: service.detail != null
                    ? const ['Consolas', 'monospace']
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TechnicalDetailsCard extends StatefulWidget {
  const _TechnicalDetailsCard({
    required this.groups,
    this.initiallyExpanded = false,
  });

  final List<TechnicalGroupView> groups;
  final bool initiallyExpanded;

  @override
  State<_TechnicalDetailsCard> createState() => _TechnicalDetailsCardState();
}

class _TechnicalDetailsCardState extends State<_TechnicalDetailsCard>
    with SingleTickerProviderStateMixin {
  late var _expanded = widget.initiallyExpanded;
  late final AnimationController _chevron;

  @override
  void initState() {
    super.initState();
    _chevron = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      value: _expanded ? 1 : 0,
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

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Technical details',
                          style: text.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'DNS · TCP · TLS · HTTP · Rules',
                          style: text.labelSmall?.copyWith(
                            color: AppColors.onSurfaceMuted,
                          ),
                        ),
                      ],
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
                  for (final group in widget.groups) ...[
                    Text(
                      group.title,
                      style: text.labelMedium?.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    for (final line in group.lines)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
                        child: SelectableText(
                          '${line.label}: ${line.value}',
                          style: mono,
                        ),
                      ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
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
      ),
    );
  }
}
