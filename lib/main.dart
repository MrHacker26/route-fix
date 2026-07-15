import 'package:flutter/material.dart';

import 'design_system/design_system.dart';
import 'di/app_services.dart';
import 'features/dashboard/dashboard_page.dart';
import 'features/onboarding/onboarding_page.dart';

void main() {
  // Warm the composition root so first diagnostic run is ready.
  AppServices.diagnostics;

  runApp(const RouteFixApp());
}

class RouteFixApp extends StatefulWidget {
  const RouteFixApp({super.key});

  @override
  State<RouteFixApp> createState() => _RouteFixAppState();
}

class _RouteFixAppState extends State<RouteFixApp> {
  bool _showOnboarding = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RouteFix',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: _showOnboarding
          ? OnboardingPage(
              onFinished: () => setState(() => _showOnboarding = false),
            )
          : const DashboardPage(),
    );
  }
}
