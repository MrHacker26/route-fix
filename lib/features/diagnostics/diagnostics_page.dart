import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import 'diagnostics_catalog.dart';
import 'diagnostics_result_page.dart';

enum _ItemPhase { waiting, running, done }

/// Premium diagnostics UI with sequenced fake progress. No networking.
class DiagnosticsPage extends StatefulWidget {
  const DiagnosticsPage({
    super.key,
    this.onClose,
  });

  final VoidCallback? onClose;

  @override
  State<DiagnosticsPage> createState() => _DiagnosticsPageState();
}

class _DiagnosticsPageState extends State<DiagnosticsPage>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _entrance;

  final List<_ItemPhase> _phases = List.filled(
    DiagnosticsCatalog.items.length,
    _ItemPhase.waiting,
  );
  final List<Timer> _timers = [];

  int _activeIndex = -1;
  bool _finished = false;
  bool _running = false;
  int _runToken = 0;

  double get _progress {
    if (_phases.isEmpty) return 0;
    final done = _phases.where((p) => p == _ItemPhase.done).length;
    final running = _activeIndex >= 0 && !_finished ? 0.35 : 0.0;
    return ((done + running) / _phases.length).clamp(0.0, 1.0);
  }

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    unawaited(_startSequence());
  }

  @override
  void dispose() {
    _runToken++;
    _cancelTimers();
    _pulse.dispose();
    _entrance.dispose();
    super.dispose();
  }

  void _cancelTimers() {
    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();
  }

  Future<void> _wait(Duration duration, int token) {
    final completer = Completer<void>();
    late final Timer timer;
    timer = Timer(duration, () {
      _timers.remove(timer);
      if (!completer.isCompleted) completer.complete();
    });
    _timers.add(timer);
    return completer.future.then((_) {
      if (token != _runToken) return;
    });
  }

  Future<void> _startSequence() async {
    final token = ++_runToken;
    _cancelTimers();
    setState(() {
      _running = true;
      _finished = false;
      _activeIndex = -1;
      for (var i = 0; i < _phases.length; i++) {
        _phases[i] = _ItemPhase.waiting;
      }
    });

    for (var i = 0; i < DiagnosticsCatalog.items.length; i++) {
      if (!mounted || token != _runToken) return;
      setState(() {
        _activeIndex = i;
        _phases[i] = _ItemPhase.running;
      });
      await _wait(DiagnosticsCatalog.items[i].duration, token);
      if (!mounted || token != _runToken) return;
      setState(() {
        _phases[i] = _ItemPhase.done;
      });
      await _wait(const Duration(milliseconds: 140), token);
      if (!mounted || token != _runToken) return;
    }

    if (!mounted || token != _runToken) return;
    setState(() {
      _activeIndex = -1;
      _running = false;
      _finished = true;
    });
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
    final items = DiagnosticsCatalog.items;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) {
          final glow = 0.035 + (_pulse.value * 0.025);
          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.85),
                radius: 1.15,
                colors: [
                  AppColors.ambience.withValues(alpha: glow),
                  AppColors.background,
                  AppColors.background,
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.xl,
                  AppSpacing.xxl,
                ),
                child: Column(
                  children: [
                    _Header(
                      finished: _finished,
                      running: _running,
                      progress: _progress,
                      onClose: _handleClose,
                      onReplay: _finished ? () => unawaited(_startSequence()) : null,
                      entrance: _entrance,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Expanded(
                      child: ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        itemCount: items.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final stagger = Interval(
                            (index * 0.06).clamp(0.0, 0.5),
                            (0.45 + index * 0.08).clamp(0.45, 1.0),
                            curve: Curves.easeOutCubic,
                          );
                          return FadeTransition(
                            opacity: CurvedAnimation(
                              parent: _entrance,
                              curve: stagger,
                            ),
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.06),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: _entrance,
                                  curve: stagger,
                                ),
                              ),
                              child: _DiagnosticTile(
                                data: items[index],
                                phase: _phases[index],
                                pulse: _pulse,
                                isActive: _activeIndex == index,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 400),
                      opacity: _finished ? 1 : 0.45,
                      child: Column(
                        children: [
                          Text(
                            _finished
                                ? 'Scan complete'
                                : 'Checking each step…',
                            style: text.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                          if (_finished) ...[
                            const SizedBox(height: AppSpacing.md),
                            SizedBox(
                              width: double.infinity,
                              child: PrimaryButton(
                                label: 'View results',
                                icon: Icons.insights_rounded,
                                expanded: true,
                                onPressed: () {
                                  Navigator.of(context).push(
                                    PageRouteBuilder<void>(
                                      transitionDuration: const Duration(
                                        milliseconds: 420,
                                      ),
                                      pageBuilder: (context, animation, secondary) {
                                        return FadeTransition(
                                          opacity: CurvedAnimation(
                                            parent: animation,
                                            curve: Curves.easeOutCubic,
                                          ),
                                          child: const DiagnosticsResultPage(),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
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
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.finished,
    required this.running,
    required this.progress,
    required this.onClose,
    required this.entrance,
    this.onReplay,
  });

  final bool finished;
  final bool running;
  final double progress;
  final VoidCallback onClose;
  final VoidCallback? onReplay;
  final Animation<double> entrance;

  @override
  Widget build(BuildContext context) {
    final text = AppTypography.textTheme;

    return FadeTransition(
      opacity: entrance,
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: onClose,
                  tooltip: 'Close',
                  style: IconButton.styleFrom(
                    foregroundColor: AppColors.onSurfaceVariant,
                    backgroundColor: AppColors.surfaceHigh.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.smAll,
                    ),
                  ),
                  icon: const Icon(Icons.close_rounded, size: AppSpacing.iconRow),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Diagnostics', style: text.headlineSmall),
                      Text(
                        'Checking each path',
                        style: text.bodySmall,
                      ),
                    ],
                  ),
                ),
                StatusBadge(
                  label: finished
                      ? 'Complete'
                      : running
                          ? 'Scanning'
                          : 'Idle',
                  tone: finished
                      ? StatusBadgeTone.success
                      : StatusBadgeTone.info,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: progress),
                        duration: const Duration(milliseconds: 420),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) {
                          return Text(
                            '${(value * 100).round()}%',
                            style: text.displaySmall?.copyWith(
                              letterSpacing: -1.2,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          );
                        },
                      ),
                      Text(
                        finished ? 'All steps checked' : 'In progress',
                        style: text.labelSmall,
                      ),
                    ],
                  ),
                ),
                if (onReplay != null)
                  SecondaryButton(
                    label: 'Scan again',
                    icon: Icons.refresh_rounded,
                    onPressed: onReplay,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: AppRadius.pill,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) {
                  return LinearProgressIndicator(
                    value: value == 0 && running ? null : value,
                    minHeight: AppSpacing.healthBar,
                    backgroundColor: AppColors.surfaceHighest,
                    color: AppColors.primary,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiagnosticTile extends StatelessWidget {
  const _DiagnosticTile({
    required this.data,
    required this.phase,
    required this.pulse,
    required this.isActive,
  });

  final DiagnosticItemData data;
  final _ItemPhase phase;
  final Animation<double> pulse;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final text = AppTypography.textTheme;
    final borderColor = switch (phase) {
      _ItemPhase.waiting => AppColors.outlineSubtle,
      _ItemPhase.running => AppColors.primary.withValues(
          alpha: 0.35 + pulse.value * 0.45,
        ),
      _ItemPhase.done => switch (data.outcome) {
          DiagnosticOutcome.success =>
            AppColors.success.withValues(alpha: 0.35),
          DiagnosticOutcome.warning =>
            AppColors.warning.withValues(alpha: 0.35),
          DiagnosticOutcome.info => AppColors.primary.withValues(alpha: 0.35),
        },
    };

    final fill = switch (phase) {
      _ItemPhase.running => AppColors.primaryContainer.withValues(
          alpha: 0.25 + pulse.value * 0.2,
        ),
      _ItemPhase.done => AppColors.surfaceContainer.withValues(alpha: 0.9),
      _ItemPhase.waiting => AppColors.surfaceLow.withValues(alpha: 0.55),
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: borderColor, width: isActive ? 1.4 : 1),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.12 + pulse.value * 0.1),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ]
            : AppShadows.none,
      ),
      child: Row(
        children: [
          _LeadingGlyph(
            data: data,
            phase: phase,
            pulse: pulse,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(data.label, style: text.titleMedium),
                    const SizedBox(width: AppSpacing.xs),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: phase == _ItemPhase.done ? 1 : 0,
                      child: StatusBadge(
                        label: switch (data.outcome) {
                          DiagnosticOutcome.success => 'Healthy',
                          DiagnosticOutcome.warning => 'Attention',
                          DiagnosticOutcome.info => 'Checked',
                        },
                        tone: switch (data.outcome) {
                          DiagnosticOutcome.success => StatusBadgeTone.success,
                          DiagnosticOutcome.warning => StatusBadgeTone.warning,
                          DiagnosticOutcome.info => StatusBadgeTone.info,
                        },
                        showDot: false,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: Text(
                    phase == _ItemPhase.done
                        ? data.result
                        : phase == _ItemPhase.running
                            ? data.activeVerb
                            : data.subtitle,
                    key: ValueKey('${data.id}-$phase'),
                    style: text.bodySmall?.copyWith(
                      color: phase == _ItemPhase.waiting
                          ? AppColors.onSurfaceMuted
                          : AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
                if (phase == _ItemPhase.running) ...[
                  const SizedBox(height: AppSpacing.sm),
                  ClipRRect(
                    borderRadius: AppRadius.pill,
                    child: LinearProgressIndicator(
                      minHeight: 3,
                      backgroundColor: AppColors.surfaceHighest,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _TrailingStatus(phase: phase, outcome: data.outcome, pulse: pulse),
        ],
      ),
    );
  }
}

class _LeadingGlyph extends StatelessWidget {
  const _LeadingGlyph({
    required this.data,
    required this.phase,
    required this.pulse,
  });

  final DiagnosticItemData data;
  final _ItemPhase phase;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    final color = switch (phase) {
      _ItemPhase.waiting => AppColors.onSurfaceMuted,
      _ItemPhase.running => AppColors.primary,
      _ItemPhase.done => switch (data.outcome) {
          DiagnosticOutcome.success => AppColors.success,
          DiagnosticOutcome.warning => AppColors.warning,
          DiagnosticOutcome.info => AppColors.primary,
        },
    };

    final bg = switch (phase) {
      _ItemPhase.waiting => AppColors.surfaceHigh,
      _ItemPhase.running => AppColors.primaryContainer,
      _ItemPhase.done => switch (data.outcome) {
          DiagnosticOutcome.success => AppColors.successContainer,
          DiagnosticOutcome.warning => AppColors.warningContainer,
          DiagnosticOutcome.info => AppColors.primaryContainer,
        },
    };

    return AnimatedBuilder(
      animation: pulse,
      builder: (context, child) {
        final scale = phase == _ItemPhase.running
            ? 1.0 + (pulse.value * 0.06)
            : 1.0;
        return Transform.scale(scale: scale, child: child);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AppRadius.mdAll,
        ),
        child: Icon(data.icon, color: color, size: AppSpacing.iconLead),
      ),
    );
  }
}

class _TrailingStatus extends StatelessWidget {
  const _TrailingStatus({
    required this.phase,
    required this.outcome,
    required this.pulse,
  });

  final _ItemPhase phase;
  final DiagnosticOutcome outcome;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, animation) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: switch (phase) {
        _ItemPhase.waiting => Icon(
            Icons.circle_outlined,
            key: const ValueKey('wait'),
            size: AppSpacing.iconRow,
            color: AppColors.outline,
          ),
        _ItemPhase.running => SizedBox(
            key: const ValueKey('run'),
            width: AppSpacing.iconLead,
            height: AppSpacing.iconLead,
            child: AnimatedBuilder(
              animation: pulse,
              builder: (context, _) {
                return CustomPaint(
                  painter: _PulseRingPainter(t: pulse.value),
                );
              },
            ),
          ),
        _ItemPhase.done => Icon(
            outcome == DiagnosticOutcome.warning
                ? Icons.error_outline_rounded
                : Icons.check_circle_rounded,
            key: ValueKey('done-$outcome'),
            size: AppSpacing.iconLead,
            color: outcome == DiagnosticOutcome.warning
                ? AppColors.warning
                : AppColors.success,
          ),
      },
    );
  }
}

class _PulseRingPainter extends CustomPainter {
  _PulseRingPainter({required this.t});

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 2;

    final track = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final sweep = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2 + (t * math.pi * 2),
      math.pi * 1.15,
      false,
      sweep,
    );
  }

  @override
  bool shouldRepaint(covariant _PulseRingPainter oldDelegate) =>
      oldDelegate.t != t;
}
