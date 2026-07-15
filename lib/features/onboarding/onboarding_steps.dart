import 'package:flutter/material.dart';

/// Onboarding step content — presentation only.
class OnboardingStepData {
  const OnboardingStepData({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.icon,
  });

  final String eyebrow;
  final String title;
  final String body;
  final IconData icon;
}

/// Ordered steps for the RouteFix first-run experience.
abstract final class OnboardingSteps {
  static const List<OnboardingStepData> all = [
    OnboardingStepData(
      eyebrow: 'Welcome',
      title: 'RouteFix',
      body:
          'See why GitHub, PyPI, Docker, and APIs feel slow — even when your bandwidth looks fine.',
      icon: Icons.hub_outlined,
    ),
    OnboardingStepData(
      eyebrow: 'Clarity',
      title: 'Not a speed test',
      body:
          'We measure how traffic reaches services, not how many megabits your ISP advertises.',
      icon: Icons.speed_outlined,
    ),
    OnboardingStepData(
      eyebrow: 'Diagnosis',
      title: 'Find the real bottleneck',
      body:
          'Trace DNS, routes, and connection timing to the hosts you care about — so fixes stay precise.',
      icon: Icons.timeline_outlined,
    ),
  ];
}
