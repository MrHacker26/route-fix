import 'dart:io';

import 'package:flutter/foundation.dart';

/// Static product metadata for About / Settings.
///
/// Keep [version] / [build] aligned with `pubspec.yaml` (`version: x.y.z+build`).
abstract final class AppInfo {
  static const String name = 'RouteFix';
  static const String version = '1.0.0';
  static const String build = '1';
  static const String versionLabel = '$version ($build)';
  static const String tagline =
      'Diagnose why developer services feel slow — even when bandwidth is fine.';
  static const String githubUrl = 'https://github.com/MrHacker26/route-fix';
  static const String githubLabel = 'github.com/MrHacker26/route-fix';
  static const String license = 'MIT';
  static const String licenseCopyright = '© 2026 MrHacker26';

  /// Optional: `flutter run --dart-define=FLUTTER_VERSION=3.29.0`
  static const String flutterVersionDefine = String.fromEnvironment(
    'FLUTTER_VERSION',
  );

  static String get platformLabel {
    if (kIsWeb) return 'Web';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isLinux) return 'Linux';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isAndroid) return 'Android';
    return 'Unknown';
  }

  static String? _cachedFlutterVersion;

  /// Resolves Flutter SDK version (build define → CLI → unavailable).
  static Future<String> resolveFlutterVersion() async {
    if (_cachedFlutterVersion != null) return _cachedFlutterVersion!;
    if (flutterVersionDefine.isNotEmpty) {
      return _cachedFlutterVersion = flutterVersionDefine;
    }
    try {
      final result = await Process.run('flutter', ['--version']);
      if (result.exitCode == 0) {
        final stdout = result.stdout?.toString() ?? '';
        final match = RegExp(r'Flutter\s+(\S+)').firstMatch(stdout);
        if (match != null) {
          return _cachedFlutterVersion = match.group(1)!;
        }
      }
    } on Object {
      // Flutter CLI may be unavailable in packaged builds.
    }
    return _cachedFlutterVersion = 'Unavailable';
  }
}
