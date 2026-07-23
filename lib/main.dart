import 'package:flutter/material.dart';

import 'design_system/design_system.dart';
import 'di/app_services.dart';
import 'features/dashboard/dashboard_page.dart';
import 'features/debug/networking_debug_page.dart';
import 'features/onboarding/onboarding_page.dart';
import 'features/settings/app_settings_controller.dart';

/// TEMPORARY: set to `false` (or omit `--dart-define=NETWORKING_DEBUG=true`)
/// to restore the normal product UI.
const bool kNetworkingLayerDebug = bool.fromEnvironment(
  'NETWORKING_DEBUG',
  defaultValue: false,
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppServices.settings.load();
  // Warm the composition root so first diagnostic run is ready.
  AppServices.diagnostics;
  runApp(RouteFixApp(settings: AppServices.settings));
}

class RouteFixApp extends StatelessWidget {
  const RouteFixApp({
    super.key,
    required this.settings,
  });

  final AppSettingsController settings;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        return _RouteFixRoot(settings: settings);
      },
    );
  }
}

class _RouteFixRoot extends StatefulWidget {
  const _RouteFixRoot({required this.settings});

  final AppSettingsController settings;

  @override
  State<_RouteFixRoot> createState() => _RouteFixRootState();
}

class _RouteFixRootState extends State<_RouteFixRoot> {
  bool _showOnboarding = true;
  int? _lastTimeoutSeconds;

  @override
  void initState() {
    super.initState();
    _lastTimeoutSeconds =
        widget.settings.settings.diagnosticsTimeoutSeconds;
    widget.settings.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    widget.settings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    final timeout = widget.settings.settings.diagnosticsTimeoutSeconds;
    if (_lastTimeoutSeconds != timeout) {
      _lastTimeoutSeconds = timeout;
      AppServices.invalidateDiagnostics();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RouteFix',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: kNetworkingLayerDebug
          ? const NetworkingDebugPage(host: 'github.com')
          : _showOnboarding
              ? OnboardingPage(
                  onFinished: () => setState(() => _showOnboarding = false),
                )
              : const DashboardPage(),
    );
  }
}
