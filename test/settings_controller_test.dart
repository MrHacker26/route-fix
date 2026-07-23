import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:route_fix/core/abstractions/result.dart';
import 'package:route_fix/data/settings/json_file_settings_repository.dart';
import 'package:route_fix/domain/repositories/settings_repository.dart';
import 'package:route_fix/features/settings/app_settings_controller.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('routefix_settings_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('AppSettingsController loads defaults and persists changes', () async {
    final controller = AppSettingsController(
      repository: JsonFileSettingsRepository(directory: tempDir),
    );

    await controller.load();
    expect(controller.settings.diagnosticsTimeoutSeconds, 8);
    expect(controller.settings.autoRerunAfterFixes, isTrue);
    expect(controller.settings.showTechnicalDetailsByDefault, isFalse);

    await controller.setDiagnosticsTimeoutSeconds(12);
    await controller.setAutoRerunAfterFixes(false);
    await controller.setShowTechnicalDetailsByDefault(true);

    final reloaded = AppSettingsController(
      repository: JsonFileSettingsRepository(directory: tempDir),
    );
    await reloaded.load();
    expect(reloaded.settings.diagnosticsTimeoutSeconds, 12);
    expect(reloaded.settings.autoRerunAfterFixes, isFalse);
    expect(reloaded.settings.showTechnicalDetailsByDefault, isTrue);
  });

  test('JsonFileSettingsRepository returns defaults when missing', () async {
    final repo = JsonFileSettingsRepository(directory: tempDir);
    final result = await repo.getSettings();
    expect(result, isA<Success<AppSettings>>());
    expect((result as Success<AppSettings>).value.diagnosticsTimeoutSeconds, 8);
  });
}
