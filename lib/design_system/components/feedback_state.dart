import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import 'glass_card.dart';
import 'secondary_button.dart';

/// Intentional loading / empty / error surface.
///
/// One composed state — not a skeleton pile.
enum FeedbackKind {
  loading,
  empty,
  error,
}

class FeedbackState extends StatefulWidget {
  const FeedbackState({
    super.key,
    required this.kind,
    required this.title,
    this.body,
    this.actionLabel,
    this.onAction,
    this.compact = false,
    this.framed = true,
    this.icon,
  });

  final FeedbackKind kind;
  final String title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  /// When false, renders content without a card chrome (for nested sections).
  final bool framed;
  final IconData? icon;

  /// Dashboard / results initial load.
  factory FeedbackState.loading({
    Key? key,
    required String title,
    String? body,
    bool compact = false,
    bool framed = true,
  }) {
    return FeedbackState(
      key: key,
      kind: FeedbackKind.loading,
      title: title,
      body: body,
      compact: compact,
      framed: framed,
    );
  }

  factory FeedbackState.empty({
    Key? key,
    required String title,
    String? body,
    IconData? icon,
    bool compact = false,
    bool framed = true,
  }) {
    return FeedbackState(
      key: key,
      kind: FeedbackKind.empty,
      title: title,
      body: body,
      icon: icon,
      compact: compact,
      framed: framed,
    );
  }

  factory FeedbackState.error({
    Key? key,
    required String title,
    String? body,
    String actionLabel = 'Try again',
    VoidCallback? onAction,
    bool compact = false,
    bool framed = true,
  }) {
    return FeedbackState(
      key: key,
      kind: FeedbackKind.error,
      title: title,
      body: body,
      actionLabel: actionLabel,
      onAction: onAction,
      compact: compact,
      framed: framed,
    );
  }

  @override
  State<FeedbackState> createState() => _FeedbackStateState();
}

class _FeedbackStateState extends State<FeedbackState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.kind == FeedbackKind.loading) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant FeedbackState oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.kind == FeedbackKind.loading &&
        oldWidget.kind != FeedbackKind.loading) {
      _pulse.repeat(reverse: true);
    } else if (widget.kind != FeedbackKind.loading &&
        oldWidget.kind == FeedbackKind.loading) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = AppTypography.textTheme;
    final pad = widget.compact
        ? const EdgeInsets.all(AppSpacing.md)
        : const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xl,
          );

    final content = TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      builder: (context, opacity, child) {
        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, (1 - opacity) * 6),
            child: child,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LeadingMark(
                kind: widget.kind,
                icon: widget.icon,
                pulse: _pulse,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: (widget.compact
                              ? text.titleSmall
                              : text.titleMedium)
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (widget.body != null && widget.body!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        widget.body!,
                        style: text.bodyMedium?.copyWith(
                          color: AppColors.onSurfaceVariant,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (widget.onAction != null &&
              widget.actionLabel != null &&
              widget.actionLabel!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            SecondaryButton(
              label: widget.actionLabel!,
              icon: Icons.refresh_rounded,
              onPressed: widget.onAction,
            ),
          ],
        ],
      ),
    );

    if (!widget.framed) return content;

    return GlassCard(
      padding: pad,
      child: content,
    );
  }
}

/// Compact inline progress row for in-card apply / restore.
class InlineProgress extends StatelessWidget {
  const InlineProgress({
    super.key,
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 1.6,
            color: AppColors.primary,
          ),
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
    );
  }
}

class _LeadingMark extends StatelessWidget {
  const _LeadingMark({
    required this.kind,
    required this.pulse,
    this.icon,
  });

  final FeedbackKind kind;
  final Animation<double> pulse;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final (IconData resolved, Color fg, Color bg) = switch (kind) {
      FeedbackKind.loading => (
          icon ?? Icons.radar_rounded,
          AppColors.primary,
          AppColors.primary.withValues(alpha: 0.12),
        ),
      FeedbackKind.empty => (
          icon ?? Icons.check_circle_outline_rounded,
          AppColors.success,
          AppColors.success.withValues(alpha: 0.12),
        ),
      FeedbackKind.error => (
          icon ?? Icons.error_outline_rounded,
          AppColors.error,
          AppColors.error.withValues(alpha: 0.12),
        ),
    };

    Widget mark = Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.smAll,
      ),
      alignment: Alignment.center,
      child: kind == FeedbackKind.loading
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 1.8,
                color: fg,
              ),
            )
          : Icon(resolved, size: 20, color: fg),
    );

    if (kind == FeedbackKind.loading) {
      mark = FadeTransition(
        opacity: Tween<double>(begin: 0.55, end: 1).animate(
          CurvedAnimation(parent: pulse, curve: Curves.easeInOut),
        ),
        child: mark,
      );
    }

    return mark;
  }
}
