import 'dart:async';

import '../../../domain/autofix/auto_fix_repository.dart';
import '../../../domain/autofix/auto_fix_service.dart';
import '../../../domain/autofix/exceptions/auto_fix_exception.dart';
import '../../../domain/autofix/models/applied_fix.dart';
import '../../../domain/autofix/models/fix_action.dart';
import '../../../domain/autofix/models/fix_result.dart';
import '../../../domain/autofix/models/fix_type.dart';
import '../../../domain/autofix/platform_fix_executor.dart';

/// Orchestrates Auto Fix apply / restore with progress and applied-fix tracking.
final class DefaultAutoFixService implements AutoFixService {
  DefaultAutoFixService({
    required PlatformFixExecutor executor,
    required AutoFixRepository repository,
  })  : _executor = executor,
        _repository = repository;

  final PlatformFixExecutor _executor;
  final AutoFixRepository _repository;

  final _progressController = StreamController<AutoFixPhase>.broadcast();
  var _busy = false;
  final List<AppliedFix> _cache = [];

  @override
  FixPlatform get platform => _executor.platform;

  @override
  bool get isBusy => _busy;

  @override
  Stream<AutoFixPhase> get progress => _progressController.stream;

  @override
  List<AppliedFix> get appliedFixes => List.unmodifiable(_cache);

  @override
  bool supports(FixType type) => _executor.supports(type);

  @override
  Future<FixResult> apply(
    FixType type, {
    void Function(AutoFixPhase phase)? onPhase,
  }) async {
    if (_busy) {
      final kind = type.toFixActionKind ?? FixActionKind.disableIpv6;
      return FixResult.failure(
        kind,
        message: 'Another fix is already being applied.',
        executed: false,
        platform: platform,
      );
    }

    if (!_executor.supports(type)) {
      final kind = type.toFixActionKind ?? FixActionKind.disableIpv6;
      if (platform == FixPlatform.unsupported) {
        return FixResult.failure(
          kind,
          message: 'Auto Fix is not available on this platform.',
          executed: false,
          platform: platform,
        );
      }
      return FixResult.notImplemented(kind);
    }

    _busy = true;
    try {
      await _emit(AutoFixPhase.applying, onPhase);
      await Future<void>.delayed(const Duration(milliseconds: 80));
      await _emit(AutoFixPhase.updatingNetwork, onPhase);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      await _emit(AutoFixPhase.restartingInterface, onPhase);

      final result = await _executor.apply(type);

      if (result.success && result.executed) {
        await _emit(AutoFixPhase.verifying, onPhase);
        final recorded = AppliedFix(
          id: '${type.name}-${DateTime.now().millisecondsSinceEpoch}',
          type: type,
          appliedAt: DateTime.now().toUtc(),
          platform: platform.name,
          target: result.metadata['applied'] ?? '',
          metadata: {
            ...result.metadata,
            if (result.message != null) 'message': result.message!,
          },
        );
        if (type == FixType.restoreDefault) {
          await _repository.clear();
          _cache.clear();
        } else {
          await _repository.record(recorded);
          _cache
            ..removeWhere((item) => item.type == type)
            ..add(recorded);
        }
      }
      return result;
    } on AutoFixBusyException catch (error) {
      final kind = type.toFixActionKind ?? FixActionKind.disableIpv6;
      return FixResult.failure(
        kind,
        message: error.message,
        error: error.details,
        executed: false,
        platform: platform,
      );
    } on AutoFixException catch (error) {
      final kind = type.toFixActionKind ?? FixActionKind.disableIpv6;
      return FixResult.failure(
        kind,
        message: error.message,
        error: error.details,
        executed: false,
        platform: platform,
      );
    } finally {
      _busy = false;
    }
  }

  @override
  Future<FixResult> restoreDefault({
    void Function(AutoFixPhase phase)? onPhase,
  }) async {
    if (_busy) {
      return FixResult.failure(
        FixActionKind.enableIpv6,
        message: 'Another fix is already being applied.',
        executed: false,
        platform: platform,
      );
    }

    _busy = true;
    try {
      await _emit(AutoFixPhase.restoring, onPhase);
      await _emit(AutoFixPhase.updatingNetwork, onPhase);

      if (!_executor.supports(FixType.restoreDefault)) {
        return FixResult.failure(
          FixActionKind.enableIpv6,
          message: 'Restore is not available on this platform.',
          executed: false,
          platform: platform,
        );
      }

      final result = await _executor.apply(FixType.restoreDefault);
      if (result.success) {
        await _repository.clear();
        _cache.clear();
        await _emit(AutoFixPhase.verifying, onPhase);
      }
      return result;
    } on AutoFixException catch (error) {
      return FixResult.failure(
        FixActionKind.enableIpv6,
        message: error.message,
        error: error.details,
        executed: false,
        platform: platform,
      );
    } finally {
      _busy = false;
    }
  }

  Future<void> hydrate() async {
    final items = await _repository.listApplied();
    _cache
      ..clear()
      ..addAll(items);
  }

  Future<void> _emit(
    AutoFixPhase phase,
    void Function(AutoFixPhase phase)? onPhase,
  ) async {
    onPhase?.call(phase);
    if (!_progressController.isClosed) {
      _progressController.add(phase);
    }
  }

  Future<void> dispose() async {
    await _progressController.close();
  }
}
