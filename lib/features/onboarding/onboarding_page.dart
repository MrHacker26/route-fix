import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import 'onboarding_steps.dart';

/// First-run onboarding for RouteFix. Presentation only — no persistence.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({
    super.key,
    this.onFinished,
  });

  /// Called when the user completes or skips onboarding.
  final VoidCallback? onFinished;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  static const _stepCount = 3;

  final _controller = PageController();
  int _index = 0;

  bool get _isLast => _index >= _stepCount - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_isLast) {
      widget.onFinished?.call();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  void _goBack() {
    if (_index == 0) return;
    _controller.previousPage(
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final steps = OnboardingSteps.all;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.background,
              AppColors.atmosphere,
              AppColors.background,
            ],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.xxl,
                ),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: widget.onFinished,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.onSurfaceMuted,
                          textStyle: AppTypography.textTheme.labelLarge,
                        ),
                        child: const Text('Skip'),
                      ),
                    ),
                    Expanded(
                      child: PageView.builder(
                        controller: _controller,
                        itemCount: steps.length,
                        onPageChanged: (i) => setState(() => _index = i),
                        itemBuilder: (context, i) {
                          return _OnboardingStepView(step: steps[i]);
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _OnboardingDots(
                      count: steps.length,
                      index: _index,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      children: [
                        if (_index > 0)
                          SecondaryButton(
                            label: 'Back',
                            onPressed: _goBack,
                          )
                        else
                          const SizedBox(width: 96),
                        const Spacer(),
                        PrimaryButton(
                          label: _isLast ? 'Get started' : 'Continue',
                          onPressed: _goNext,
                          icon: _isLast
                              ? Icons.arrow_forward_rounded
                              : Icons.chevron_right_rounded,
                        ),
                      ],
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

class _OnboardingStepView extends StatelessWidget {
  const _OnboardingStepView({required this.step});

  final OnboardingStepData step;

  @override
  Widget build(BuildContext context) {
    final text = AppTypography.textTheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: AppRadius.mdAll,
                    child: step.title == 'RouteFix'
                        ? Image.asset(
                            AppAssets.appIcon,
                            width: 48,
                            height: 48,
                            filterQuality: FilterQuality.medium,
                          )
                        : Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: AppRadius.mdAll,
                            ),
                            child: Icon(
                              step.icon,
                              color: AppColors.primary,
                              size: AppSpacing.iconLead,
                            ),
                          ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  StatusBadge(
                    label: step.eyebrow,
                    tone: StatusBadgeTone.info,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                step.title,
                style: text.displaySmall?.copyWith(
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                step.body,
                style: text.bodyLarge?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  height: 1.55,
                ),
              ),
            ],
          ),
        ),
        if (step.title == 'RouteFix') ...[
          const SizedBox(height: AppSpacing.lg),
          const Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            alignment: WrapAlignment.center,
            children: [
              StatusBadge(label: 'DNS', tone: StatusBadgeTone.neutral),
              StatusBadge(label: 'Routes', tone: StatusBadgeTone.neutral),
              StatusBadge(label: 'Timing', tone: StatusBadgeTone.neutral),
              StatusBadge(label: 'APIs', tone: StatusBadgeTone.neutral),
            ],
          ),
        ],
      ],
    );
  }
}

class _OnboardingDots extends StatelessWidget {
  const _OnboardingDots({
    required this.count,
    required this.index,
  });

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
          width: active ? 20 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.outline,
            borderRadius: AppRadius.pill,
          ),
        );
      }),
    );
  }
}
