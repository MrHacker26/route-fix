import 'dart:convert';
import 'dart:io';

import '../../core/abstractions/result.dart';
import '../../core/errors/app_failure.dart';
import '../../domain/repositories/settings_repository.dart';

/// Persists [AppSettings] as JSON under the user config directory.
final class JsonFileSettingsRepository implements SettingsRepository {
  JsonFileSettingsRepository({Directory? directory}) : _directory = directory;

  final Directory? _directory;

  Future<File> _file() async {
    final dir = _directory ?? await _defaultDirectory();
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return File('${dir.path}${Platform.pathSeparator}settings.json');
  }

  static Future<Directory> _defaultDirectory() async {
    if (Platform.isMacOS) {
      final home = Platform.environment['HOME'];
      if (home != null && home.isNotEmpty) {
        return Directory('$home/Library/Application Support/RouteFix');
      }
    } else if (Platform.isWindows) {
      final appData = Platform.environment['APPDATA'];
      if (appData != null && appData.isNotEmpty) {
        return Directory('$appData${Platform.pathSeparator}RouteFix');
      }
    } else {
      final config = Platform.environment['XDG_CONFIG_HOME'];
      final home = Platform.environment['HOME'];
      if (config != null && config.isNotEmpty) {
        return Directory('$config/routefix');
      }
      if (home != null && home.isNotEmpty) {
        return Directory('$home/.config/routefix');
      }
    }
    return Directory('${Directory.systemTemp.path}/routefix');
  }

  @override
  Future<Result<AppSettings>> getSettings() async {
    try {
      final file = await _file();
      if (!await file.exists()) {
        return const Success(AppSettings());
      }
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) {
        return const Success(AppSettings());
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return const Success(AppSettings());
      }
      return Success(
        AppSettings.fromJson(Map<String, dynamic>.from(decoded)),
      );
    } on Object catch (error) {
      return Failure(UnknownFailure('Could not read settings: $error'));
    }
  }

  @override
  Future<Result<void>> saveSettings(AppSettings settings) async {
    try {
      final file = await _file();
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(settings.toJson()),
      );
      return const Success(null);
    } on Object catch (error) {
      return Failure(UnknownFailure('Could not save settings: $error'));
    }
  }
}
