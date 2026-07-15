import 'package:flutter/material.dart';

import 'design_system/design_system.dart';

void main() {
  runApp(const RouteFixApp());
}

class RouteFixApp extends StatelessWidget {
  const RouteFixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RouteFix',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: const Scaffold(),
    );
  }
}
