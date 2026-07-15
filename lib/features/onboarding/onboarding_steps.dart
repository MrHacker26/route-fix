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
          'Find out why tools feel slow when your connection looks fine.',
      icon: Icons.hub_outlined,
    ),
    OnboardingStepData(
      eyebrow: 'Clarity',
      title: 'Not a speed test',
      body:
          'RouteFix checks how you reach services — not download speed.',
      icon: Icons.speed_outlined,
    ),
    OnboardingStepData(
      eyebrow: 'Precision',
      title: 'Measure what matters',
      body:
          'Name lookup, routes, and timing to the hosts you use every day.',
      icon: Icons.timeline_outlined,
    ),
  ];
}
